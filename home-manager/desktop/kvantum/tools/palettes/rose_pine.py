"""Rosé Pine — main (dark) and Dawn (light) on the shared acrylic design.

Same contract as palettes/gruvbox_dragon.py (the documented reference):
only the colors and the artifact names differ. The opacity tables, layout
metrics and Plasma surface alphas are the DESIGN, not the palette, so they
are taken from the reference rather than copied — the two themes cannot
drift apart in shape, only in color.

Source: https://rosepinetheme.com/palette (main + dawn). Moon is not
shipped; it would be a third palette module, not a third variant here.
"""
from . import gruvbox_dragon as _ref

THEME = dict(
    title="Rosé Pine",
    kvantum=("RosePineDark", "RosePine"),
    scheme=("RosePine", "RosePineDawn"),
    gtk=("Rose-Pine", "Rose-Pine-Dawn"),
    cursors=("Rose-Pine-Cursors", "Rose-Pine-Cursors-Dawn"),
    # Papirus overlays built by kde-gruvbox.nix: current Papirus app icons
    # (the 2022 oomox rose-pine-icon-theme lacked ghostty, zed, lutris...)
    # with the folder art recolored to `papirus_folders` below
    icons=("Rose-Pine-Papirus-Dark", "Rose-Pine-Papirus-Light"),
    plasma=("rose-pine-acrylic", "Rosé Pine Acrylic"),
    lnf=("rose-pine", "rose-pine-dawn"),
    lnf_names=("Rosé Pine", "Rosé Pine Dawn"),
)

# ---------------------------------------------------------------- base hex
MAIN = dict(
    base="#191724", surface="#1f1d2e", overlay="#26233a",
    muted="#6e6a86", subtle="#908caa", text="#e0def4",
    love="#eb6f92", gold="#f6c177", rose="#ebbcba",
    pine="#31748f", foam="#9ccfd8", iris="#c4a7e7",
    hl_low="#21202e", hl_med="#403d52", hl_high="#524f67",
)
DAWN = dict(
    base="#faf4ed", surface="#fffaf3", overlay="#f2e9e1",
    muted="#9893a5", subtle="#797593", text="#575279",
    love="#b4637a", gold="#ea9d34", rose="#d7827e",
    pine="#286983", foam="#56949f", iris="#907aa9",
    hl_low="#f4ede8", hl_med="#dfdad9", hl_high="#cecacd",
)

# The generators also reach into G directly (cursor art, the gtk2 baked
# scheme, the Selection group, the Kvantum seed recolor), by the
# reference palette's slot names. Those names are ROLES here: "dark*" are
# main surfaces, "light*" dawn surfaces, "*_faded" the dawn accents, and
# kvantum_seed.py maps every reference color onto the slot of the same name —
# so each slot below answers "what plays this part in Rosé Pine".
G = dict(
    dragon_bg=MAIN["base"],
    dark0_hard=MAIN["surface"], dark0=MAIN["overlay"], dark1=MAIN["hl_med"],
    dark_deep=MAIN["hl_low"],
    light0_hard=DAWN["surface"], light0=DAWN["base"], light0_soft=DAWN["overlay"],
    light1=MAIN["text"], light2=DAWN["hl_med"], light3=DAWN["hl_high"],
    gray=DAWN["muted"], gray_alt=MAIN["muted"], wm_gray=MAIN["muted"],
    teal_inactive=MAIN["subtle"],
    aqua=MAIN["pine"], aqua_bright=MAIN["foam"], aqua_faded=DAWN["pine"],
    blue_bright=MAIN["foam"], blue=DAWN["foam"], blue_faded=DAWN["pine"],
    green_bright=MAIN["rose"], green_faded=DAWN["pine"],
    red_kde=MAIN["love"], red_faded=DAWN["love"],
    orange_kde=MAIN["gold"], orange_faded=DAWN["gold"],
    green_kde=MAIN["foam"], purple_faded=DAWN["iris"], pink=MAIN["iris"],
    yellow_bright=MAIN["gold"], yellow_faded=DAWN["gold"],
    sel_link=MAIN["gold"], sel_active=DAWN["surface"], sel_visited=MAIN["rose"],
    white="#ffffff", black="#000000",
)

# Papirus folder recolor (kde-gruvbox.nix swaps Papirus' teal folder set
# onto these): body, back flap, and the darker emblem tone on special
# folders (downloads, music, ...). Pine, like the accent.
THEME["papirus_folders"] = dict(
    front=MAIN["pine"], back=DAWN["pine"], glyph=MAIN["base"],
)

# text on the pine accent: main text reads on both pines (5.0:1 on dawn
# pine, 4.1:1 on main pine)
ON_ACCENT = MAIN["text"]

# same derivation as the reference (see its comment): these alphas land on
# what KDE's [ColorEffects:Disabled] fade produces from the scheme
DISABLED_ALPHA_DARK = _ref.DISABLED_ALPHA_DARK
DISABLED_ALPHA_LIGHT = _ref.DISABLED_ALPHA_LIGHT

rgb = _ref.rgb

DARK = dict(
    colors=dict(
        bg=MAIN["base"],
        fg=MAIN["text"],
        fg_bright=DAWN["surface"],
        accent=MAIN["pine"],
        field=MAIN["surface"],
        popup=MAIN["surface"],
        press=G["black"],
        tab_active=MAIN["text"],
        handle=MAIN["text"],
        handle_hover=DAWN["surface"],
        ring=G["black"],
    ),
    qt={
        "window.color": MAIN["base"], "base.color": MAIN["base"],
        "alt.base.color": MAIN["surface"], "button.color": MAIN["overlay"],
        "light.color": MAIN["hl_med"], "mid.light.color": MAIN["overlay"],
        "dark.color": MAIN["hl_low"], "mid.color": MAIN["overlay"],
        "highlight.color": MAIN["pine"], "inactive.highlight.color": MAIN["hl_med"],
        "text.color": MAIN["text"], "window.text.color": MAIN["text"],
        "button.text.color": MAIN["text"],
        "disabled.text.color": MAIN["text"] + DISABLED_ALPHA_DARK,
        "tooltip.text.color": MAIN["text"], "highlight.text.color": MAIN["text"],
        "link.color": MAIN["foam"], "link.visited.color": MAIN["iris"],
        "progress.indicator.text.color": MAIN["text"],
    },
    scheme=dict(
        name="Rosé Pine", id="RosePineColors",
        bg_alt=MAIN["overlay"],
        fg_active=MAIN["rose"], fg_inactive=MAIN["subtle"],
        link=MAIN["foam"], visited=MAIN["iris"],
        negative=MAIN["love"], neutral=MAIN["gold"], positive=MAIN["foam"],
        accent_hover=MAIN["foam"],
        selection_fg=MAIN["text"], selection_alt=MAIN["foam"],
        wm_inactive_fg=MAIN["muted"], wm_inactive_blend=MAIN["hl_med"],
    ),
    a=_ref.DARK["a"],
)

LIGHT = dict(
    colors=dict(
        bg=DAWN["base"],
        fg=DAWN["text"],
        fg_bright=DAWN["text"],
        accent=DAWN["pine"],
        field=DAWN["surface"],
        popup=DAWN["base"],
        press=DAWN["text"],
        tab_active=DAWN["surface"],
        handle=DAWN["surface"],
        handle_hover=DAWN["surface"],
        ring=DAWN["text"],
    ),
    qt={
        "window.color": DAWN["base"], "base.color": DAWN["base"],
        "alt.base.color": DAWN["hl_low"], "button.color": DAWN["overlay"],
        "light.color": DAWN["surface"], "mid.light.color": DAWN["hl_low"],
        "dark.color": DAWN["hl_high"], "mid.color": DAWN["hl_med"],
        "highlight.color": DAWN["pine"], "inactive.highlight.color": DAWN["base"],
        "text.color": DAWN["text"], "window.text.color": DAWN["text"],
        "button.text.color": DAWN["text"],
        "disabled.text.color": DAWN["text"] + DISABLED_ALPHA_LIGHT,
        "tooltip.text.color": DAWN["text"], "highlight.text.color": DAWN["base"],
        "link.color": DAWN["pine"], "link.visited.color": DAWN["iris"],
        "progress.indicator.text.color": DAWN["text"],
    },
    scheme=dict(
        name="Rosé Pine Dawn", id="RosePineDawnColors",
        bg_alt=DAWN["overlay"],
        fg_active=DAWN["pine"], fg_inactive=DAWN["subtle"],
        link=DAWN["pine"], visited=DAWN["iris"],
        negative=DAWN["love"], neutral=DAWN["gold"], positive=DAWN["pine"],
        accent_hover=DAWN["foam"],
        selection_fg=DAWN["base"], selection_alt=DAWN["foam"],
        wm_inactive_fg=DAWN["muted"], wm_inactive_blend=DAWN["hl_med"],
    ),
    a=_ref.LIGHT["a"],
)

METRICS = _ref.METRICS
PLASMA = _ref.PLASMA
