#!/usr/bin/env python3
"""Generate the Oathkeeper keyblade artwork.

Outputs, next to this script's parent directory:
  ../oathkeeper.svg            master SVG with SMIL animation (glint
                               sweeping up the blade, twinkling stars,
                               swinging wayfinder charm) — viewable in
                               any browser
  ../oathkeeper-frames/k.png   raster frames of the same geometry at
                               animation phase k, for the terminal
                               greeting's kitty-graphics frame flipping

One geometry function builds the scene; the master embeds SMIL, the
frames bake a phase. Gruvbox ivory/gold palette to match the theme.
"""
import math
import shutil
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent
W, H = 300, 640

IVORY = "#fbf1c7"
CREAM = "#ebdbb2"
SAND = "#d5c4a1"
GOLD = "#fdbc4b"
DEEPGOLD = "#d79921"
LINE = "#a89984"
DARK = "#3c3836"
AQUA = "#689d6a"

CX = 150  # blade axis


def star(cx, cy, r, points=5, rot=-90):
    """Five-pointed star path."""
    pts = []
    for i in range(points * 2):
        rad = r if i % 2 == 0 else r * 0.42
        a = math.radians(rot + i * 180 / points)
        pts.append(f"{cx + rad * math.cos(a):.1f},{cy + rad * math.sin(a):.1f}")
    return "M" + " L".join(pts) + " Z"


def scene(phase=None, nphases=6):
    """Return SVG inner markup. phase=None -> SMIL-animated master;
    phase=k -> static snapshot at that animation step."""
    smil = phase is None

    def twinkle(period, delay):
        if not smil:
            # bake a phase-dependent opacity
            t = (phase / nphases + delay) % 1.0
            return f'opacity="{0.35 + 0.65 * abs(math.cos(math.pi * t)):.2f}"'
        return (f'opacity="1"><animate attributeName="opacity" '
                f'values="1;0.35;1" dur="{period}s" begin="{delay}s" '
                f'repeatCount="indefinite"/')

    parts = []

    # ---- defs: glint gradient sweeping up the blade
    if smil:
        glint_anim = ('<animate attributeName="y1" values="640;-200" dur="2.4s" repeatCount="indefinite"/>'
                      '<animate attributeName="y2" values="840;0" dur="2.4s" repeatCount="indefinite"/>')
        y1, y2 = 640, 840
    else:
        t = phase / nphases
        y1 = 640 + (-200 - 640) * t
        y2 = 840 + (0 - 840) * t
        glint_anim = ""
    parts.append(f"""<defs>
  <linearGradient id="glint" gradientUnits="userSpaceOnUse" x1="0" y1="{y1:.0f}" x2="0" y2="{y2:.0f}">
    <stop offset="0" stop-color="{IVORY}" stop-opacity="0"/>
    <stop offset="0.5" stop-color="#ffffff" stop-opacity="0.85"/>
    <stop offset="1" stop-color="{IVORY}" stop-opacity="0"/>
    {glint_anim}
  </linearGradient>
  <linearGradient id="bladeshade" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="{SAND}"/>
    <stop offset="0.35" stop-color="{IVORY}"/>
    <stop offset="0.65" stop-color="{IVORY}"/>
    <stop offset="1" stop-color="{SAND}"/>
  </linearGradient>
  <radialGradient id="tipglow">
    <stop offset="0" stop-color="{GOLD}" stop-opacity="0.5"/>
    <stop offset="1" stop-color="{GOLD}" stop-opacity="0"/>
  </radialGradient>
</defs>""")

    # ---- tip glow + star burst (the "teeth" cluster of Oathkeeper)
    glow_r = 66 if smil else 58 + 14 * abs(math.cos(math.pi * (phase / nphases)))
    parts.append(f'<circle cx="{CX}" cy="86" r="{glow_r:.0f}" fill="url(#tipglow)">')
    if smil:
        parts.append('<animate attributeName="r" values="58;72;58" dur="2.4s" repeatCount="indefinite"/>')
    parts.append('</circle>')

    # ring at the tip
    parts.append(f'<circle cx="{CX}" cy="86" r="30" fill="none" stroke="{CREAM}" stroke-width="7"/>')
    parts.append(f'<circle cx="{CX}" cy="86" r="30" fill="none" stroke="url(#glint)" stroke-width="7"/>')

    # big tip star
    parts.append(f'<path d="{star(CX, 86, 22)}" fill="{GOLD}" stroke="{DEEPGOLD}" stroke-width="2" {twinkle(2.4, 0.0)}/>')
    # side sparkles
    parts.append(f'<path d="{star(CX - 52, 60, 9)}" fill="{IVORY}" {twinkle(1.6, 0.4)}/>')
    parts.append(f'<path d="{star(CX + 52, 60, 9)}" fill="{IVORY}" {twinkle(1.6, 1.0)}/>')
    parts.append(f'<path d="{star(CX + 40, 118, 6)}" fill="{CREAM}" {twinkle(1.2, 0.7)}/>')

    # ---- key teeth: half-heart + bars on the left, joined to the shaft
    parts.append(f"""<g stroke="{CREAM}" stroke-width="10" fill="none" stroke-linecap="round">
  <path d="M {CX - 8} 150 H 96 V 120 M 96 150 V 184 H {CX - 8}"/>
  <path d="M 96 150 H 72 V 132 M 72 150 V 168"/>
</g>""")

    # ---- shaft: tapered, with glint overlay
    parts.append(f"""<path d="M {CX - 9} 116 L {CX + 9} 116 L {CX + 6} 440 L {CX - 6} 440 Z"
      fill="url(#bladeshade)" stroke="{LINE}" stroke-width="2"/>
<path d="M {CX - 9} 116 L {CX + 9} 116 L {CX + 6} 440 L {CX - 6} 440 Z" fill="url(#glint)"/>""")

    # ---- angel-wing crossguard: wings sweep up and outward, feathered
    # scallops on the lower edge, closing back at the shaft
    for sgn in (-1, 1):
        parts.append(f"""<path d="M {CX + sgn * 8} 464
      C {CX + sgn * 34} 434, {CX + sgn * 56} 408, {CX + sgn * 96} 394
      C {CX + sgn * 110} 414, {CX + sgn * 114} 438, {CX + sgn * 104} 458
      C {CX + sgn * 112} 464, {CX + sgn * 116} 474, {CX + sgn * 112} 486
      C {CX + sgn * 98} 482, {CX + sgn * 90} 484, {CX + sgn * 82} 490
      C {CX + sgn * 88} 498, {CX + sgn * 90} 508, {CX + sgn * 84} 518
      C {CX + sgn * 68} 510, {CX + sgn * 54} 508, {CX + sgn * 44} 500
      C {CX + sgn * 32} 490, {CX + sgn * 24} 478, {CX + sgn * 22} 468 Z"
      fill="{IVORY}" stroke="{DEEPGOLD}" stroke-width="3"/>""")
        # feather detail following the leading edge
        parts.append(f'<path d="M {CX + sgn * 30} 448 C {CX + sgn * 50} 428, {CX + sgn * 68} 412, {CX + sgn * 88} 404" '
                     f'fill="none" stroke="{SAND}" stroke-width="3"/>')
        parts.append(f'<path d="M {CX + sgn * 40} 468 C {CX + sgn * 58} 452, {CX + sgn * 76} 442, {CX + sgn * 94} 438" '
                     f'fill="none" stroke="{SAND}" stroke-width="2"/>')

    # ---- grip + pommel
    parts.append(f"""<rect x="{CX - 10}" y="448" width="20" height="88" rx="8" fill="{DARK}" stroke="{DEEPGOLD}" stroke-width="3"/>
<circle cx="{CX}" cy="548" r="13" fill="{GOLD}" stroke="{DEEPGOLD}" stroke-width="3"/>""")

    # ---- keychain: swinging wayfinder charm
    if smil:
        swing = ('<animateTransform attributeName="transform" type="rotate" '
                 f'values="-8 {CX} 548; 8 {CX} 548; -8 {CX} 548" dur="3.2s" '
                 'repeatCount="indefinite"/>')
        ang = 0.0
    else:
        swing = ""
        ang = -8 * math.cos(2 * math.pi * (phase / nphases))
    parts.append(f'<g transform="rotate({ang:.1f} {CX} 548)">{swing}'
                 f'<path d="M {CX} 560 Q {CX + 4} 574 {CX} 588" fill="none" stroke="{LINE}" stroke-width="3" stroke-dasharray="1 6" stroke-linecap="round"/>'
                 f'<path d="{star(CX, 606, 16)}" fill="{GOLD}" stroke="{DEEPGOLD}" stroke-width="2"/>'
                 f'<circle cx="{CX}" cy="606" r="4" fill="{AQUA}"/></g>')

    return "\n".join(parts)


def svg(inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
            f'width="{W}" height="{H}">\n{inner}\n</svg>\n')


NF = 12
master = OUT / "oathkeeper.svg"
master.write_text(svg(scene()))
print(f"wrote {master}")

frames_dir = OUT / "oathkeeper-frames-png"
if frames_dir.exists():
    shutil.rmtree(frames_dir)
frames_dir.mkdir(parents=True)
for k in range(NF):
    fsvg = frames_dir / f"{k:02d}.svg"
    fsvg.write_text(svg(scene(phase=k, nphases=NF)))
    subprocess.run(["magick", "-background", "none", "-density", "144",
                    str(fsvg), "-resize", "360x768", str(frames_dir / f"{k:02d}.png")],
                   check=True)
    fsvg.unlink()
    print(f"wrote {frames_dir / f'{k:02d}.png'}")
