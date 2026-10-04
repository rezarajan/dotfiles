#!/usr/bin/env python3
"""Seed a palette's Kvantum theme pair from the reference (Gruvbox) pair.

acrylic_gen.py regenerates the surface art and patch_kvconfig.py the
geometry + Qt palette, but both work IN PLACE on an existing theme: the
glyphs (arrows, check marks, radios, mdi buttons, tree lines) and the
per-widget text.*.color keys are kept from whatever SVG/kvconfig is there.
For the reference palette those come from the original Gruvbox Kvantum
theme. Every other palette gets its pair re-derived from the reference on
each run — a fresh copy with every reference color swapped for the color
playing the same role — before the two in-place generators run over it.

The color mapping, per variant (dark seed -> DARK, light seed -> LIGHT):
  1. tokens: every hex the reference variant's colors/qt/scheme tables use,
     mapped onto what the target palette puts under the same key (a hex
     under several keys takes the majority answer)
  2. near misses (colors the original theme used that are not palette
     tokens, e.g. gruvbox dark2 on focused text): the nearest step-1 hex
     within NEAR, else the nearest reference G slot within NEAR, mapped
     onto the target's same slot
  3. anything further away (Kvantum's #ff00ff markers, neutral greys in
     unused elements) is left alone
No-op for the reference palette itself.
"""
import re
from collections import Counter, defaultdict
from pathlib import Path

import palette
from palettes import gruvbox_dragon as ref

BASE = Path(__file__).resolve().parent.parent
NEAR = 60          # max RGB distance for a step-2 match
HEX = re.compile(r"#([0-9a-fA-F]{6})(?![0-9a-fA-F])|#([0-9a-fA-F]{6})([0-9a-fA-F]{2})(?![0-9a-fA-F])")


def parse(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def dist(a, b):
    return sum((x - y) ** 2 for x, y in zip(parse(a), parse(b))) ** 0.5


def token_map(src, dst):
    votes = defaultdict(Counter)
    for table in ("colors", "qt", "scheme"):
        for key, val in src[table].items():
            want = dst[table].get(key)
            if not (isinstance(val, str) and isinstance(want, str)):
                continue
            if val.startswith("#") and want.startswith("#"):
                votes[val[:7].lower()][want[:7].lower()] += 1
    return {k: c.most_common(1)[0][0] for k, c in votes.items()}


def slot_map():
    return {ref.G[k].lower(): palette.G[k].lower() for k in ref.G if k in palette.G}


def recolor_fn(tokens, slots):
    cache = {}

    def nearest(h, table):
        best = min(table, key=lambda k: dist(h, k))
        return table[best] if dist(h, best) <= NEAR else None

    def one(h):
        h = h.lower()
        if h not in cache:
            cache[h] = (tokens.get(h) or nearest(h, tokens)
                        or nearest(h, slots) or h)
        return cache[h]

    def sub(m):
        if m.group(1):
            return one("#" + m.group(1))
        return one("#" + m.group(2)) + m.group(3)

    return lambda text: HEX.sub(sub, text)


def main():
    if palette.THEME["kvantum"] == ref.THEME["kvantum"]:
        print("  reference palette: Kvantum pair is the seed itself, skipped")
        return
    slots = slot_map()
    for src_name, dst_name, src_p, dst_p in zip(
            ref.THEME["kvantum"], palette.THEME["kvantum"],
            (ref.DARK, ref.LIGHT), (palette.DARK, palette.LIGHT)):
        recolor = recolor_fn(token_map(src_p, dst_p), slots)
        out = BASE / dst_name
        out.mkdir(parents=True, exist_ok=True)
        for ext in ("svg", "kvconfig"):
            text = (BASE / src_name / f"{src_name}.{ext}").read_text()
            (out / f"{dst_name}.{ext}").write_text(recolor(text))
        print(f"  seeded {dst_name} from {src_name}")


main()
