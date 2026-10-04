#!/usr/bin/env python3
"""Generate the palette's Plasma global-theme (look-and-feel) pair.

These packages ARE the light/dark toggle: kdeglobals [KDE]
DefaultDarkLookAndFeel / DefaultLightLookAndFeel name them, and applying
one writes its contents/defaults into the kdedefaults layer — color scheme,
icons, Kvantum widget style, cursors and the acrylic Plasma theme, all by
the names in THEME. Only metadata.json and contents/defaults are written:
anything else in a package (gruvbox's contents/layouts, a hand-kept panel
layout applied only with `plasma-apply-lookandfeel --resetLayout`) is left
alone.

Output: ../../look-and-feel/<id>/ relative to this script.
"""
import json
from pathlib import Path

import palette

OUT = Path(__file__).resolve().parent.parent.parent / "look-and-feel"
T = palette.THEME


def defaults(i):
    # Kvantum's naming convention does the light/dark split of the widget
    # style: "kvantum-dark" loads <kvantum.kvconfig theme>Dark
    style = "kvantum-dark" if i == 0 else "kvantum"
    return f"""\
[kcminputrc][Mouse]
cursorTheme={T["cursors"][i]}

[kdeglobals][General]
ColorScheme={T["scheme"][i]}

[kdeglobals][Icons]
Theme={T["icons"][i]}

[kdeglobals][KDE]
widgetStyle={style}

[kwinrc][DesktopSwitcher]
LayoutName=org.kde.breeze.desktop

[kwinrc][WindowSwitcher]
LayoutName=org.kde.breeze.desktop

[kwinrc][org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze

[plasmarc][Theme]
name={T["plasma"][0]}
"""


for i, variant in enumerate(("dark", "light")):
    root = OUT / T["lnf"][i]
    (root / "contents").mkdir(parents=True, exist_ok=True)
    (root / "metadata.json").write_text(json.dumps({
        "KPackageStructure": "Plasma/LookAndFeel",
        "KPlugin": {
            "Authors": [{"Email": "", "Name": ""}],
            "Description": f"{T['title']} {variant} variant",
            "Id": T["lnf"][i],
            "License": "",
            "Name": T["lnf_names"][i],
            "Website": "",
        },
        "Keywords": "Desktop;Workspace;Appearance;Look and Feel;",
        "X-Plasma-APIVersion": "2",
        "X-Plasma-MainScript": "default",
    }, indent=4, ensure_ascii=False) + "\n")
    (root / "contents" / "defaults").write_text(defaults(i))
    print(f"wrote {root.relative_to(OUT.parent)}")
