#!/usr/bin/env python3
"""Generate the palette's Plasma global-theme (look-and-feel) pair.

These packages ARE the light/dark toggle: kdeglobals [KDE]
DefaultDarkLookAndFeel / DefaultLightLookAndFeel name them, and applying
one writes its contents/defaults into the kdedefaults layer.

A package's defaults are three layers, later ones winning key by key:
  1. BASE — the desktop's look, shared by every theme (window decoration,
     task switchers, ...). Change it here, once.
  2. the theme overlay — only what a palette owns: color scheme, icons,
     cursors, Kvantum variant and the acrylic Plasma style, all by the
     names in THEME.
  3. THEME["lnf_overrides"], optional — {file: {group: {key: value}}} for
     a theme that must depart from BASE; a value may be a (dark, light)
     pair. Nested, not tuple-keyed: THEME is exported to themes.json.

Only metadata.json and contents/defaults are written here. Everything else
a package carries — the panel layout in contents/layouts — lives ONCE in
../../look-and-feel/.base/ and kde.nix joins it under every package; a
package that ships its own copy of a file overrides the shared one.

Output: ../../look-and-feel/<id>/ relative to this script.
"""
import json
from pathlib import Path

import palette

OUT = Path(__file__).resolve().parent.parent.parent / "look-and-feel"
T = palette.THEME

BASE = {
    "kwinrc": {
        "DesktopSwitcher": {"LayoutName": "org.kde.breeze.desktop"},
        "WindowSwitcher": {"LayoutName": "org.kde.breeze.desktop"},
        "org.kde.kdecoration2": {"library": "org.kde.breeze", "theme": "Breeze"},
    },
}


def overlay(i):
    # Kvantum's naming convention does the light/dark split of the widget
    # style: "kvantum-dark" loads <kvantum.kvconfig theme>Dark
    return {
        "kcminputrc": {"Mouse": {"cursorTheme": T["cursors"][i]}},
        "kdeglobals": {
            "General": {"ColorScheme": T["scheme"][i]},
            "Icons": {"Theme": T["icons"][i]},
            "KDE": {"widgetStyle": "kvantum-dark" if i == 0 else "kvantum"},
        },
        "plasmarc": {"Theme": {"name": T["plasma"][0]}},
    }


def defaults(i):
    merged = {}
    for layer in (BASE, overlay(i), T.get("lnf_overrides", {})):
        for f, groups in layer.items():
            for g, keys in groups.items():
                merged.setdefault((f, g), {}).update(
                    {k: v[i] if isinstance(v, (tuple, list)) else v
                     for k, v in keys.items()})
    return "\n".join(
        f"[{f}][{g}]\n" + "".join(f"{k}={v}\n" for k, v in keys.items())
        for (f, g), keys in sorted(merged.items()))


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
