"""Palette loader — the single source of truth, made swappable.

Every generator imports its color tables from here; nothing downstream
hard-codes a hex value. Each palette under palettes/ is a complete theme
with its own artifact names (THEME), so several can be installed side by
side; generate_all.py builds the KDE/GTK/Kvantum/cursor artifacts for every
entry in PALETTES, and kde-gruvbox.nix's `dotfiles.kde.theme` picks which
pair the light/dark toggle uses.

The Hyprland stack (waybar, rofi, swaync, hyprlock, ...) has one set of
token files, so it follows ACTIVE_PALETTE only.

To add a theme:
  1. copy palettes/gruvbox_dragon.py to palettes/<name>.py; change the
     base hex table, variant tokens and THEME names (all disjoint)
  2. add "<name>" to PALETTES below
  3. run generate_all.py, wire the name into kde-gruvbox.nix's `themes`,
     then `home-manager switch`

A palette module must export: THEME, G, ON_ACCENT, rgb, DARK, LIGHT,
METRICS, PLASMA — see palettes/gruvbox_dragon.py for the documented
reference. A generator runs against one palette per process: the
PALETTE environment variable overrides ACTIVE_PALETTE.
"""
import importlib
import os

ACTIVE_PALETTE = "gruvbox_dragon"
PALETTES = ("gruvbox_dragon", "rose_pine")

NAME = os.environ.get("PALETTE") or ACTIVE_PALETTE
if NAME not in PALETTES:
    raise SystemExit(f"palette.py: unknown palette {NAME!r} (have {PALETTES})")

_p = importlib.import_module(f"palettes.{NAME}")

THEME = _p.THEME
G = _p.G
ON_ACCENT = _p.ON_ACCENT
rgb = _p.rgb
DARK = _p.DARK
LIGHT = _p.LIGHT
METRICS = _p.METRICS
PLASMA = _p.PLASMA
