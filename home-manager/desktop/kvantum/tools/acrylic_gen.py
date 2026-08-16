#!/usr/bin/env python3
"""Regenerate Kvantum surface elements as a consistent rounded/acrylic design.

Strips the old boxy 9-patch widget art from Gruvbox(.Dark).svg and appends
script-generated replacements: rounded corners, hairline borders, translucent
fills. Glyphs (arrows, checkboxes, radios, shadows, mdi, tree, spin) are kept.
"""
import re
import xml.etree.ElementTree as ET
from pathlib import Path

# theme dirs live next to this script's parent dir (works both in the
# dotfiles repo and in ~/.config/Kvantum)
BASE = Path(__file__).resolve().parent.parent
SVGNS = "http://www.w3.org/2000/svg"

# ------------------------------------------------------------------- roles
# The design language: which palette token each widget surface uses, at
# which opacity. Colors and opacities both come from palette.py.
import palette


def roles(P):
    col, A = P["colors"], P["a"]
    fg, accent = col["fg"], col["accent"]
    return dict(
        window=col["bg"],
        fg=fg, fg_bright=col["fg_bright"],
        accent=accent,
        menu_bg=col["popup"], menu_alpha=A["menu"],
        menu_border=(fg, A["menu_border"]),
        btn_fill=(fg, A["btn_fill"]), btn_border=(fg, A["btn_border"]),
        hov_fill=(fg, A["hov_fill"]), hov_border=(accent, A["hov_border"]),
        prs_fill=(col["press"], A["press"]), prs_border=(fg, A["prs_border"]),
        tgl_fill=(accent, A["tgl_fill"]), tgl_border=(accent, A["tgl_border"]),
        edit_fill=(col["field"], A["edit_fill"]),
        edit_border=(fg, A["edit_border"]),
        edit_focus_border=(accent, A["edit_focus"]),
        tab_n=((fg, A["tab_fill"]), (fg, A["tab_border"])),
        tab_f=((fg, A["tab_hov"]), (fg, A["tab_border"])),
        tab_t=((col["tab_active"], A["tab_active"]), (fg, A["tab_active_border"])),
        frame_fill=(fg, A["frame_fill"]), frame_border=(fg, A["frame_border"]),
        item_hov=(fg, A["item_hov"]), item_prs=(accent, A["item_prs"]),
        item_sel=(accent, A["item_sel"]),
        mitem_hov=(fg, A["mitem_hov"]), mitem_sel=(accent, A["mitem_sel"]),
        shadow=A["shadow"],
        mbar_hov=(fg, A["mbar_hov"]), mbar_prs=(fg, A["mbar_prs"]),
        hairline=(fg, A["hairline"]),
        groove=(fg, A["groove"]), bar=(accent, 1.0), bar_dis=(fg, A["bar_dis"]),
        sb_n=(fg, A["sb_n"]), sb_f=(fg, A["sb_f"]), sb_p=(accent, A["sb_p"]),
        sl_groove=(fg, A["sl_groove"]), sl_fill=(accent, 1.0),
        cur_n=(col["handle"], 1.0), cur_f=(col["handle_hover"], 1.0),
        cur_p=(accent, 1.0), cur_d=(fg, A["handle_dis"]),
        cur_ring=(col["ring"], A["ring"]),
        focus=(accent, A["focus"]),
    )


DARK = roles(palette.DARK)
LIGHT = roles(palette.LIGHT)

W = 1  # hairline border width
C = 8  # stretched center tile size
GAP = 4


def fmt(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return s if s else "0"


def pathd(ops):
    out = []
    for op in ops:
        if op[0] == "M":
            out.append(f"M {fmt(op[1][0])} {fmt(op[1][1])}")
        elif op[0] == "L":
            out.append(f"L {fmt(op[1][0])} {fmt(op[1][1])}")
        elif op[0] == "A":
            _, r1, r2, sweep, p = op
            out.append(f"A {fmt(r1)} {fmt(r2)} 0 0 {sweep} {fmt(p[0])} {fmt(p[1])}")
        elif op[0] == "Z":
            out.append("Z")
    return " ".join(out)


def rot90(ops, T):
    """Rotate tile-local ops 90 degrees clockwise inside a TxT tile."""
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


def corner_ops(T, r, w):
    """Top-left corner tile: border strip and fill region."""
    if w > 0:
        border = [("M", (0, T)), ("L", (0, r)), ("A", r, r, 1, (r, 0)),
                  ("L", (T, 0)), ("L", (T, w)), ("L", (r, w)),
                  ("A", r - w, r - w, 0, (w, r)), ("L", (w, T)), ("Z",)]
        fill = [("M", (w, T)), ("L", (w, r)), ("A", r - w, r - w, 1, (r, w)),
                ("L", (T, w)), ("L", (T, T)), ("Z",)]
    else:
        border = None
        fill = [("M", (0, T)), ("L", (0, r)), ("A", r, r, 1, (r, 0)),
                ("L", (T, 0)), ("L", (T, T)), ("Z",)]
    return border, fill


class Sheet:
    def __init__(self):
        self.nodes = []
        self.x = 2000.0
        self.y = 2000.0
        self.rowh = 0.0

    def place(self, w, h):
        if self.x > 2600:
            self.x = 2000.0
            self.y += self.rowh + GAP
            self.rowh = 0.0
        pos = (self.x, self.y)
        self.x += w + GAP
        self.rowh = max(self.rowh, h)
        return pos

    def group(self, eid, w, h):
        x, y = self.place(w, h)
        g = ET.Element(f"{{{SVGNS}}}g", {"id": eid,
                       "transform": f"translate({fmt(x)},{fmt(y)})"})
        self.nodes.append(g)
        return g


def add_rect(g, x, y, w, h, color, opacity, rx=0):
    if w <= 0 or h <= 0:
        return
    a = {"x": fmt(x), "y": fmt(y), "width": fmt(w), "height": fmt(h),
         "fill": color, "fill-opacity": fmt(opacity)}
    if rx:
        a["rx"] = fmt(rx)
    ET.SubElement(g, f"{{{SVGNS}}}rect", a)


def add_path(g, ops, color, opacity):
    ET.SubElement(g, f"{{{SVGNS}}}path",
                  {"d": pathd(ops), "fill": color, "fill-opacity": fmt(opacity)})


def ninepatch(sheet, eid, r, fill, border, border_sides=("top", "bottom", "left", "right"),
              interior=True, junct=False):
    """Emit interior + 8 frame tiles for element `eid`."""
    fc, fo = fill if fill else ("#000000", 0.0)
    has_b = border is not None
    bc, bo = border if has_b else ("#000000", 0.0)
    w = W if has_b else 0
    T = max(r, 3)

    if interior:
        g = sheet.group(eid, C, C)
        add_rect(g, 0, 0, C, C, fc, fo)

    # corners: rotate top-left ops clockwise: topleft, topright, bottomright, bottomleft
    cb, cf = corner_ops(T, r, w) if r > 0 else (None, None)
    order = ["topleft", "topright", "bottomright", "bottomleft"]
    for i, name in enumerate(order):
        g = sheet.group(f"{eid}-{name}", T, T)
        side_pair = {"topleft": ("top", "left"), "topright": ("top", "right"),
                     "bottomright": ("bottom", "right"), "bottomleft": ("bottom", "left")}[name]
        cw = w if any(s in border_sides for s in side_pair) else 0
        if r > 0:
            b, f = corner_ops(T, r, cw)
            for _ in range(i):
                b = rot90(b, T) if b else None
                f = rot90(f, T)
            if b and cw:
                add_path(g, b, bc, bo)
            add_path(g, f, fc, fo)
        else:
            # square corner tiles
            bx = {"left": (0, 0, cw, T), "right": (T - cw, 0, cw, T)}
            by = {"top": (0, 0, T, cw), "bottom": (0, T - cw, T, cw)}
            if cw:
                if side_pair[0] in border_sides:
                    add_rect(g, *by[side_pair[0]], bc, bo)
                if side_pair[1] in border_sides:
                    add_rect(g, *bx[side_pair[1]], bc, bo)
            add_rect(g, (cw if side_pair[1] == "left" else 0),
                     (cw if side_pair[0] == "top" else 0),
                     T - cw, T - cw, fc, fo)

    # edges
    def edge(name):
        vert = name in ("left", "right")
        gw, gh = (T, C) if vert else (C, T)
        g = sheet.group(f"{eid}-{name}", gw, gh)
        ew = w if name in border_sides else 0
        if ew:
            pos = {"top": (0, 0, C, ew), "bottom": (0, T - ew, C, ew),
                   "left": (0, 0, ew, C), "right": (T - ew, 0, ew, C)}[name]
            add_rect(g, *pos, bc, bo)
        fpos = {"top": (0, ew, C, T - ew), "bottom": (0, 0, C, T - ew),
                "left": (ew, 0, T - ew, C), "right": (0, 0, T - ew, C)}[name]
        add_rect(g, *fpos, fc, fo)
        return g

    for name in ("top", "bottom", "left", "right"):
        edge(name)
        if junct:
            for j in ("leftjunct", "rightjunct"):
                src = edge(name)
                src.set("id", f"{eid}-{name}-{j}")


def single(sheet, eid, w, h, draw):
    g = sheet.group(eid, w, h)
    draw(g)
    return g


def add_stop(grad, offset, opacity):
    ET.SubElement(grad, f"{{{SVGNS}}}stop",
                  {"offset": fmt(offset), "stop-color": "#000000",
                   "stop-opacity": fmt(opacity)})


def shadow_frame(sheet, base, F, sh, r, bg, border, S, hint):
    """Popup shadow tiles with the rounded menu body corner baked in.

    In Kvantum's translucent path only <base>-{side} tiles + the interior are
    drawn, so the body's rounded corner and hairline border must live inside
    these tiles.  F = tile size ([Menu]/[ToolTip] frame width), sh = soft
    shadow depth, r = body corner radius, S = peak shadow opacity,
    hint = hint square size (thickness * hint/F = real shadow margin).
    """
    bc, bo = border
    fc, fo = bg
    inner = F - sh          # where the body starts, from the outer edge
    # gradient defs -------------------------------------------------------
    grads = {}
    for side, (x1, y1, x2, y2, o0, o1) in {
            "top": (0, 0, 0, 1, 0, S), "bottom": (0, 0, 0, 1, S, 0),
            "left": (0, 0, 1, 0, 0, S), "right": (0, 0, 1, 0, S, 0)}.items():
        gid = f"acrg-{base}-{side}"
        lg = ET.Element(f"{{{SVGNS}}}linearGradient",
                        {"id": gid, "x1": fmt(x1), "y1": fmt(y1),
                         "x2": fmt(x2), "y2": fmt(y2)})
        add_stop(lg, 0, o0)
        # eased falloff so the outer shadow edge doesn't read as a line
        add_stop(lg, 0.55 if o1 > o0 else 0.45, max(o0, o1) * 0.30)
        add_stop(lg, 1, o1)
        sheet.nodes.append(lg)
        grads[side] = gid
    centers = {"topleft": (F, F), "topright": (0, F),
               "bottomright": (0, 0), "bottomleft": (F, 0)}
    for corner, (cx, cy) in centers.items():
        gid = f"acrg-{base}-c-{corner}"
        rg = ET.Element(f"{{{SVGNS}}}radialGradient",
                        {"id": gid, "cx": fmt(cx), "cy": fmt(cy),
                         "r": fmt(F), "gradientUnits": "userSpaceOnUse"})
        add_stop(rg, 0, S)
        add_stop(rg, r / F, S)
        add_stop(rg, (r / F + 1) / 2, S * 0.30)
        add_stop(rg, 1, 0)
        sheet.nodes.append(rg)

    # edge tiles ----------------------------------------------------------
    for side in ("top", "bottom", "left", "right"):
        vert = side in ("left", "right")
        gw, gh = (F, C) if vert else (C, F)
        g = sheet.group(f"{base}-{side}", gw, gh)
        rects = {  # (shadow, border, body) rects per side
            "top": ((0, 0, C, sh), (0, sh, C, W), (0, sh + W, C, inner - W)),
            "bottom": ((0, F - sh, C, sh), (0, inner - W, C, W), (0, 0, C, inner - W)),
            "left": ((0, 0, sh, C), (sh, 0, W, C), (sh + W, 0, inner - W, C)),
            "right": ((F - sh, 0, sh, C), (inner - W, 0, W, C), (0, 0, inner - W, C)),
        }[side]
        sx, sy, sw2, sh2 = rects[0]
        ET.SubElement(g, f"{{{SVGNS}}}rect",
                      {"x": fmt(sx), "y": fmt(sy), "width": fmt(sw2),
                       "height": fmt(sh2), "fill": f"url(#{grads[side]})"})
        add_rect(g, *rects[1], bc, bo)
        add_rect(g, *rects[2], fc, fo)

    # corner tiles (top-left drawn, others rotated) -----------------------
    shadow_ops = [("M", (0, 0)), ("L", (F, 0)), ("L", (F, sh)),
                  ("A", r, r, 0, (sh, F)), ("L", (0, F)), ("Z",)]
    ring_ops = [("M", (F, sh)), ("A", r, r, 0, (sh, F)), ("L", (sh + W, F)),
                ("A", r - W, r - W, 1, (F, sh + W)), ("Z",)]
    body_ops = [("M", (F, sh + W)), ("A", r - W, r - W, 0, (sh + W, F)),
                ("L", (F, F)), ("Z",)]
    order = ["topleft", "topright", "bottomright", "bottomleft"]
    for i, corner in enumerate(order):
        g = sheet.group(f"{base}-{corner}", F, F)
        so, ro, bo2 = shadow_ops, ring_ops, body_ops
        for _ in range(i):
            so, ro, bo2 = rot90(so, F), rot90(ro, F), rot90(bo2, F)
        ET.SubElement(g, f"{{{SVGNS}}}path",
                      {"d": pathd(so), "fill": f"url(#acrg-{base}-c-{corner})"})
        add_path(g, ro, bc, bo)
        add_path(g, bo2, fc, fo)

    for side in ("top", "bottom", "left", "right"):
        single(sheet, f"{base}-hint-{side}", hint, hint,
               lambda g, h=hint: add_rect(g, 0, 0, h, h, "#ff00ff", 1.0))


def build_nodes(P):
    s = Sheet()
    btn = dict(normal=(P["btn_fill"], P["btn_border"]),
               focused=(P["hov_fill"], P["hov_border"]),
               pressed=(P["prs_fill"], P["prs_border"]),
               toggled=(P["tgl_fill"], P["tgl_border"]))
    for fam in ("button", "combo"):
        for st, (f, b) in btn.items():
            ninepatch(s, f"{fam}-{st}", 6, f, b)
    ninepatch(s, "lineedit-normal", 6, P["edit_fill"], P["edit_border"])
    ninepatch(s, "lineedit-focused", 6, P["edit_fill"], P["edit_focus_border"])

    menu_fill = (P["menu_bg"], P["menu_alpha"])
    # opaque-compositing fallback frames
    ninepatch(s, "menu-normal", 8, menu_fill, P["menu_border"])
    ninepatch(s, "tooltip-normal", 8, menu_fill, P["menu_border"])
    # translucent path: shadow tiles carry the rounded body corners
    shadow_frame(s, "menu-shadow", 12, 4, 8, menu_fill, P["menu_border"],
                 P["shadow"], 4)
    shadow_frame(s, "tooltip-shadow", 12, 4, 8, menu_fill, P["menu_border"],
                 P["shadow"], 3)
    ninepatch(s, "menuitem-normal", 5, None, None)
    # Kvantum maps State_Selected (hover) to "toggled"; "pressed" is click
    ninepatch(s, "menuitem-pressed", 5, P["mitem_sel"], None)
    ninepatch(s, "menuitem-toggled", 5, P["mitem_sel"], None)
    ninepatch(s, "menuitem-focused", 5, P["mitem_sel"], None)
    ninepatch(s, "menubar-normal", 0, None, P["hairline"], border_sides=("bottom",))
    ninepatch(s, "menubaritem-focused", 5, P["mbar_hov"], None)
    ninepatch(s, "menubaritem-pressed", 5, P["mbar_prs"], None)
    ninepatch(s, "menubaritem-toggled", 5, P["mbar_prs"], None)

    ninepatch(s, "itemview-focused", 4, P["item_hov"], None)
    ninepatch(s, "itemview-pressed", 4, P["item_prs"], None)
    ninepatch(s, "itemview-toggled", 4, P["item_sel"], None)

    for st, key in (("normal", "tab_n"), ("focused", "tab_f"), ("toggled", "tab_t")):
        f, b = P[key]
        ninepatch(s, f"tab-{st}", 6, f, b)
        ninepatch(s, f"floating-tab-{st}", 6, f, b)
    ninepatch(s, "tabframe-normal", 8, P["frame_fill"], P["frame_border"], junct=True)
    ninepatch(s, "tabBarFrame-normal", 0, None, None)
    ninepatch(s, "dock-normal", 8, P["frame_fill"], P["frame_border"])
    ninepatch(s, "dock-focused", 8, P["frame_fill"], P["frame_border"])
    ninepatch(s, "common-normal", 0, None, P["hairline"])

    for st in ("normal", "focused", "pressed", "toggled"):
        ninepatch(s, f"header-{st}", 0, None, P["hairline"], border_sides=("bottom",))

    ninepatch(s, "progress-normal", 3, P["groove"], None)
    ninepatch(s, "progress-pattern-normal", 3, P["bar"], None)
    ninepatch(s, "progress-pattern-disabled", 3, P["bar_dis"], None)
    ninepatch(s, "slider-normal", 2, P["sl_groove"], None)
    ninepatch(s, "slider-toggled", 2, P["sl_fill"], None)
    ninepatch(s, "focus", 3, None, P["focus"], interior=False)

    for st, key in (("normal", "sb_n"), ("focused", "sb_f"), ("pressed", "sb_p")):
        c, o = P[key]
        single(s, f"scrollbarslider-{st}", 6, 24,
               lambda g, c=c, o=o: add_rect(g, 0, 0, 6, 24, c, o, rx=3))
    single(s, "scrollbargroove-normal", 6, 24,
           lambda g: add_rect(g, 0, 0, 6, 24, "#000000", 0.0))

    for st, key in (("normal", "cur_n"), ("focused", "cur_f"),
                    ("pressed", "cur_p"), ("disabled", "cur_d")):
        c, o = P[key]
        rc, ro = P["cur_ring"]

        def draw(g, c=c, o=o, rc=rc, ro=ro):
            ET.SubElement(g, f"{{{SVGNS}}}circle",
                          {"cx": "9", "cy": "9", "r": "8.5", "fill": c,
                           "fill-opacity": fmt(o), "stroke": rc,
                           "stroke-opacity": fmt(ro), "stroke-width": "1"})
        single(s, f"slidercursor-{st}", 18, 18, draw)

    for eid in ("spin-separator-normal", "spin-separator-pressed",
                "spin-separator-top-normal", "spin-separator-top-pressed",
                "spin-separator-bottom-normal", "spin-separator-bottom-pressed"):
        single(s, eid, 2, 8, lambda g: add_rect(g, 0, 0, 2, 8, "#000000", 0.0))
    hc, ho = P["hairline"]
    single(s, "header-separator", 1, 8, lambda g: add_rect(g, 0, 1, 1, 6, hc, ho))
    single(s, "toolbar-handle", 3, 14, lambda g: add_rect(g, 1, 0, 1.5, 14, hc, ho, rx=0.75))
    single(s, "window-normal", 16, 16,
           lambda g: add_rect(g, 0, 0, 16, 16, P["window"], 1.0))
    return s.nodes


# ---------------------------------------------------------------- svg rewrite
def regen_ids(nodes):
    return {n.get("id") for n in nodes}


def rewrite_svg(path, nodes):
    ET.register_namespace("", SVGNS)
    ET.register_namespace("xlink", "http://www.w3.org/1999/xlink")
    ET.register_namespace("inkscape", "http://www.inkscape.org/namespaces/inkscape")
    ET.register_namespace("sodipodi", "http://sodipodi.sourceforge.net/DTD/sodipodi-0.0.dtd")
    ET.register_namespace("dc", "http://purl.org/dc/elements/1.1/")
    ET.register_namespace("cc", "http://creativecommons.org/ns#")
    ET.register_namespace("rdf", "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
    tree = ET.parse(path)
    root = tree.getroot()
    kill = regen_ids(nodes)

    removed = 0
    parents = {c: p for p in root.iter() for c in p}
    for el in list(root.iter()):
        eid = el.get("id")
        if eid in kill and el is not root:
            parents[el].remove(el)
            removed += 1
    for n in nodes:
        root.append(n)
    tree.write(path, xml_declaration=True, encoding="unicode")
    return removed, len(kill)


for theme, pal in (("GruvboxDark", DARK), ("Gruvbox", LIGHT)):
    p = BASE / theme / f"{theme}.svg"
    nodes = build_nodes(pal)
    removed, total = rewrite_svg(p, nodes)
    # sanity: parse back and confirm all ids present exactly once
    txt = p.read_text()
    ids = re.findall(r'id="([^"]+)"', txt)
    from collections import Counter
    cnt = Counter(ids)
    missing = [n.get("id") for n in nodes if cnt[n.get("id")] == 0]
    dupes = [i for i in regen_ids(nodes) if cnt[i] > 1]
    print(f"{theme}: replaced {removed} old elements, emitted {len(nodes)} new; "
          f"missing={missing or 'none'} dupes={dupes or 'none'}")
    ET.parse(p)  # well-formedness check
    print(f"{theme}: XML OK")
