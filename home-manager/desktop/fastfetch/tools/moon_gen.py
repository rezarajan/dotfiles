#!/usr/bin/env python3
"""Render the current moon phase as a PNG for the fastfetch greeting.

Usage: moon_gen.py <out.png> [YYYY-MM-DD]

Phase math is the classic synodic approximation against a known new-moon
epoch (2000-01-06 18:14 UTC) — good to a few hours, plenty for a logo.
The lit region is drawn exactly: limb semicircle on the lit side plus a
terminator half-ellipse whose semi-axis is R*cos(2*pi*phase). Gruvbox
ivory moon with clipped craters and a soft glow, transparent background.
"""
import math
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path

SYNODIC = 29.530588861
EPOCH = datetime(2000, 1, 6, 18, 14, tzinfo=timezone.utc).timestamp()

IVORY = "#fbf1c7"
CREAM = "#ebdbb2"
SAND = "#d5c4a1"
DARKSIDE = "#1d2021"
RIM = "#504945"
GOLD = "#fdbc4b"

S = 512
CX = CY = S // 2
R = 170


def phase_fraction(when=None):
    """0 = new, 0.5 = full, -> 1 = next new."""
    t = time.time() if when is None else when
    return ((t - EPOCH) / 86400.0 % SYNODIC) / SYNODIC


def lit_path(p):
    """SVG path for the illuminated region at phase p, or None/'full'."""
    k = (1 - math.cos(2 * math.pi * p)) / 2  # illuminated fraction
    if k < 0.02:
        return None
    if k > 0.98:
        return "full"
    c = math.cos(2 * math.pi * p)
    rx = abs(c) * R
    waxing = p < 0.5
    top, bot = (CX, CY - R), (CX, CY + R)
    if waxing:
        # lit right: down the right limb, back up along the terminator
        limb = f"A {R} {R} 0 0 1 {bot[0]} {bot[1]}"
        term = f"A {rx:.1f} {R} 0 0 {0 if c > 0 else 1} {top[0]} {top[1]}"
    else:
        # lit left: down the left limb, back up along the terminator
        limb = f"A {R} {R} 0 0 0 {bot[0]} {bot[1]}"
        term = f"A {rx:.1f} {R} 0 0 {1 if c > 0 else 0} {top[0]} {top[1]}"
    return f"M {top[0]} {top[1]} {limb} {term} Z"


def star(cx, cy, r):
    pts = []
    for i in range(8):
        rad = r if i % 2 == 0 else r * 0.4
        a = math.radians(-90 + i * 45)
        pts.append(f"{cx + rad * math.cos(a):.1f},{cy + rad * math.sin(a):.1f}")
    return "M" + " L".join(pts) + " Z"


def build_svg(p):
    lit = lit_path(p)
    waxing = p < 0.5
    # glow leans toward the lit limb, but the gradient must fade to zero
    # INSIDE the canvas — a radius past the edge clips into a visible
    # square halo boundary
    glow_cx = CX + (36 if waxing else -36) if lit not in (None, "full") else CX
    glow_r = 208

    craters = [
        (CX - 60, CY - 55, 34), (CX + 45, CY + 20, 46), (CX - 25, CY + 85, 26),
        (CX + 80, CY - 70, 20), (CX - 95, CY + 30, 18), (CX + 10, CY - 25, 14),
    ]

    parts = [f"""<defs>
  <radialGradient id="litshade" cx="0.5" cy="0.45">
    <stop offset="0" stop-color="{IVORY}"/>
    <stop offset="0.75" stop-color="{CREAM}"/>
    <stop offset="1" stop-color="{SAND}"/>
  </radialGradient>
  <radialGradient id="glow">
    <stop offset="0" stop-color="{GOLD}" stop-opacity="0.28"/>
    <stop offset="1" stop-color="{GOLD}" stop-opacity="0"/>
  </radialGradient>
</defs>"""]

    # sprinkling of stars around the moon
    for sx, sy, sr, so in [(70, 90, 11, 0.9), (440, 70, 8, 0.7), (455, 400, 12, 0.85),
                           (60, 420, 7, 0.6), (250, 28, 6, 0.7), (35, 250, 5, 0.5)]:
        parts.append(f'<path d="{star(sx, sy, sr)}" fill="{CREAM}" opacity="{so}"/>')

    if lit is not None:
        parts.append(f'<circle cx="{glow_cx}" cy="{CY}" r="{glow_r}" fill="url(#glow)"/>')

    # dark side with a faint rim
    parts.append(f'<circle cx="{CX}" cy="{CY}" r="{R}" fill="{DARKSIDE}" stroke="{RIM}" stroke-width="2"/>')

    # illuminated region, craters clipped to it
    if lit is not None:
        shape = (f'<circle cx="{CX}" cy="{CY}" r="{R}"/>' if lit == "full"
                 else f'<path d="{lit}"/>')
        parts.append(f'<clipPath id="litclip">{shape}</clipPath>')
        fill = shape.replace("/>", f' fill="url(#litshade)"/>')
        parts.append(fill)
        for ccx, ccy, cr in craters:
            parts.append(f'<circle cx="{ccx}" cy="{ccy}" r="{cr}" fill="{SAND}" '
                         f'opacity="0.55" clip-path="url(#litclip)"/>')
            parts.append(f'<circle cx="{ccx}" cy="{ccy}" r="{cr}" fill="none" stroke="#bdae93" '
                         f'stroke-width="2" opacity="0.5" clip-path="url(#litclip)"/>')

    inner = "\n".join(parts)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}" '
            f'width="{S}" height="{S}">\n{inner}\n</svg>\n')


out = Path(sys.argv[1])
when = None
if len(sys.argv) > 2:
    when = datetime.strptime(sys.argv[2], "%Y-%m-%d").replace(
        tzinfo=timezone.utc).timestamp()

p = phase_fraction(when)
with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
    f.write(build_svg(p))
    tmp = f.name
subprocess.run(["magick", "-background", "none", "-density", "144",
                tmp, "-resize", "512x512", str(out)], check=True)
Path(tmp).unlink()
k = (1 - math.cos(2 * math.pi * p)) / 2
print(f"phase {p:.3f} ({'waxing' if p < 0.5 else 'waning'}, {k * 100:.0f}% lit) -> {out}")
