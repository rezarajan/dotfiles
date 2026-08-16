#!/usr/bin/env python3
"""Patch Kvantum kvconfigs: frame widths for the new rounded art, acrylic
knobs, and gruvbox-consistent Qt palette colors."""
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent


def frames(n, extra=None):
    d = {f"frame.{s}": str(n) for s in ("top", "bottom", "left", "right")}
    if extra:
        d.update(extra)
    return d


COMMON = {
    "%General": {"attach_active_tab": "false", "progressbar_thickness": "4",
                 "slider_width": "4", "spread_menuitems": "false",
                 "menu_blur_radius": "8", "tooltip_blur_radius": "8",
                 "tooltip_shadow_depth": "4"},
    "PanelButtonCommand": frames(6, {"frame.expansion": "0"}),
    "Focus": frames(3),
    "Tab": frames(6),
    "TabFrame": frames(8),
    "ToolTip": frames(12),
    "Menu": frames(12),
    "MenuItem": frames(5, {"text.margin.left": "6", "text.margin.right": "6",
                           "text.press.color": "#fbf1c7",
                           "text.toggle.color": "#fbf1c7"}),
    "MenuBarItem": frames(5),
    "ItemView": frames(4),
    "Slider": frames(2),
    "Progressbar": frames(3),
    "ProgressbarContents": frames(3),
    "Dock": frames(8),
}

DARK_COLORS = {
    "GeneralColors": {
        "window.color": "#181616", "base.color": "#181616",
        "alt.base.color": "#282828", "button.color": "#282828",
        "light.color": "#3c3836", "mid.light.color": "#282828",
        "dark.color": "#0f0d0d", "mid.color": "#282828",
        "highlight.color": "#689d6a", "inactive.highlight.color": "#3c3836",
        "link.color": "#83a598", "link.visited.color": "#d3869b",
    },
}
LIGHT_COLORS = {
    "GeneralColors": {
        "alt.base.color": "#f2e5bc",
        "light.color": "#f9f5d7", "mid.light.color": "#f2e5bc",
        "dark.color": "#bdae93", "mid.color": "#d5c4a1",
    },
}

DARK_REPLACES = [
    ("#d8dee978", "#ebdbb278"),
    ("#d8dee9", "#ebdbb2"),
    ("#c8c8ca", "#fbf1c7"),
    ("#d2d2d4", "#d5c4a1"),
    ("comment=Medium Dark Gruvbox kvantum theme", "comment=Gruvbox acrylic dark"),
]
LIGHT_REPLACES = [
    ("comment=Light Gruvbox kvantum theme", "comment=Gruvbox acrylic light"),
]


def patch(path, overrides, replaces):
    text = path.read_text()
    for a, b in replaces:
        text = text.replace(a, b)
    lines = text.splitlines()
    out = []
    section = None
    pending = {}

    def flush():
        for k, v in pending.items():
            out.append(f"{k}={v}")

    for ln in lines:
        if ln.startswith("["):
            flush()
            section = ln.strip("[] \t")
            pending = dict(overrides.get(section, {}))
            out.append(ln)
            continue
        key = ln.split("=", 1)[0].strip() if "=" in ln else None
        if key and key in pending:
            out.append(f"{key}={pending.pop(key)}")
        else:
            out.append(ln)
    flush()
    path.write_text("\n".join(out) + "\n")
    print(f"patched {path.name}")


dark = BASE / "GruvboxDark/GruvboxDark.kvconfig"
light = BASE / "Gruvbox/Gruvbox.kvconfig"
patch(dark, {**COMMON, **{k: {**COMMON.get(k, {}), **v} for k, v in DARK_COLORS.items()}}, DARK_REPLACES)
patch(light, {**COMMON, **{k: {**COMMON.get(k, {}), **v} for k, v in LIGHT_COLORS.items()}}, LIGHT_REPLACES)
