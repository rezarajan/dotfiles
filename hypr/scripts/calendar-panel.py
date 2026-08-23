#!/usr/bin/env python3
"""Calendar popup — a real month view, not a tooltip.

Opened by the bar clock (scripts/panel.sh calendar). Runs with app-id
"gruvbox-calendar" so the applet window rules float it under the clock
with the acrylic treatment and lua/applets.lua dismisses it on focus
loss / click-outside. Header shows today in Gregorian and Hijri;
selecting any day shows its Hijri equivalent underneath.
"""
import datetime

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import GLib  # noqa: E402

GLib.set_prgname("gruvbox-calendar")

from gi.repository import Gdk, Gtk  # noqa: E402

HIJRI_MONTHS = ["Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
                "Jumada al-Ula", "Jumada al-Akhirah", "Rajab", "Sha'ban",
                "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"]
HIJRI_LEAP = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29}


def hijri(date):
    """Tabular (arithmetic) Islamic date — ±1 day vs Umm al-Qura."""
    days = date.toordinal() + 1721425 - 1948440
    cyc, d = divmod(days, 10631)
    y = 0
    while True:
        ylen = 355 if (y % 30) + 1 in HIJRI_LEAP else 354
        if d < ylen:
            break
        d -= ylen
        y += 1
    year = cyc * 30 + y + 1
    m = 0
    while True:
        mlen = 30 if m % 2 == 0 else 29
        if m == 11 and (year - 1) % 30 + 1 in HIJRI_LEAP:
            mlen = 30
        if d < mlen:
            break
        d -= mlen
        m += 1
    return f"{d + 1} {HIJRI_MONTHS[m]} {year} AH"


class CalendarPanel(Gtk.Window):
    def __init__(self):
        super().__init__(title="Calendar")
        self.connect("destroy", Gtk.main_quit)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8,
                        margin=16)
        self.add(outer)

        today = datetime.date.today()
        head = Gtk.Label(label=today.strftime("%A, %B %-d %Y"))
        head.get_style_context().add_class("cal-today")
        outer.pack_start(head, False, False, 0)

        head_h = Gtk.Label(label=hijri(today))
        head_h.get_style_context().add_class("cal-hijri")
        outer.pack_start(head_h, False, False, 0)

        self.cal = Gtk.Calendar()
        self.cal.get_style_context().add_class("cal-grid")
        self.cal.connect("day-selected", self._on_day)
        outer.pack_start(self.cal, True, True, 4)

        self.selected = Gtk.Label(label="")
        self.selected.get_style_context().add_class("cal-selected")
        outer.pack_start(self.selected, False, False, 0)

        css = Gtk.CssProvider()
        css.load_from_data(b"""
            .cal-today { font-size: 15px; font-weight: 600; }
            .cal-hijri { font-size: 12px;
                         color: @theme_unfocused_fg_color_breeze; }
            .cal-selected { font-size: 12px;
                            color: @theme_unfocused_fg_color_breeze; }
            .cal-grid { font-size: 13px; padding: 6px;
                        border-radius: 12px; border: none; }
            calendar:selected {
                background: alpha(@theme_selected_bg_color, 0.9);
                color: @theme_selected_fg_color;
                border-radius: 7px;
            }
            calendar header { border: none; font-weight: 600; }
            calendar button {
                background: transparent; border: none;
                border-radius: 999px; min-width: 30px; min-height: 30px;
            }
            calendar button:hover {
                background: alpha(@theme_fg_color, 0.1);
            }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER + 100)

    def _on_day(self, cal):
        y, m, d = cal.get_date()
        try:
            date = datetime.date(y, m + 1, d)   # Gtk months are 0-based
        except ValueError:
            return
        if date == datetime.date.today():
            self.selected.set_label("")
        else:
            self.selected.set_label(
                f"{date.strftime('%b %-d')} · {hijri(date)}")


if __name__ == "__main__":
    panel = CalendarPanel()
    panel.show_all()
    Gtk.main()
