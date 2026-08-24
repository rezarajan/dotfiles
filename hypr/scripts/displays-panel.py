#!/usr/bin/env python3
"""Displays popup — layout presets and per-output controls.

Opened by the bar's displays chip (scripts/panel.sh displays) or Super+D.
Runs as a normal window with app-id "gruvbox-displays": the Hyprland
applet rules float it under the bar with the acrylic treatment, and
lua/applets.lua dismisses it on focus loss or click-outside, like every
other applet. All state changes go through scripts/monitors.sh, which is
also what the bar chip and the keybinds use.

Deliberately popup-free: a GtkComboBox would spawn a second surface, and
lua/applets.lua reads that as focus leaving the panel and closes it out
from under the user. So the mode control is a button that cycles the
refresh rates offered at the current resolution — the common quick fix,
notably for panels that came up at the EDID's 60 Hz. Resolution and
arrangement changes are what the full GUI is for.
"""
import json
import os
import subprocess

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
# prgname becomes the Wayland app_id, and PyGObject initialises GTK the
# moment Gtk is imported — so set it FIRST
from gi.repository import GLib  # noqa: E402

GLib.set_prgname("gruvbox-displays")

from gi.repository import Gdk, Gtk  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
MONITORS = os.path.join(HERE, "monitors.sh")

GLYPH_MONITOR = "\U000f0379"
GLYPH_SAVE = "\U000f0193"
GLYPH_COG = "\U000f0493"


def monitors_sh(*args, capture=True):
    """Run scripts/monitors.sh; return stdout, or "" on any failure."""
    try:
        out = subprocess.run(["bash", MONITORS, *args],
                             capture_output=capture, text=True, timeout=10)
        return out.stdout.strip() if capture else ""
    except Exception:
        return ""


def outputs():
    raw = monitors_sh("list")
    if not raw:
        return []
    try:
        return json.loads(raw)
    except ValueError:
        return []


def parse_mode(mode):
    """"3440x1440@174.96Hz" -> (3440, 1440, 174.96); None if unparseable."""
    try:
        res, _, rate = mode.partition("@")
        w, _, h = res.partition("x")
        return int(w), int(h), float(rate.rstrip("Hz"))
    except (ValueError, AttributeError):
        return None


class DisplaysPanel(Gtk.Window):
    def __init__(self):
        super().__init__(title="Displays")
        self.set_default_size(400, -1)
        self.connect("destroy", Gtk.main_quit)
        self._syncing = False
        self._rows = {}

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12,
                        margin=16)
        self.add(outer)

        # ---------------------------------------------------- preset pills
        presets = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8,
                          halign=Gtk.Align.CENTER)
        for label, preset, tip in (
                ("Extend", "extend-right", "Side by side, focused display leftmost"),
                ("Mirror", "mirror", "Every display shows the focused one"),
                ("Solo", "solo", "Only the focused display stays on")):
            b = Gtk.Button(label=label)
            b.get_style_context().add_class("preset-pill")
            b.set_can_focus(False)   # a focus ring reads as "selected"
            b.set_tooltip_text(tip)
            b.connect("clicked", self._on_preset, preset)
            presets.pack_start(b, False, False, 0)
        outer.pack_start(presets, False, False, 0)

        # -------------------------------------------------- per-output list
        self.list_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_min_content_height(70)
        # hug the output list rather than reserving a fixed slab: the
        # window rule leaves this panel unsized so it grows with however
        # many outputs are attached, up to a cap where it starts scrolling
        scroll.set_propagate_natural_height(True)
        scroll.set_max_content_height(340)
        scroll.add(self.list_box)
        outer.pack_start(scroll, False, False, 0)

        # ---------------------------------------------------------- footer
        footer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        save = Gtk.Button(label=f"{GLYPH_SAVE}  Save layout")
        save.get_style_context().add_class("footer-button")
        save.set_can_focus(False)
        save.set_tooltip_text("Keep this arrangement across restarts")
        save.connect("clicked", self._on_save)
        footer.pack_start(save, True, True, 0)

        settings = Gtk.Button(label=f"{GLYPH_COG}  Arrange…")
        settings.get_style_context().add_class("footer-button")
        settings.set_can_focus(False)
        settings.set_tooltip_text("Full drag-and-drop arrangement (wdisplays)")
        settings.connect("clicked", self._on_settings)
        footer.pack_start(settings, True, True, 0)
        outer.pack_start(footer, False, False, 0)

        css = Gtk.CssProvider()
        css.load_from_data(b"""
            .preset-pill {
                border-radius: 999px;
                padding: 4px 16px;
                font-size: 13px;
                font-weight: 500;
            }
            .output-row {
                border-radius: 12px;
                padding: 8px 10px;
                background: alpha(@theme_fg_color, 0.05);
            }
            .output-row.off { opacity: 0.55; }
            .output-name { font-size: 14px; font-weight: 600; }
            .output-icon { font-size: 15px; color: @theme_unfocused_fg_color_breeze; }
            .output-mode {
                font-size: 11px;
                padding: 1px 8px;
                border-radius: 999px;
                background: transparent;
                border: none;
                color: @theme_unfocused_fg_color_breeze;
            }
            .output-mode:hover {
                color: @theme_fg_color;
                background: alpha(@theme_fg_color, 0.12);
            }
            .output-mirror { font-size: 11px; color: @theme_unfocused_fg_color_breeze; }
            .footer-button {
                border-radius: 999px;
                padding: 5px 10px;
                font-size: 12px;
            }
            .empty-note {
                font-size: 12px;
                color: @theme_unfocused_fg_color_breeze;
            }
        """)
        # above USER priority (800): the session gtk.css must not square
        # these pills back off
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER + 100)

        self.refresh()
        GLib.timeout_add(2000, self.refresh)

    # ------------------------------------------------------------- actions
    def _reload_soon(self):
        # the compositor needs a beat to settle before it reports the
        # layout it just applied
        GLib.timeout_add(400, self.refresh)

    def _on_preset(self, _button, preset):
        if preset == "solo":
            focused = next((m["name"] for m in outputs() if m.get("focused")), None)
            if not focused:
                return
            preset = f"solo:{focused}"
        monitors_sh("apply", preset)
        self._reload_soon()

    def _on_toggle(self, switch, state, name):
        if self._syncing:
            return False
        monitors_sh("apply", f"{'on' if state else 'off'}:{name}")
        # monitors.sh refuses to switch off the last display, so re-read
        # rather than trusting the switch we just moved
        self._reload_soon()
        return False

    def _on_cycle_mode(self, _button, name):
        mons = {m["name"]: m for m in outputs()}
        mon = mons.get(name)
        if not mon:
            return
        cur_w, cur_h = mon["width"], mon["height"]
        rates = []
        for mode in mon.get("modes", []):
            parsed = parse_mode(mode)
            if parsed and parsed[0] == cur_w and parsed[1] == cur_h:
                rates.append(parsed[2])
        rates = sorted(set(rates))
        if len(rates) < 2:
            return
        # step to the next rate up, wrapping at the top
        nxt = next((r for r in rates if r > mon["refresh"] + 0.5), rates[0])
        monitors_sh("set", name, "mode", f"{cur_w}x{cur_h}@{nxt:g}")
        self._reload_soon()

    def _on_save(self, _button):
        monitors_sh("save")

    def _on_settings(self, _button):
        # detached: the GUI outlives this panel, which lua/applets.lua
        # closes the moment focus lands on the new window
        subprocess.Popen(["bash", MONITORS, "gui"], start_new_session=True)
        self.destroy()

    # ------------------------------------------------------------- display
    def refresh(self):
        mons = outputs()
        for child in self.list_box.get_children():
            self.list_box.remove(child)

        if not mons:
            note = Gtk.Label(label="No outputs reported")
            note.get_style_context().add_class("empty-note")
            self.list_box.pack_start(note, False, False, 8)
            self.list_box.show_all()
            return True

        self._syncing = True
        for mon in mons:
            self.list_box.pack_start(self._build_row(mon), False, False, 0)
        self._syncing = False
        self.list_box.show_all()
        return True

    def _build_row(self, mon):
        name = mon["name"]
        off = mon["disabled"]

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.get_style_context().add_class("output-row")
        if off:
            row.get_style_context().add_class("off")

        text = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=1)
        # the glyph gets its own label: a nerd-font icon carries no side
        # bearing, so spacing it inside the string leaves it welded to the
        # first letter
        head = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        icon = Gtk.Label(label=GLYPH_MONITOR)
        icon.get_style_context().add_class("output-icon")
        # the glyph's ink sits flush right inside its advance box, so box
        # spacing alone leaves it touching the name
        icon.set_margin_end(6)
        head.pack_start(icon, False, False, 0)
        title = Gtk.Label(label=name, xalign=0)
        title.get_style_context().add_class("output-name")
        # the EDID model is the only way to tell two identical port names
        # apart; keep it to the tooltip rather than crowding the row
        if mon.get("description"):
            title.set_tooltip_text(mon["description"])
        head.pack_start(title, False, False, 0)
        text.pack_start(head, False, False, 0)

        if off:
            sub = Gtk.Label(label="Off", xalign=0)
            sub.get_style_context().add_class("output-mirror")
            text.pack_start(sub, False, False, 0)
        elif mon.get("mirrorOf", "none") != "none":
            sub = Gtk.Label(label=f"Mirrors {mon['mirrorOf']}", xalign=0)
            sub.get_style_context().add_class("output-mirror")
            text.pack_start(sub, False, False, 0)
        else:
            mode = Gtk.Button(
                label=f"{mon['width']}×{mon['height']}  ·  "
                      f"{mon['refresh']:.0f} Hz")
            mode.get_style_context().add_class("output-mode")
            mode.set_halign(Gtk.Align.START)
            mode.set_tooltip_text("Click to cycle refresh rate")
            mode.connect("clicked", self._on_cycle_mode, name)
            text.pack_start(mode, False, False, 0)

        row.pack_start(text, True, True, 0)

        switch = Gtk.Switch()
        switch.set_valign(Gtk.Align.CENTER)
        switch.set_active(not off)
        switch.connect("state-set", self._on_toggle, name)
        row.pack_start(switch, False, False, 0)
        return row


if __name__ == "__main__":
    panel = DisplaysPanel()
    panel.show_all()
    Gtk.main()
