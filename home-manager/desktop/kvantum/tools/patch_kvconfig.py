#!/usr/bin/env python3
"""Patch Kvantum kvconfigs: frame widths for the new rounded art, acrylic
knobs, and gruvbox-consistent Qt palette colors."""
from pathlib import Path

import palette

BASE = Path(__file__).resolve().parent.parent


def frames(n, extra=None):
    d = {f"frame.{s}": str(n) for s in ("top", "bottom", "left", "right")}
    if extra:
        d.update(extra)
    return d


M = palette.METRICS

COMMON = {
    "%General": {"attach_active_tab": "false", "progressbar_thickness": "4",
                 "slider_width": "4", "spread_menuitems": "false",
                 "menu_blur_radius": "8", "tooltip_blur_radius": "8",
                 "tooltip_shadow_depth": "4",
                 "layout_spacing": M["layout_spacing"],
                 "layout_margin": M["layout_margin"],
                 "toolbar_item_spacing": M["toolbar_item_spacing"],
                 "toolbar_interior_spacing": M["toolbar_interior_spacing"]},
    "PanelButtonCommand": frames(int(M["control_frame"]), {
        "frame.expansion": "0",
        "text.margin.left": M["text_margin_h"],
        "text.margin.right": M["text_margin_h"],
        "text.margin.top": M["text_margin_v"],
        "text.margin.bottom": M["text_margin_v"],
        "min_height": M["control_min_height"],
    }),
    "Focus": frames(3),
    "Tab": frames(6),
    "TabFrame": frames(8),
    "ToolTip": frames(12),
    "Menu": frames(12),
    "MenuItem": frames(5, {"text.margin.left": "6", "text.margin.right": "6",
                           "text.press.color": palette.ON_ACCENT,
                           "text.toggle.color": palette.ON_ACCENT}),
    "MenuBarItem": frames(5),
    "ItemView": frames(int(M["itemview_frame"])),
    "Slider": frames(2),
    "Progressbar": frames(3),
    "ProgressbarContents": frames(3),
    "Dock": frames(8),
}

# full Qt palette tables come from the shared palette module
DARK_COLORS = {"GeneralColors": dict(palette.DARK["qt"])}
LIGHT_COLORS = {"GeneralColors": dict(palette.LIGHT["qt"])}

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
