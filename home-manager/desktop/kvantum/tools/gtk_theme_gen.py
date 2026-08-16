#!/usr/bin/env python3
"""Generate the Gruvbox-Dragon GTK theme pair from the shared palette.

GTK2 has no runtime color mechanism, so the palette is baked in: the
gtkrc includes Breeze's engine-free widget styling and then re-declares
every gtk-color-scheme name with palette values (later definitions win).
Gruvbox-Dragon carries the dark palette, Gruvbox-Dragon-Light the light.

GTK3/4 keep the runtime path: the theme imports Breeze's widget css by
absolute path (its internal relative asset urls still resolve against
Breeze's own directory), while colors keep flowing from the KDE color
scheme via kde-gtk-config's generated colors.css and the acrylic overlay
in ~/.config/gtk-{3,4}.0/ — both palette-generated — so a single theme
follows the light/dark toggle automatically.
"""
from pathlib import Path

import palette

BASE = Path(__file__).resolve().parent.parent.parent
OUT = BASE / "gtk" / "themes"

BREEZE = "/usr/share/themes/Breeze"
BREEZE_GTK2 = {"dark": "/usr/share/themes/Breeze-Dark", "light": BREEZE}

G = palette.G


def gtk2_scheme(P, variant):
    c = P["colors"]
    dark = variant == "dark"
    return {
        "text_color": c["fg"],
        "base_color": c["field"],
        "insensitive_base_color": G["dragon_bg"] if dark else G["light0_soft"],
        "fg_color": c["fg"],
        "bg_color": c["bg"],
        "selected_fg_color": P["scheme"]["selection_fg"],
        "selected_bg_color": c["accent"],
        "button_fg_color": c["fg"],
        "tooltip_fg_color": c["fg"],
        "tooltip_bg_color": c["popup"],
        "insensitive_fg_color": G["gray"],
        "insensitive_text_color": G["gray"],
        "button_insensitive_fg_color": G["gray"],
        "button_active": c["accent"],
        "border_color": G["dark1"] if dark else G["light3"],
    }


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    print(f"wrote {path.relative_to(BASE)}")


def gen_theme(name, P, variant):
    root = OUT / name

    write(root / "index.theme", f"""[Desktop Entry]
Type=X-GNOME-Metatheme
Name={name}
Comment=Gruvbox acrylic ({variant}), generated from palette.py
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme={name}
MetacityTheme={name}
IconTheme=Gruvbox-Plus-{"Dark" if variant == "dark" else "Light"}
CursorTheme=breeze_cursors
""")

    scheme = gtk2_scheme(P, variant)
    colors = "\n".join(
        f'gtk-color-scheme = "{k}:{v}"' for k, v in scheme.items()
    )
    write(root / "gtk-2.0" / "gtkrc", f"""# {name} — generated from palette.py, do not edit by hand.
# Inherits Breeze's engine-free gtk2 widget styling; the color scheme
# below overrides Breeze's (later gtk-color-scheme definitions win).
include "{BREEZE_GTK2[variant]}/gtk-2.0/gtkrc"

{colors}
""")

    for ver in ("gtk-3.0", "gtk-4.0"):
        for css in ("gtk.css", "gtk-dark.css"):
            write(root / ver / css, f"""/* {name} — generated from palette.py, do not edit by hand.
 * Widget styling comes from Breeze; colors arrive at runtime through
 * kde-gtk-config's colors.css (synced from the active KDE color scheme,
 * itself palette-generated) plus the acrylic overlay in the gtk config
 * dir, so this one theme follows the light/dark toggle. */
@import url("{BREEZE}/{ver}/{css}");
""")


gen_theme("Gruvbox-Dragon", palette.DARK, "dark")
gen_theme("Gruvbox-Dragon-Light", palette.LIGHT, "light")
