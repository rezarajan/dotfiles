#!/usr/bin/env python3
"""Generate the KDE color schemes (GruvboxDragon / GruvboxDragonLight) from
palette.py into ../../color-schemes/. Both variants share one template, so
the schemes stay structural mirrors of each other."""
from pathlib import Path

import palette
from palette import G, rgb

OUT = Path(__file__).resolve().parent.parent.parent / "color-schemes"

EFFECTS = """\
[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65000000000000002
ContrastEffect=1
IntensityAmount=0.10000000000000001
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025000000000000001
ColorEffect=2
ContrastAmount=0.10000000000000001
ContrastEffect=2
Enable=true
IntensityAmount=0
IntensityEffect=0
"""


def group(name, S, col):
    return f"""\
[Colors:{name}]
BackgroundAlternate={rgb(S["bg_alt"])}
BackgroundNormal={rgb(col["bg"])}
DecorationFocus={rgb(col["accent"])}
DecorationHover={rgb(S["accent_hover"])}
ForegroundActive={rgb(S["fg_active"])}
ForegroundInactive={rgb(S["fg_inactive"])}
ForegroundLink={rgb(S["link"])}
ForegroundNegative={rgb(S["negative"])}
ForegroundNeutral={rgb(S["neutral"])}
ForegroundNormal={rgb(col["fg"])}
ForegroundPositive={rgb(S["positive"])}
ForegroundVisited={rgb(S["visited"])}
"""


def selection(S, col):
    return f"""\
[Colors:Selection]
BackgroundAlternate={rgb(S["selection_alt"])}
BackgroundNormal={rgb(col["accent"])}
DecorationFocus={rgb(col["accent"])}
DecorationHover={rgb(S["accent_hover"])}
ForegroundActive={rgb(G["sel_active"])}
ForegroundInactive={rgb(G["light1"])}
ForegroundLink={rgb(G["sel_link"])}
ForegroundNegative={rgb(S["negative"])}
ForegroundNeutral={rgb(G["orange_kde"])}
ForegroundNormal={rgb(S["selection_fg"])}
ForegroundPositive={rgb(G["green_kde"])}
ForegroundVisited={rgb(G["sel_visited"])}
"""


def scheme(P):
    S, col = P["scheme"], P["colors"]
    parts = [EFFECTS,
             group("Button", S, col),
             selection(S, col),
             group("Tooltip", S, col),
             group("View", S, col),
             group("Window", S, col),
             f"""\
[General]
ColorScheme={S["id"]}
Name={S["name"]}
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground={rgb(col["bg"])}
activeBlend={rgb(col["fg"])}
activeForeground={rgb(col["fg"])}
inactiveBackground={rgb(col["bg"])}
inactiveBlend={rgb(S["wm_inactive_blend"])}
inactiveForeground={rgb(S["wm_inactive_fg"])}
"""]
    return "\n".join(parts)


for fname, P in (("GruvboxDragon.colors", palette.DARK),
                 ("GruvboxDragonLight.colors", palette.LIGHT)):
    (OUT / fname).write_text(scheme(P))
    print(f"wrote {OUT / fname}")
