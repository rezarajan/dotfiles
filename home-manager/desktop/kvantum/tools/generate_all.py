#!/usr/bin/env python3
"""Regenerate every palette-derived artifact, for every palette in
palette.PALETTES (each into its own THEME names, side by side):

  1. KDE color schemes    -> ../../color-schemes/
  2. Kvantum seed + art   -> ../<Kvantum pair>/ (SVGs; non-reference
                             palettes are re-seeded from Gruvbox first)
  3. Kvantum kvconfigs    -> geometry + Qt palette keys
  4. Plasma desktop theme -> ../../plasma-theme/<id>/
  5. GTK theme pair       -> ../../gtk/themes/<name>{,-Light}/
  6. Cursor theme pair    -> ../../cursors/<name>/
  7. Look-and-feel pair   -> ../../look-and-feel/<id>/
plus ../../themes.json, every palette's THEME names keyed by option value
(module name, "_" -> "-"): kde-gruvbox.nix reads it to deploy them all and
to resolve `dotfiles.kde.theme`, so the names live in exactly one place;
and, for palette.ACTIVE_PALETTE only (it has a single set of token files):
  8. Hyprland stack       -> <repo>/hypr, waybar, rofi, swaync, wlogout tokens

Each generator runs in its own process with PALETTE=<name>, since they
read the palette at import time. Run after editing a palette, then
`home-manager switch` to deploy.
"""
import importlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# UTF-8 everywhere: without this, Windows runs write cp1252 and corrupt
# any non-ASCII byte (em-dashes) in the generated artifacts
if os.environ.get("PYTHONUTF8") != "1":
    os.environ["PYTHONUTF8"] = "1"
    os.execv(sys.executable, [sys.executable] + sys.argv)

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import palette  # noqa: E402

KDE = ("colorscheme_gen.py", "kvantum_seed.py", "acrylic_gen.py",
       "patch_kvconfig.py", "plasma_theme_gen.py", "gtk_theme_gen.py",
       "cursor_gen.py", "lookandfeel_gen.py")


def run(script, name):
    if script == "cursor_gen.py" and not shutil.which("xcursorgen"):
        print(f"==> [{name}] cursor_gen.py SKIPPED (xcursorgen not on PATH; "
              "committed artifacts remain current)")
        return
    print(f"==> [{name}] {script}", flush=True)
    subprocess.run([sys.executable, str(HERE / script)], cwd=HERE, check=True,
                   env={**os.environ, "PALETTE": name})


for name in palette.PALETTES:
    for script in KDE:
        run(script, name)
run("hyprland_gen.py", palette.ACTIVE_PALETTE)


themes = {name.replace("_", "-"):
          importlib.import_module(f"palettes.{name}").THEME
          for name in palette.PALETTES}
out = HERE.parents[1] / "themes.json"
out.write_text(json.dumps(themes, indent=2, ensure_ascii=False) + "\n",
               encoding="utf-8", newline="\n")
print(f"==> wrote {out.relative_to(HERE.parents[1])}")
