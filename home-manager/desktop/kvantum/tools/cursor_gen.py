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


# gruvbox beachball — the playful mac-style wait spinner: six palette
# wedges behind a glove-style contrast rim with a little ivory hub
BALL_COLORS = (G["aqua"], G["aqua_bright"], G["green_bright"],
               G["sel_link"], G["orange_kde"], G["pink"])

# animated cursors: enough frames at a short delay to stay fluid on
# high-refresh displays (48 x 20ms = 50fps, ~1s per rotation)
NFRAMES = 48
FRAME_DELAY = 20


def beachball(v, cx, cy, r, angle):
    parts = [f'<circle cx="{cx}" cy="{cy}" r="{r + 3}" fill="{v.O}"/>']
    for i, color in enumerate(BALL_COLORS):
        a0 = angle + i * 60
        x0 = cx + r * math.cos(math.radians(a0))
        y0 = cy + r * math.sin(math.radians(a0))
        x1 = cx + r * math.cos(math.radians(a0 + 60))
        y1 = cy + r * math.sin(math.radians(a0 + 60))
        parts.append(f'<path d="M {cx} {cy} L {x0:.1f} {y0:.1f} '
                     f'A {r} {r} 0 0 1 {x1:.1f} {y1:.1f} Z" fill="{color}"/>')
    parts.append(f'<circle cx="{cx}" cy="{cy}" r="{r * 0.28:.1f}" '
                 f'fill="{G["light0"]}" stroke="{v.O}" stroke-width="4"/>')
    return "".join(parts)


ARROW = "M 32 12 L 32 98 L 53 79 L 65 108 L 81 101 L 68 73 L 97 71 Z"

# Mac-style glove hands, built from anatomical parts welded by the
# two-pass rim: tapered SPLAYED finger capsules (angled, bowed sides,
# bulbous tips), round knuckle bulges in an arc, organic palm blobs, a
# flared cuff, and CURVED interior crease strokes — straight parallel
# fingers and straight creases read as boxy and lifeless.
def capsule(bx, by, ang, L, wb, wt, bow=2.0):
    """Tapered finger: base (bx,by), tilt ang degrees from vertical,
    length L, base/tip widths wb/wt, sides bowed outward slightly."""
    a = math.radians(ang)
    ux, uy = math.sin(a), -math.cos(a)
    nx, ny = math.cos(a), math.sin(a)
    tx, ty = bx + ux * L, by + uy * L
    blx, bly = bx - nx * wb / 2, by - ny * wb / 2
    brx, bry = bx + nx * wb / 2, by + ny * wb / 2
    tlx, tly = tx - nx * wt / 2, ty - ny * wt / 2
    trx, try_ = tx + nx * wt / 2, ty + ny * wt / 2
    mw = (wb + wt) / 2 + bow  # bowed mid width
    mlx, mly = bx + ux * L * 0.55 - nx * mw / 2, by + uy * L * 0.55 - ny * mw / 2
    mrx, mry = bx + ux * L * 0.55 + nx * mw / 2, by + uy * L * 0.55 + ny * mw / 2
    r = wt / 2
    return (f"M {blx:.1f} {bly:.1f} Q {mlx:.1f} {mly:.1f} {tlx:.1f} {tly:.1f} "
            f"A {r:.1f} {r:.1f} 0 0 1 {trx:.1f} {try_:.1f} "
            f"Q {mrx:.1f} {mry:.1f} {brx:.1f} {bry:.1f} Z")


POINTING_PARTS = (
    [f'<path d="{capsule(52, 60, -3, 41, 17, 14)}" {{fs}}/>'] +
    [f'<circle cx="{cx}" cy="{cy}" r="{r}" {{fs}}/>'
     for cx, cy, r in ((70, 52, 9.5), (84, 55.5, 9), (96.5, 60, 8))] +
    ['<path d="M 42 66 C 42 58 47 54 55 54 L 90 54 C 100 56 105 62 105 72 '
     'C 105 84 101 94 92 99 C 84 102 60 102 52 100 C 45 98 42 92 41 84 '
     'C 40 76 41 70 42 66 Z" {fs}/>',
     f'<path d="{capsule(44, 78, -125, 20, 15, 12)}" {{fs}}/>',
     '<rect x="40" y="100" width="56" height="14" rx="7" {fs}/>']
)
POINTING_CREASES = ["M 63 52 Q 62 60 61 68", "M 77 52 Q 77 60 76 67",
                    "M 90 56 Q 90 62 89 68", "M 46 68 Q 40 74 38 82",
                    "M 44 101 Q 66 105 92 101"]

OPEN_PARTS = (
    [f'<path d="{capsule(*p)}" {{fs}}/>' for p in
     ((38, 58, -12, 36, 17, 13), (56, 56, -4, 36, 17, 14),
      (74, 57, 4, 37, 17, 13), (90, 60, 13, 30, 15, 11),
      (38, 76, -58, 20, 16, 13))] +
    ['<path d="M 26 66 C 25 58 30 54 38 54 L 92 54 C 100 54 104 60 104 68 '
     'C 105 78 103 88 96 95 C 88 102 74 104 60 103 C 44 102 32 98 28 88 '
     'C 25 80 25 72 26 66 Z" {fs}/>',
     '<rect x="34" y="102" width="62" height="14" rx="7" {fs}/>']
)
OPEN_CREASES = ["M 47 57 Q 46 66 43 73", "M 65 55 Q 65 63 64 71",
                "M 82 57 Q 82 64 80 70", "M 38 103 Q 64 107 92 103"]

CLOSED_PARTS = (
    [f'<circle cx="{cx}" cy="{cy}" r="{r}" {{fs}}/>'
     for cx, cy, r in ((42, 52, 10), (60, 47, 11), (78, 48, 10.5), (94, 54, 9))] +
    ['<path d="M 26 74 C 25 62 30 54 40 52 L 96 52 C 102 54 106 60 106 68 '
     'C 107 76 105 84 100 89 C 92 95 78 96 64 96 C 48 96 34 94 29 86 '
     'C 26 82 26 78 26 74 Z" {fs}/>',
     f'<path d="{capsule(64, 86, -90, 26, 15, 12)}" {{fs}}/>',
     '<rect x="36" y="96" width="58" height="14" rx="7" {fs}/>']
)
CLOSED_CREASES = ["M 51 50 Q 52 58 51 64", "M 69 46 Q 70 54 69 61",
                  "M 86 50 Q 87 57 86 63", "M 40 82 Q 52 78 64 83",
                  "M 40 97 Q 64 101 90 97"]


def creases(ds, v, w=4):
    return "".join(
        f'<path d="{d}" fill="none" stroke="{v.O}" stroke-width="{w}" '
        f'stroke-linecap="round" opacity="0.65"/>' for d in ds)


# ---------------------------------------------------------------- cursors
def build_cursors(v):
    """name -> (frames, hotspot, delay_ms). frames = list of svg inner."""
    c = {}

    c["default"] = ([solid([f'<path d="{ARROW}" {{fs}}/>'], v)], (32, 12), 0)

    c["pointer"] = ([solid(POINTING_PARTS, v) +
                     creases(POINTING_CREASES, v)], (50, 12), 0)

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

    c["wait"] = ([beachball(v, 64, 64, 38, k * 360 / NFRAMES)
                  for k in range(NFRAMES)], (64, 64), FRAME_DELAY)

    c["progress"] = ([solid([f'<path d="{ARROW}" {{fs}}/>'], v) +
                      beachball(v, 92, 92, 24, k * 360 / NFRAMES)
                      for k in range(NFRAMES)], (32, 12), FRAME_DELAY)

    c["openhand"] = ([solid(OPEN_PARTS, v) +
                      creases(OPEN_CREASES, v)], (64, 64), 0)

    c["closedhand"] = ([solid(CLOSED_PARTS, v) +
                        creases(CLOSED_CREASES, v)], (64, 68), 0)

    pencil = rot(
        solid(['<rect x="55" y="22" width="18" height="60" rx="5" {fs}/>',
               '<path d="M 55 82 L 64 106 L 73 82 Z" {fs}/>'], v) +
        f'<rect x="55" y="12" width="18" height="12" rx="4" fill="{v.A}" '
        f'stroke="{v.O}" stroke-width="5"/>', 45)
    c["pencil"] = ([pencil], (36, 92), 0)

    c["up-arrow"] = ([solid(['<path d="M 64 14 L 42 50 L 56 50 L 56 106 '
                             'L 72 106 L 72 50 L 86 50 Z" {fs}/>'], v)], (64, 14), 0)

    # zoom lenses: filled glass so the glyphs actually read, and
    # color-coded bold glyphs — aqua + for in, red − for out — so the
    # two are distinguishable at a glance even at 24px
    handle = lines(["M 80 80 L 107 107"], v, w=16, ow=26)
    glass = solid(['<circle cx="55" cy="55" r="33" {fs}/>'], v)
    zoom_in = handle + glass + (
        f'<path d="M 41 55 L 69 55 M 55 41 L 55 69" fill="none" '
        f'stroke="{v.A}" stroke-width="13" stroke-linecap="round"/>')
    zoom_out = handle + glass + (
        f'<path d="M 41 55 L 69 55" fill="none" '
        f'stroke="{v.R}" stroke-width="13" stroke-linecap="round"/>')
    c["zoom-in"] = ([zoom_in], (55, 55), 0)
    c["zoom-out"] = ([zoom_out], (55, 55), 0)

    # arrow + menu-list badge
    c["context-menu"] = ([solid([f'<path d="{ARROW}" {{fs}}/>',
                                 '<rect x="74" y="72" width="42" height="40" rx="9" {fs}/>'], v) +
                          f'<path d="M 83 84 H 107 M 83 92 H 107 M 83 100 H 99" fill="none" '
                          f'stroke="{v.A}" stroke-width="6" stroke-linecap="round"/>'],
                         (32, 12), 0)

    # spreadsheet cell plus
    c["cell"] = ([lines(["M 64 26 L 64 102", "M 26 64 L 102 64"], v, w=14, ow=26)],
                 (64, 64), 0)

    # eyedropper, tip to the lower left, aqua drop in the tube
    dropper = rot(
        solid(['<circle cx="64" cy="26" r="13" {fs}/>',
               '<rect x="56" y="30" width="16" height="52" rx="6" {fs}/>',
               '<path d="M 56 80 L 64 102 L 72 80 Z" {fs}/>'], v) +
        f'<rect x="59" y="58" width="10" height="20" rx="5" fill="{v.A}"/>', 45)
    c["color-picker"] = ([dropper], (37, 91), 0)

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
    "context-menu": ["context_menu"],
    "cell": ["plus"],
    "color-picker": ["eyedropper"],
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
