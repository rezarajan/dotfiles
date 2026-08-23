#!/usr/bin/env python3
"""Regenerate every palette-derived artifact from palette.py:

  1. KDE color schemes   -> ../../color-schemes/
  2. Kvantum widget art  -> ../Gruvbox, ../GruvboxDark (SVGs)
  3. Kvantum kvconfigs   -> geometry + Qt palette keys
  4. Plasma desktop theme -> ../../plasma-theme/gruvbox-acrylic/
  5. GTK theme pair      -> ../../gtk/themes/Gruvbox-Dragon{,-Light}/
  6. Cursor theme pair   -> ../../cursors/Gruvbox-Dragon-Cursors{,-Light}/
  7. Hyprland stack      -> <repo>/hypr, waybar, rofi, swaync, wlogout tokens

Run after editing palette.py, then `home-manager switch` to deploy.
"""
import os
import runpy
import shutil
import sys
from pathlib import Path

# UTF-8 everywhere: without this, Windows runs write cp1252 and corrupt
# any non-ASCII byte (em-dashes) in the generated artifacts
if os.environ.get("PYTHONUTF8") != "1":
    os.environ["PYTHONUTF8"] = "1"
    os.execv(sys.executable, [sys.executable] + sys.argv)

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

for script in ("colorscheme_gen.py", "acrylic_gen.py",
               "patch_kvconfig.py", "plasma_theme_gen.py",
               "gtk_theme_gen.py", "cursor_gen.py",
               "hyprland_gen.py"):
    if script == "cursor_gen.py" and not shutil.which("xcursorgen"):
        print("==> cursor_gen.py SKIPPED (xcursorgen not on PATH; "
              "committed artifacts remain current)")
        continue
    print(f"==> {script}")
    runpy.run_path(str(HERE / script), run_name="__main__")
