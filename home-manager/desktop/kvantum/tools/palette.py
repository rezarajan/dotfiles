"""Palette loader — the single source of truth, made swappable.

Every generator imports its color tables from here; nothing downstream
hard-codes a hex value. To re-skin the ENTIRE desktop (KDE, GTK, Kvantum,
cursors, and the Hyprland stack — waybar, rofi, swaync, hyprlock, ...):

  1. copy palettes/gruvbox_dragon.py to palettes/<name>.py and change the
     base hex table + variant tokens
  2. point ACTIVE_PALETTE below at "<name>"
  3. run generate_all.py, then `home-manager switch` (KDE machines) or
     hypr/scripts/theme-mode.sh apply (Hyprland machines)

A palette module must export: G, ON_ACCENT, rgb, DARK, LIGHT, METRICS,
PLASMA — see palettes/gruvbox_dragon.py for the documented reference.
"""
import importlib

ACTIVE_PALETTE = "gruvbox_dragon"

_p = importlib.import_module(f"palettes.{ACTIVE_PALETTE}")

G = _p.G
ON_ACCENT = _p.ON_ACCENT
rgb = _p.rgb
DARK = _p.DARK
LIGHT = _p.LIGHT
METRICS = _p.METRICS
PLASMA = _p.PLASMA
