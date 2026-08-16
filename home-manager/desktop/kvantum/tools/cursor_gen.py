#!/usr/bin/env python3
"""Generate the Gruvbox-Dragon cursor theme pair from the shared palette.

Every cursor is drawn as SVG on a 128px design grid from palette colors —
dark theme: ivory cursors with a charcoal rim; light theme: charcoal with
an ivory rim; aqua accents, gruvbox red for 'not allowed', and an aqua
spinner for wait/progress (12 animated frames). Rasterized at 24/32/48px
and compiled with xcursorgen into ../../cursors/<Theme>/ for deployment
to ~/.local/share/icons. index.theme inherits breeze_cursors so any
uncovered shape falls back gracefully.

Needs imagemagick + xcursorgen (override with $XCURSORGEN).
"""
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import palette

G = palette.G
BASE = Path(__file__).resolve().parent.parent.parent
OUT = BASE / "cursors"
SIZES = (24, 32, 48)
D = 128  # design grid
XCURSORGEN = os.environ.get("XCURSORGEN", "xcursorgen")


class V:
    def __init__(self, F, O, A, R):
        self.F, self.O, self.A, self.R = F, O, A, R


DARK = V(F=G["light0"], O=G["dark1"], A=G["aqua"], R=G["red_kde"])
LIGHT = V(F=G["dark1"], O=G["light0"], A=G["aqua_faded"], R=G["red_faded"])


# --------------------------------------------------------------- primitives
def solid(elems, v, fill=None):
    """Filled shapes with a contrast rim. Two passes: a fat contrast
    stroke+fill silhouette, then the body refilled — overlapping elements
    merge into one outlined union."""
    f = fill or v.F
    out = []
    for e in elems:
        out.append(e.format(fs=f'fill="{v.O}" stroke="{v.O}" stroke-width="20" '
                               f'stroke-linejoin="round" stroke-linecap="round"'))
    for e in elems:
        out.append(e.format(fs=f'fill="{f}" stroke="{f}" stroke-width="5" '
                               f'stroke-linejoin="round" stroke-linecap="round"'))
    return "".join(out)


def lines(ds, v, w=13, ow=25, color=None):
    """Stroke glyphs (resize arrows, ibeam …) with a contrast underlay."""
    c = color or v.F
    out = []
    for d in ds:
        out.append(f'<path d="{d}" fill="none" stroke="{v.O}" stroke-width="{ow}" '
                   f'stroke-linejoin="round" stroke-linecap="round"/>')
    for d in ds:
        out.append(f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" '
                   f'stroke-linejoin="round" stroke-linecap="round"/>')
    return "".join(out)


def rot(inner, angle):
    return f'<g transform="rotate({angle} 64 64)">{inner}</g>'


def arc_path(cx, cy, r, a0, a1):
    x0 = cx + r * math.cos(math.radians(a0))
    y0 = cy + r * math.sin(math.radians(a0))
    x1 = cx + r * math.cos(math.radians(a1))
    y1 = cy + r * math.sin(math.radians(a1))
    large = 1 if (a1 - a0) % 360 > 180 else 0
    return f"M {x0:.1f} {y0:.1f} A {r} {r} 0 {large} 1 {x1:.1f} {y1:.1f}"


def spinner(v, cx, cy, r, angle, w=14, ow=22):
    ring = (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" '
            f'stroke="{v.O}" stroke-width="{w}" opacity="0.45"/>')
    d = arc_path(cx, cy, r, angle - 90, angle + 30)
    arc = (f'<path d="{d}" fill="none" stroke="{v.O}" stroke-width="{ow}" stroke-linecap="round"/>'
           f'<path d="{d}" fill="none" stroke="{v.A}" stroke-width="{w}" stroke-linecap="round"/>')
    return ring + arc


ARROW = "M 32 12 L 32 98 L 53 79 L 65 108 L 81 101 L 68 73 L 97 71 Z"

# Hands are single smooth paths: fingertip round caps, folded-knuckle
# bumps, thumb curves. The two-pass rim renders concave valleys and
# creases as dark grooves, which is what makes them read as fingers.
POINTING_HAND = (
    "M 44 60 L 44 20 Q 44 11 52 11 Q 60 11 60 20 L 60 52 "
    "C 60 45 74 45 74 52 L 74 54 C 74 47 88 47 88 54 L 88 58 "
    "C 88 51 100 51 100 58 L 100 62 C 103 66 104 72 103 78 "
    "C 101 94 94 106 78 109 L 58 109 C 49 109 43 103 41 95 "
    "C 39 88 34 82 30 76 C 26 70 28 64 34 63 C 38 62 42 63 44 66 Z"
)

OPEN_HAND = (
    "M 30 92 L 30 34 Q 30 25 38 25 Q 46 25 46 34 L 46 52 L 49 52 "
    "L 49 24 Q 49 15 56 15 Q 64 15 64 24 L 64 50 L 67 50 "
    "L 67 26 Q 67 17 73 17 Q 80 17 80 26 L 80 52 L 83 52 "
    "L 83 36 Q 83 27 89 27 Q 96 27 96 36 L 96 66 "
    "C 98 84 94 98 84 106 Q 72 114 58 113 Q 40 112 32 100 "
    "C 22 94 14 82 20 74 Q 24 68 32 72 Z"
)

CLOSED_HAND = (
    "M 30 78 C 30 64 34 56 44 54 Q 44 46 52 46 Q 59 46 60 54 "
    "Q 61 47 68 47 Q 75 47 76 55 Q 77 48 84 48 Q 91 48 92 56 "
    "Q 98 58 100 66 C 102 76 100 88 94 96 Q 84 106 64 106 "
    "Q 42 106 34 96 Q 28 88 30 78 Z"
)


# ---------------------------------------------------------------- cursors
def build_cursors(v):
    """name -> (frames, hotspot, delay_ms). frames = list of svg inner."""
    c = {}

    c["default"] = ([solid([f'<path d="{ARROW}" {{fs}}/>'], v)], (32, 12), 0)

    c["pointer"] = ([solid([f'<path d="{POINTING_HAND}" {{fs}}/>'], v)], (52, 12), 0)

    c["text"] = ([lines(["M 64 26 L 64 102", "M 53 25 L 75 25",
                         "M 53 103 L 75 103"], v, w=11, ow=23)], (64, 64), 0)

    cross = ["M 64 18 L 64 50", "M 64 78 L 64 110",
             "M 18 64 L 50 64", "M 78 64 L 110 64"]
    c["crosshair"] = ([lines(cross, v) +
                       f'<circle cx="64" cy="64" r="9" fill="{v.A}" '
                       f'stroke="{v.O}" stroke-width="5"/>'], (64, 64), 0)

    hor = ["M 26 64 L 102 64", "M 44 46 L 24 64 L 44 82", "M 84 46 L 104 64 L 84 82"]
    c["size_hor"] = ([lines(hor, v)], (64, 64), 0)
    c["size_ver"] = ([rot(lines(hor, v), 90)], (64, 64), 0)
    c["size_bdiag"] = ([rot(lines(hor, v), -45)], (64, 64), 0)
    c["size_fdiag"] = ([rot(lines(hor, v), 45)], (64, 64), 0)

    allarr = hor + ["M 64 26 L 64 102", "M 46 44 L 64 24 L 82 44", "M 46 84 L 64 104 L 82 84"]
    c["size_all"] = ([lines(allarr, v, w=11, ow=23)], (64, 64), 0)

    c["not-allowed"] = ([lines([arc_path(64, 64, 38, 0, 359.9) + " Z",
                                "M 38 38 L 90 90"], v, color=v.R)], (64, 64), 0)

    qmark = ('M 82 82 C 82 70 102 70 102 82 C 102 91 92 89 92 99'
             '')
    c["help"] = ([solid([f'<path d="{ARROW}" {{fs}}/>'], v) +
                  f'<circle cx="92" cy="92" r="26" fill="{v.A}" stroke="{v.O}" stroke-width="5"/>' +
                  f'<path d="{qmark}" fill="none" stroke="{G["light0"]}" stroke-width="8" stroke-linecap="round"/>' +
                  f'<circle cx="92" cy="109" r="5" fill="{G["light0"]}"/>'], (32, 12), 0)

    c["wait"] = ([spinner(v, 64, 64, 36, k * 30, w=16, ow=26)
                  for k in range(12)], (64, 64), 60)

    c["progress"] = ([solid([f'<path d="{ARROW}" {{fs}}/>'], v) +
                      spinner(v, 92, 92, 22, k * 30, w=12, ow=18)
                      for k in range(12)], (32, 12), 60)

    c["openhand"] = ([solid([f'<path d="{OPEN_HAND}" {{fs}}/>'], v)], (62, 64), 0)

    c["closedhand"] = ([solid([f'<path d="{CLOSED_HAND}" {{fs}}/>'], v) +
                        f'<path d="M 36 90 Q 48 100 62 100" fill="none" '
                        f'stroke="{v.O}" stroke-width="4" stroke-linecap="round" opacity="0.6"/>'],
                       (64, 74), 0)

    pencil = rot(
        solid(['<rect x="55" y="22" width="18" height="60" rx="5" {fs}/>',
               '<path d="M 55 82 L 64 106 L 73 82 Z" {fs}/>'], v) +
        f'<rect x="55" y="12" width="18" height="12" rx="4" fill="{v.A}" '
        f'stroke="{v.O}" stroke-width="5"/>', 45)
    c["pencil"] = ([pencil], (36, 92), 0)

    c["up-arrow"] = ([solid(['<path d="M 64 14 L 42 50 L 56 50 L 56 106 '
                             'L 72 106 L 72 50 L 86 50 Z" {fs}/>'], v)], (64, 14), 0)

    lens = (f'<circle cx="55" cy="55" r="31" fill="none" stroke="{v.O}" stroke-width="24"/>'
            f'<circle cx="55" cy="55" r="31" fill="none" stroke="{v.F}" stroke-width="13"/>')
    handle = lines(["M 79 79 L 106 106"], v, w=15, ow=25)
    zoom_in = lens + handle + lines(["M 43 55 L 67 55", "M 55 43 L 55 67"], v, w=9, ow=0)
    zoom_out = lens + handle + lines(["M 43 55 L 67 55"], v, w=9, ow=0)
    c["zoom-in"] = ([zoom_in], (55, 55), 0)
    c["zoom-out"] = ([zoom_out], (55, 55), 0)

    badge = (f'<rect x="74" y="76" width="40" height="36" rx="9" fill="{v.F}" '
             f'stroke="{v.O}" stroke-width="6"/>')
    c["copy"] = ([solid([f'<path d="{ARROW}" {{fs}}/>'], v) + badge +
                  f'<path d="M 86 94 L 102 94 M 94 86 L 94 102" fill="none" '
                  f'stroke="{v.A}" stroke-width="8" stroke-linecap="round"/>'], (32, 12), 0)
    c["link"] = ([solid([f'<path d="{ARROW}" {{fs}}/>'], v) + badge +
                  f'<rect x="80" y="88" width="18" height="12" rx="6" fill="none" stroke="{v.A}" stroke-width="6"/>' +
                  f'<rect x="92" y="88" width="18" height="12" rx="6" fill="none" stroke="{v.A}" stroke-width="6"/>'],
                 (32, 12), 0)

    c["vertical-text"] = ([rot(c["text"][0][0], 90)], (64, 64), 0)

    return c


ALIASES = {
    "default": ["left_ptr", "arrow", "top_left_arrow", "top-left-arrow"],
    "pointer": ["hand1", "hand2", "pointing_hand", "hand"],
    "text": ["xterm", "ibeam"],
    "wait": ["watch"],
    "progress": ["left_ptr_watch", "half-busy"],
    "crosshair": ["cross", "tcross"],
    "help": ["question_arrow", "whats_this", "left_ptr_help"],
    "not-allowed": ["forbidden", "crossed_circle", "no-drop", "dnd-no-drop", "pirate"],
    "size_ver": ["ns-resize", "n-resize", "s-resize", "row-resize", "split_v",
                 "v_double_arrow", "top_side", "bottom_side", "sb_v_double_arrow"],
    "size_hor": ["ew-resize", "e-resize", "w-resize", "col-resize", "split_h",
                 "h_double_arrow", "left_side", "right_side", "sb_h_double_arrow"],
    "size_bdiag": ["nesw-resize", "ne-resize", "sw-resize", "top_right_corner",
                   "bottom_left_corner"],
    "size_fdiag": ["nwse-resize", "nw-resize", "se-resize", "top_left_corner",
                   "bottom_right_corner"],
    "size_all": ["fleur", "all-scroll", "move"],
    "openhand": ["grab"],
    "closedhand": ["grabbing", "dnd-move", "dnd-none"],
    "pencil": ["draft"],
    "up-arrow": ["up_arrow", "center_ptr"],
    "zoom-in": ["zoom_in"],
    "zoom-out": ["zoom_out"],
    "copy": ["dnd-copy"],
    "link": ["dnd-link", "alias"],
    "vertical-text": ["vertical_text"],
}


def svg_doc(inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {D} {D}" '
            f'width="{D}" height="{D}">{inner}</svg>')


def gen_theme(name, v, comment):
    cdir = OUT / name / "cursors"
    if (OUT / name).exists():
        shutil.rmtree(OUT / name)
    cdir.mkdir(parents=True)
    (OUT / name / "index.theme").write_text(
        f"[Icon Theme]\nName={name}\nComment={comment}\nInherits=breeze_cursors\n")

    cursors = build_cursors(v)
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        for cname, (frames, hot, delay) in cursors.items():
            cfg = []
            for fi, inner in enumerate(frames):
                fsvg = tdp / f"{cname}-{fi}.svg"
                fsvg.write_text(svg_doc(inner))
                for s in SIZES:
                    png = tdp / f"{cname}-{fi}-{s}.png"
                    subprocess.run(["magick", "-background", "none",
                                    str(fsvg), "-resize", f"{s}x{s}", str(png)],
                                   check=True)
                    hx = round(hot[0] * s / D)
                    hy = round(hot[1] * s / D)
                    line = f"{s} {hx} {hy} {png}"
                    if delay:
                        line += f" {delay}"
                    cfg.append((s, line))
            # xcursorgen wants all images; group by declaration order
            cfgfile = tdp / f"{cname}.cfg"
            cfgfile.write_text("\n".join(l for _, l in sorted(cfg, key=lambda x: x[0])) + "\n")
            subprocess.run([XCURSORGEN, str(cfgfile), str(cdir / cname)], check=True)
        for target, names in ALIASES.items():
            for alias in names:
                dst = cdir / alias
                if not dst.exists():
                    dst.symlink_to(target)

    # scalable variants (Plasma 6 svg cursor format): KWin renders these
    # at the exact effective size (cursor size x display scale), so the
    # pointer stays crisp on any display — the xcursor rasters above
    # remain as the fallback for X11/legacy clients. Hotspots are in SVG
    # document coordinates; nominal_size=D maps the design grid 1:1 onto
    # the configured cursor size.
    sdir = OUT / name / "cursors_scalable"
    for cname, (frames, hot, delay) in cursors.items():
        d = sdir / cname
        d.mkdir(parents=True)
        meta = []
        for fi, inner in enumerate(frames):
            fn = f"{cname}-{fi:02d}.svg" if len(frames) > 1 else f"{cname}.svg"
            (d / fn).write_text(svg_doc(inner))
            entry = {"filename": fn, "hotspot_x": hot[0], "hotspot_y": hot[1],
                     "nominal_size": D}
            if delay:
                entry["delay"] = delay
            meta.append(entry)
        (d / "metadata.json").write_text(json.dumps(meta, indent=2) + "\n")
    for target, names in ALIASES.items():
        for alias in names:
            dst = sdir / alias
            if not dst.exists():
                dst.symlink_to(target)
    print(f"built {name} ({len(cursors)} cursors + aliases, xcursor + scalable svg)")


if __name__ == "__main__":
    gen_theme("Gruvbox-Dragon-Cursors", DARK, "Gruvbox acrylic cursors (ivory on dark)")
    gen_theme("Gruvbox-Dragon-Cursors-Light", LIGHT, "Gruvbox acrylic cursors (charcoal on light)")
