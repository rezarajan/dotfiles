#!/usr/bin/env python3
"""Generate the Gruvbox-Dragon GTK theme pair from the shared palette.

GTK2 has no runtime color mechanism, so the palette is baked in: the
gtkrc includes Breeze's engine-free widget styling and then re-declares
every gtk-color-scheme name with palette values (later definitions win).
Gruvbox-Dragon carries the dark palette, Gruvbox-Dragon-Light the light.

GTK3/4 keep the runtime path: the theme imports Breeze's widget css,
while colors keep flowing from the KDE color scheme via kde-gtk-config's
generated colors.css and the acrylic overlay in ~/.config/gtk-{3,4}.0/ —
both palette-generated — so a single theme follows the light/dark toggle
automatically.

That import is RELATIVE, to a mirror of the distro's Breeze themes parked
beside ours as `.breeze-base/` (home-manager activation, or
install-theme-assets.sh, refreshes it). An absolute /usr/share/themes path
works only outside a sandbox: a flatpak brings its own /usr, Breeze is not
in it, the import dies and GTK silently falls back to Adwaita — which is
how flatpak LibreOffice ended up Adwaita-grey with square scrollbars on top
of our colors.css.

The mirror keeps BOTH Breeze and Breeze-Dark, under their own names, side
by side: Breeze's gtk-dark.css is a 50-byte shim that does
`@import url("../../Breeze-Dark/gtk-3.0/gtk.css")`, so a mirror of Breeze
alone leaves dark mode importing nothing at all — GTK renders raw unstyled
white. Mirroring whole theme directories (not just gtk-3.0/) likewise keeps
Breeze's own ../assets/ urls resolving.
"""
import re
from pathlib import Path, PurePosixPath

import palette

BASE = Path(__file__).resolve().parent.parent.parent
OUT = BASE / "gtk" / "themes"

# Where the mirror comes from and what it is called under the themes dir.
# Kept in sync by hand with kde-gruvbox.nix's gruvboxBreezeMirror and
# hypr/scripts/install-theme-assets.sh, which are what actually build it.
MIRROR_SOURCE = "/usr/share/themes"
MIRROR_DIR = ".breeze-base"
MIRROR_VARIANTS = ("Breeze", "Breeze-Dark")

# relative to <themes dir>/<theme>/gtk-N.0/, so it resolves wherever the
# themes directory is mounted — including a flatpak's XDG_DATA_HOME. The
# trailing "Breeze" matters: it keeps Breeze and Breeze-Dark siblings
# inside the mirror, which is what Breeze's own gtk-dark.css shim expects.
BREEZE = f"../../{MIRROR_DIR}/{MIRROR_VARIANTS[0]}"
# gtk2 has no sandboxed consumers left (no flatpak ships a gtk2 app), and
# it needs Breeze-Dark too, so it keeps the plain distro paths
BREEZE_GTK2 = {"dark": "/usr/share/themes/Breeze-Dark",
               "light": "/usr/share/themes/Breeze"}

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
 * dir, so this one theme follows the light/dark toggle.
 * The import is relative on purpose — see gtk_theme_gen.py's docstring:
 * an absolute /usr path cannot resolve inside a flatpak sandbox. */
@import url("{BREEZE}/{ver}/{css}");
""")


gen_theme("Gruvbox-Dragon", palette.DARK, "dark")
gen_theme("Gruvbox-Dragon-Light", palette.LIGHT, "light")


# ------------------------------------------------------------------ verify
# A dead @import is SILENT: GTK logs nothing a user sees and just renders the
# unstyled default, so both light/dark sheets of both themes get walked here,
# through however many shims Breeze puts in the way. This is what catches a
# mirror that forgot Breeze-Dark — which looks fine until someone toggles.
IMPORT = re.compile(r'@import url\("([^"]+)"\)')


def resolve(base, rel):
    """Join rel onto base's directory WITHOUT resolving symlinks — how GTK
    does it, since GFile keeps the logical path a stylesheet was opened by
    (the themes live behind a home-manager symlink into the nix store)."""
    p = PurePosixPath(base).parent
    for part in PurePosixPath(rel).parts:
        p = p.parent if part == ".." else p if part == "." else p / part
    return p


THEMES = PurePosixPath("/themes")   # stand-in for the deployed themes dir


def on_disk(p):
    """Map a path inside the stand-in themes dir to where its bytes live
    now: our own themes are still in the repo, the mirror's are the
    distro's originals the mirror will be copied from."""
    rel = PurePosixPath(p).relative_to(THEMES)
    if rel.parts[0] == MIRROR_DIR:
        # only what the mirror actually copies counts as present — this is
        # the check that catches a shim reaching for an unmirrored variant
        if rel.parts[1] not in MIRROR_VARIANTS:
            return Path("/nonexistent") / rel
        return Path(MIRROR_SOURCE).joinpath(*rel.parts[1:])
    return OUT.joinpath(*rel.parts)


def verify():
    """Walk every emitted import as GTK would, through however many shims
    Breeze puts in the way. Skipped where the distro themes are absent."""
    if not Path(MIRROR_SOURCE).is_dir():
        print(f"  (import check skipped: no {MIRROR_SOURCE})")
        return
    bad = []
    for name in ("Gruvbox-Dragon", "Gruvbox-Dragon-Light"):
        for ver in ("gtk-3.0", "gtk-4.0"):
            for css in ("gtk.css", "gtk-dark.css"):
                here = THEMES / name / ver / css
                for _ in range(5):
                    f = on_disk(here)
                    if not f.is_file():
                        bad.append(f"{name}/{ver}/{css}: {here} is missing")
                        break
                    m = IMPORT.search(f.read_text(encoding="utf-8",
                                                  errors="replace"))
                    # a shim is nothing but its import; a real sheet is huge
                    if not m or f.stat().st_size > 4096:
                        break
                    here = resolve(here, m.group(1))
                else:
                    bad.append(f"{name}/{ver}/{css}: import chain too deep")
    for line in bad:
        print(f"  IMPORT BROKEN: {line}")
    if bad:
        raise SystemExit(f"gtk_theme_gen: {len(bad)} broken import chain(s)")
    print("  imports resolve: 2 themes x gtk-3.0/gtk-4.0 x light/dark")


verify()
