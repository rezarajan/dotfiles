#!/usr/bin/env python3
"""Dedicated media popup — album art, track info, transport controls.

Opened by the bar's media chip (scripts/panel.sh media). Runs as a normal
window with app-id "gruvbox-media": the Hyprland applet rules float it
under the bar centre with the acrylic treatment, and lua/applets.lua
dismisses it on focus loss or click-outside, like every other applet.
Styling comes from the session GTK theme; only geometry lives here.
"""
import hashlib
import os
import subprocess
import tempfile
import urllib.request

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
# prgname becomes the Wayland app_id, and PyGObject initialises GTK (and
# connects the display) the moment Gtk is imported — so set it FIRST
from gi.repository import GLib  # noqa: E402

GLib.set_prgname("gruvbox-media")

from gi.repository import Gdk, GdkPixbuf, Gtk  # noqa: E402

ART_SIZE = 190


def pctl(*args, player=None):
    cmd = ["playerctl"]
    if player:
        cmd += ["-p", player]
    cmd += list(args)
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=2)
        return out.stdout.strip() if out.returncode == 0 else ""
    except Exception:
        return ""


def list_players():
    return [p for p in pctl("-l").splitlines() if p]


def art_path(url):
    if not url:
        return None
    if url.startswith("file://"):
        path = urllib.request.url2pathname(url[7:])
        return path if os.path.exists(path) else None
    if url.startswith(("http://", "https://")):
        cache = os.path.join(tempfile.gettempdir(),
                             "gruvbox-art-" + hashlib.sha1(url.encode()).hexdigest())
        if not os.path.exists(cache):
            try:
                urllib.request.urlretrieve(url, cache)
            except Exception:
                return None
        return cache
    return None


class MediaPanel(Gtk.Window):
    def __init__(self):
        super().__init__(title="Media")
        self.set_default_size(380, -1)
        self.connect("destroy", Gtk.main_quit)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10,
                        margin=18)
        self.add(outer)

        # player switcher: ‹ chromium · 2 of 3 › — shown when several
        # apps (or several tabs of one app) expose players
        self.players = []
        self.idx = 0
        switcher = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6,
                           halign=Gtk.Align.CENTER)
        self.prev_player = Gtk.Button(label="‹")
        self.prev_player.get_style_context().add_class("player-nav")
        self.prev_player.connect("clicked", self._switch_player, -1)
        self.player_label = Gtk.Label(label="")
        self.player_label.get_style_context().add_class("media-player-name")
        self.next_player = Gtk.Button(label="›")
        self.next_player.get_style_context().add_class("player-nav")
        self.next_player.connect("clicked", self._switch_player, 1)
        switcher.pack_start(self.prev_player, False, False, 0)
        switcher.pack_start(self.player_label, False, False, 8)
        switcher.pack_start(self.next_player, False, False, 0)
        outer.pack_start(switcher, False, False, 0)
        self.switcher = switcher

        self.art = Gtk.Image()
        self.art.set_size_request(ART_SIZE, ART_SIZE)
        art_frame = Gtk.Box(halign=Gtk.Align.CENTER)
        art_frame.add(self.art)
        outer.pack_start(art_frame, False, False, 0)

        self.title = Gtk.Label(label="Nothing playing", justify=Gtk.Justification.CENTER)
        self.title.set_line_wrap(True)
        self.title.get_style_context().add_class("media-title")
        outer.pack_start(self.title, False, False, 0)

        self.artist = Gtk.Label(label="", justify=Gtk.Justification.CENTER)
        self.artist.get_style_context().add_class("media-artist")
        outer.pack_start(self.artist, False, False, 0)

        controls = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14,
                           halign=Gtk.Align.CENTER)
        self.buttons = {}
        for key, glyph, action in (("prev", "\U000f04ae", "previous"),
                                   ("play", "\U000f040a", "play-pause"),
                                   ("next", "\U000f04ad", "next")):
            b = Gtk.Button(label=glyph)
            b.get_style_context().add_class("media-button")
            if key == "play":
                b.get_style_context().add_class("media-play")
                b.set_size_request(56, 56)   # true circles, never pills
            else:
                b.set_size_request(46, 46)
            b.connect("clicked", self._on_control, action)
            b.set_valign(Gtk.Align.CENTER)
            controls.pack_start(b, False, False, 0)
            self.buttons[key] = b
        outer.pack_start(controls, False, False, 6)

        css = Gtk.CssProvider()
        css.load_from_data(b"""
            .media-title { font-size: 16px; font-weight: 600; }
            .media-artist { font-size: 13px; color: @theme_unfocused_fg_color_breeze; }
            .media-player-name { font-size: 11px; color: @theme_unfocused_fg_color_breeze; }
            .media-button {
                border-radius: 999px; min-width: 44px; min-height: 44px;
                font-size: 20px; padding: 0;
            }
            .media-play {
                background: alpha(@theme_selected_bg_color, 0.9);
                color: @theme_selected_fg_color;
                font-size: 24px;
            }
            .player-nav {
                border-radius: 999px; min-width: 30px; min-height: 30px;
                padding: 0; font-size: 15px;
                background: transparent; border: none;
                color: @theme_unfocused_fg_color_breeze;
            }
            .player-nav:hover { color: @theme_fg_color; }
        """)
        # above USER priority (800): the session gtk.css must not square
        # these circles back off
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER + 100)

        self._last_art = None
        self.refresh()
        GLib.timeout_add(1000, self.refresh)

    def _current(self):
        if not self.players:
            return None
        self.idx %= len(self.players)
        return self.players[self.idx]

    def _switch_player(self, _button, step):
        if self.players:
            self.idx = (self.idx + step) % len(self.players)
            self.refresh()

    def _on_control(self, _button, action):
        pctl(action, player=self._current())
        GLib.timeout_add(200, self.refresh)

    def refresh(self):
        old = self._current()
        self.players = list_players()
        if old in self.players:
            self.idx = self.players.index(old)
        player = self._current()

        many = len(self.players) > 1
        self.prev_player.set_visible(many)
        self.next_player.set_visible(many)
        if player:
            name = player.split(".")[0]
            label = (f"{name} · {self.idx + 1} of {len(self.players)}"
                     if many else name)
            self.player_label.set_label(label)
        else:
            self.player_label.set_label("no players")

        status = pctl("status", player=player) if player else ""
        if not status:
            self.title.set_label("Nothing playing")
            self.artist.set_label("")
            self.art.clear()
            return True

        self.title.set_label(pctl("metadata", "title", player=player)
                             or "Unknown title")
        self.artist.set_label(pctl("metadata", "artist", player=player))
        self.buttons["play"].set_label(
            "\U000f03e4" if status == "Playing" else "\U000f040a")

        art = art_path(pctl("metadata", "mpris:artUrl", player=player))
        if art != self._last_art:
            self._last_art = art
            done = False
            if art:
                try:
                    pix = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                        art, ART_SIZE, ART_SIZE, True)
                    self.art.set_from_pixbuf(pix)
                    done = True
                except Exception:
                    pass
            if not done:
                # players without artwork get a quiet glyph, not a hole
                self.art.set_from_icon_name("folder-music-symbolic",
                                            Gtk.IconSize.DIALOG)
                self.art.set_pixel_size(96)
        return True


if __name__ == "__main__":
    panel = MediaPanel()
    panel.show_all()
    panel.refresh()   # after show_all, so switcher visibility sticks
    Gtk.main()
