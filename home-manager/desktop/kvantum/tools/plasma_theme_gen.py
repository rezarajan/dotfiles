#!/usr/bin/env python3
"""Generate the gruvbox-acrylic Plasma desktop theme.

Emits Breeze-compatible FrameSvg sheets (9-patch body + mask-* + shadow-*
frames + margin/inset hints) for dialogs, panel, tooltips, and generic widget
backgrounds, in normal and translucent/ variants. Colors come from the
`current-color-scheme` stylesheet classes, which Plasma rewrites at runtime
from the active KDE color scheme — so one theme serves light and dark.

Geometry (matches the Kvantum acrylic design): 4px transparent inset band
(floating gap, same as Breeze), radius-8 rounded body, 10px soft shadow.

Output: ../../plasma-theme/gruvbox-acrylic/ relative to this script.
"""
import json
from pathlib import Path

import palette

OUT = Path(__file__).resolve().parent.parent.parent / "plasma-theme" / "gruvbox-acrylic"

INSET = 4      # transparent gap between window edge and body (Breeze-like)
RADIUS = 8
F = INSET + RADIUS          # frame tile size
C = 32                      # center tile size
MARGIN = INSET + 4          # content margin (inset + padding), Breeze-compatible
SHADOW = 10                 # shadow band width
SHADOW_PEAK = 0.30
HAIRLINE = 0.07             # ColorScheme-Text alpha for the 1px border

# placeholder values only — Plasma rewrites this stylesheet at runtime from
# the active color scheme
STYLE = f"""
            .ColorScheme-Text {{
                color:{palette.DARK["colors"]["fg"]};
                stop-color:{palette.DARK["colors"]["fg"]};
            }}
            .ColorScheme-Background {{
                color:{palette.DARK["colors"]["bg"]};
                stop-color:{palette.DARK["colors"]["bg"]};
            }}
        """


def fmt(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return s if s else "0"


def pathd(ops):
    out = []
    for op in ops:
        if op[0] in ("M", "L"):
            out.append(f"{op[0]} {fmt(op[1][0])} {fmt(op[1][1])}")
        elif op[0] == "A":
            _, r1, r2, sweep, p = op
            out.append(f"A {fmt(r1)} {fmt(r2)} 0 0 {sweep} {fmt(p[0])} {fmt(p[1])}")
        else:
            out.append("Z")
    return " ".join(out)


def rot90(ops, T):
    out = []
    for op in ops:
        if op[0] in ("M", "L"):
            x, y = op[1]
            out.append((op[0], (T - y, x)))
        elif op[0] == "A":
            _, r1, r2, sweep, (x, y) = op
            out.append(("A", r1, r2, sweep, (T - y, x)))
        else:
            out.append(op)
    return out


class Sheet:
    def __init__(self):
        self.parts = []
        self.defs = []
        self.x = 0.0
        self.y = 0.0
        self.rowh = 0.0

    def place(self, w, h):
        if self.x > 400:
            self.x = 0.0
            self.y += self.rowh + 4
            self.rowh = 0.0
        pos = (self.x, self.y)
        self.x += w + 4
        self.rowh = max(self.rowh, h)
        return pos

    def group(self, eid, w, h, inner):
        x, y = self.place(w, h)
        self.parts.append(
            f'<g id="{eid}" transform="translate({fmt(x)},{fmt(y)})">{inner}</g>')

    def write(self, path):
        w = 460
        h = int(self.y + self.rowh + 8)
        svg = (f'<?xml version="1.0" encoding="UTF-8"?>\n'
               f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
               f'viewBox="0 0 {w} {h}">\n<defs>\n'
               f'<style type="text/css" id="current-color-scheme">{STYLE}</style>\n'
               + "\n".join(self.defs) + "\n</defs>\n"
               + "\n".join(self.parts) + "\n</svg>\n")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(svg)


def bg_rect(x, y, w, h, alpha):
    return (f'<rect x="{fmt(x)}" y="{fmt(y)}" width="{fmt(w)}" height="{fmt(h)}" '
            f'class="ColorScheme-Background" style="fill:currentColor;'
            f'fill-opacity:{fmt(alpha)}"/>')


def fg_rect(x, y, w, h, alpha):
    return (f'<rect x="{fmt(x)}" y="{fmt(y)}" width="{fmt(w)}" height="{fmt(h)}" '
            f'class="ColorScheme-Text" style="fill:currentColor;'
            f'fill-opacity:{fmt(alpha)}"/>')


def bg_path(ops, alpha):
    return (f'<path d="{pathd(ops)}" class="ColorScheme-Background" '
            f'style="fill:currentColor;fill-opacity:{fmt(alpha)}"/>')


def fg_path(ops, alpha):
    return (f'<path d="{pathd(ops)}" class="ColorScheme-Text" '
            f'style="fill:currentColor;fill-opacity:{fmt(alpha)}"/>')


def solid_path(ops):
    return f'<path d="{pathd(ops)}" style="fill:#000000"/>'


CORNERS = ["topleft", "topright", "bottomright", "bottomleft"]


def body_frame(s, alpha, with_hairline=True):
    """Main 9-patch: transparent inset band, hairline, rounded acrylic body."""
    w = 1 if with_hairline else 0
    s.group("center", C, C, bg_rect(0, 0, C, C, alpha))
    # corner ops in the topleft orientation (tile F, body starts at INSET)
    ring = [("M", (F, INSET)), ("A", RADIUS, RADIUS, 0, (INSET, F)),
            ("L", (INSET + w, F)),
            ("A", RADIUS - w, RADIUS - w, 1, (F, INSET + w)), ("Z",)]
    body = [("M", (F, INSET + w)),
            ("A", RADIUS - w, RADIUS - w, 0, (INSET + w, F)),
            ("L", (F, F)), ("Z",)]
    for i, c in enumerate(CORNERS):
        r, b = ring, body
        for _ in range(i):
            r, b = rot90(r, F), rot90(b, F)
        inner = (fg_path(r, HAIRLINE) if with_hairline else "") + bg_path(b, alpha)
        s.group(c, F, F, inner)
    edges = {
        "top": (fg_rect(0, INSET, C, w, HAIRLINE), bg_rect(0, INSET + w, C, F - INSET - w, alpha)),
        "bottom": (fg_rect(0, F - INSET - w, C, w, HAIRLINE), bg_rect(0, 0, C, F - INSET - w, alpha)),
        "left": (fg_rect(INSET, 0, w, C, HAIRLINE), bg_rect(INSET + w, 0, F - INSET - w, C, alpha)),
        "right": (fg_rect(F - INSET - w, 0, w, C, HAIRLINE), bg_rect(0, 0, F - INSET - w, C, alpha)),
    }
    for name, (hl, bgr) in edges.items():
        vert = name in ("left", "right")
        gw, gh = (F, C) if vert else (C, F)
        s.group(name, gw, gh, (hl if with_hairline else "") + bgr)


def mask_frame(s):
    """Solid mask 9-patch defining the rounded window shape (body incl. hairline)."""
    s.group("mask-center", C, C, '<rect width="32" height="32" style="fill:#000"/>')
    corner = [("M", (F, INSET)), ("A", RADIUS, RADIUS, 0, (INSET, F)),
              ("L", (F, F)), ("Z",)]
    for i, c in enumerate(CORNERS):
        ops = corner
        for _ in range(i):
            ops = rot90(ops, F)
        s.group(f"mask-{c}", F, F, solid_path(ops))
    rects = {"top": (0, INSET, C, F - INSET), "bottom": (0, 0, C, F - INSET),
             "left": (INSET, 0, F - INSET, C), "right": (0, 0, F - INSET, C)}
    for name, (x, y, w2, h2) in rects.items():
        vert = name in ("left", "right")
        gw, gh = (F, C) if vert else (C, F)
        s.group(f"mask-{name}", gw, gh,
                f'<rect x="{fmt(x)}" y="{fmt(y)}" width="{fmt(w2)}" height="{fmt(h2)}" style="fill:#000"/>')


def shadow_frame(s):
    """Soft shadow 9-patch used by Plasma dialog shadows (drawn outside the mask)."""
    stops = (f'<stop offset="0" stop-color="#000" stop-opacity="{fmt(SHADOW_PEAK)}"/>'
             f'<stop offset="0.45" stop-color="#000" stop-opacity="{fmt(SHADOW_PEAK * 0.3)}"/>'
             f'<stop offset="1" stop-color="#000" stop-opacity="0"/>')
    for side, (x1, y1, x2, y2) in {"top": (0, 1, 0, 0), "bottom": (0, 0, 0, 1),
                                   "left": (1, 0, 0, 0), "right": (0, 0, 1, 0)}.items():
        s.defs.append(f'<linearGradient id="sg-{side}" x1="{x1}" y1="{y1}" '
                      f'x2="{x2}" y2="{y2}">{stops}</linearGradient>')
    centers = {"topleft": (SHADOW, SHADOW), "topright": (0, SHADOW),
               "bottomright": (0, 0), "bottomleft": (SHADOW, 0)}
    for c, (cx, cy) in centers.items():
        s.defs.append(
            f'<radialGradient id="sg-c-{c}" cx="{cx}" cy="{cy}" r="{SHADOW}" '
            f'gradientUnits="userSpaceOnUse">{stops}</radialGradient>')
    s.group("shadow-center", C, C, "")
    for c in CORNERS:
        s.group(f"shadow-{c}", SHADOW, SHADOW,
                f'<rect width="{SHADOW}" height="{SHADOW}" style="fill:url(#sg-c-{c})"/>')
    for side in ("top", "bottom", "left", "right"):
        vert = side in ("left", "right")
        gw, gh = (SHADOW, C) if vert else (C, SHADOW)
        s.group(f"shadow-{side}", gw, gh,
                f'<rect width="{gw}" height="{gh}" style="fill:url(#sg-{side})"/>')
    for side in ("top", "bottom", "left", "right"):
        s.group(f"shadow-hint-{side}-margin", SHADOW, SHADOW,
                f'<rect width="{SHADOW}" height="{SHADOW}" style="fill:#f0f"/>')


def hints(s, margin=MARGIN):
    for side in ("top", "bottom", "left", "right"):
        s.group(f"hint-{side}-margin", margin, margin,
                f'<rect width="{fmt(margin)}" height="{fmt(margin)}" style="fill:#f0f"/>')
        s.group(f"hint-{side}-inset", INSET, INSET,
                f'<rect width="{INSET}" height="{INSET}" style="fill:#f0f"/>')


def sheet(alpha, panel=False):
    s = Sheet()
    body_frame(s, alpha)
    mask_frame(s)
    shadow_frame(s)
    hints(s)
    if panel:
        s.group("thick-center", C, C, bg_rect(0, 0, C, C, alpha))
        for side in ("top", "bottom", "left", "right"):
            s.group(f"thick-hint-{side}-margin", MARGIN + 2, MARGIN + 2,
                    f'<rect width="{fmt(MARGIN + 2)}" height="{fmt(MARGIN + 2)}" style="fill:#f0f"/>')
    return s


# (path, (translucent alpha, normal alpha), is_panel) — alphas from palette
TARGETS = [
    ("dialogs/background.svg", palette.PLASMA["dialog"], False),
    ("widgets/background.svg", palette.PLASMA["widget"], False),
    ("widgets/tooltip.svg", palette.PLASMA["tooltip"], False),
    ("widgets/panel-background.svg", palette.PLASMA["panel"], True),
]

for rel, (t_alpha, n_alpha), is_panel in TARGETS:
    sheet(n_alpha, is_panel).write(OUT / rel)
    sheet(t_alpha, is_panel).write(OUT / "translucent" / rel)

(OUT / "metadata.json").write_text(json.dumps({
    "KPlugin": {
        "Authors": [{"Email": "rezarajan@gmail.com", "Name": "cascadura"}],
        "Category": "",
        "Description": "Gruvbox acrylic Plasma style — follows the system color scheme",
        "Id": "gruvbox-acrylic",
        "License": "LGPL",
        "Name": "Gruvbox Acrylic",
        "Version": "1.0",
    },
    "X-Plasma-API": "5.0",
}, indent=4) + "\n")

(OUT / "plasmarc").write_text("[AdaptiveTransparency]\nenabled=true\n")

print(f"wrote theme to {OUT}")
for p in sorted(OUT.rglob("*.svg")):
    print(" ", p.relative_to(OUT))
