"""Single source of truth for the theme's colors.

Every generator imports from here — Kvantum widget art (acrylic_gen), the
Qt palette and kvconfig colors (patch_kvconfig), the KDE color schemes
(colorscheme_gen), and the Plasma desktop theme (plasma_theme_gen). To
re-skin the whole theme, change the base colors below and run
generate_all.py; nothing downstream hard-codes a hex value.

Layout per variant (DARK / LIGHT):
  colors — flat semantic color tokens used by the widget-art generator
  qt     — the Kvantum [GeneralColors] table (Qt palette for non-KDE apps)
  scheme — extra tokens for the KDE .colors scheme files
  a      — opacity table for the acrylic surfaces
"""

# ---------------------------------------------------------------- base hex
G = dict(
    # dragon variant background
    dragon_bg="#181616",
    # gruvbox darks
    dark0_hard="#1d2021", dark0="#282828", dark1="#3c3836", dark_deep="#0f0d0d",
    # gruvbox lights
    light0_hard="#f9f5d7", light0="#fbf1c7", light0_soft="#f2e5bc",
    light1="#ebdbb2", light2="#d5c4a1", light3="#bdae93",
    # grays
    gray="#928374", gray_alt="#7f8c8d", wm_gray="#6d6a57", teal_inactive="#377375",
    # accents
    aqua="#689d6a", aqua_bright="#8ec07c", aqua_faded="#427b58",
    blue_bright="#83a598", blue="#458588", blue_faded="#076678",
    green_bright="#b8bb26", green_faded="#79740e",
    red_kde="#da4453", red_faded="#9d0006",
    orange_kde="#f67400", orange_faded="#af3a03",
    green_kde="#27ae60", purple_faded="#8f3f71", pink="#d3869b",
    sel_link="#fdbc4b", sel_active="#fcfcfc", sel_visited="#bdc3c7",
    white="#ffffff", black="#000000",
)

# text color used on top of the accent (menu hover chips), both variants
ON_ACCENT = G["light0"]


def rgb(hex_color):
    """'#rrggbb' -> 'r,g,b' as used by KDE .colors files."""
    h = hex_color.lstrip("#")
    return ",".join(str(int(h[i:i + 2], 16)) for i in (0, 2, 4))


DARK = dict(
    colors=dict(
        bg=G["dragon_bg"],
        fg=G["light1"],
        fg_bright=G["light0"],
        accent=G["aqua"],
        field=G["dark0_hard"],       # input fields
        popup=G["dark0_hard"],       # menu / tooltip body
        press=G["black"],            # pressed-surface tint
        tab_active=G["light1"],      # active tab fill
        handle=G["light1"],          # slider handle
        handle_hover=G["light0"],
        ring=G["black"],             # slider handle outline
    ),
    qt={
        "window.color": G["dragon_bg"], "base.color": G["dragon_bg"],
        "alt.base.color": G["dark0"], "button.color": G["dark0"],
        "light.color": G["dark1"], "mid.light.color": G["dark0"],
        "dark.color": G["dark_deep"], "mid.color": G["dark0"],
        "highlight.color": G["aqua"], "inactive.highlight.color": G["dark1"],
        "text.color": G["light1"], "window.text.color": G["light1"],
        "button.text.color": G["light1"],
        "disabled.text.color": G["light1"] + "78",
        "tooltip.text.color": G["light1"], "highlight.text.color": G["light1"],
        "link.color": G["blue_bright"], "link.visited.color": G["pink"],
        "progress.indicator.text.color": G["light1"],
    },
    scheme=dict(
        name="Gruvbox Dragon", id="GruvboxColors",
        bg_alt=G["dark1"],
        fg_active=G["green_bright"], fg_inactive=G["teal_inactive"],
        link=G["aqua_bright"], visited=G["gray_alt"],
        negative=G["red_kde"], neutral=G["orange_kde"], positive=G["green_kde"],
        accent_hover=G["blue_bright"],
        selection_fg=G["light1"], selection_alt=G["aqua_bright"],
        wm_inactive_fg=G["wm_gray"], wm_inactive_blend=G["dark1"],
    ),
    a=dict(
        menu=0.76, menu_border=0.05,
        btn_fill=0.07, btn_border=0.16, hov_fill=0.12, hov_border=0.55,
        press=0.25, prs_border=0.12, tgl_fill=0.28, tgl_border=0.55,
        edit_fill=0.50, edit_border=0.14, edit_focus=0.80,
        tab_fill=0.05, tab_border=0.10, tab_hov=0.09,
        tab_active=0.14, tab_active_border=0.18,
        frame_fill=0.04, frame_border=0.10,
        item_hov=0.07, item_prs=0.28, item_sel=0.35,
        mitem_hov=0.12, mitem_sel=0.90, shadow=0.22,
        mbar_hov=0.10, mbar_prs=0.16, hairline=0.12,
        groove=0.15, bar_dis=0.20,
        sb_n=0.28, sb_f=0.45, sb_p=0.80,
        sl_groove=0.18, handle_dis=0.40, ring=0.25, focus=0.55,
    ),
)

LIGHT = dict(
    colors=dict(
        bg=G["light0"],
        fg=G["dark1"],
        fg_bright=G["dark0"],
        accent=G["aqua"],
        field=G["light0_hard"],
        popup=G["light0"],
        press=G["dark1"],
        tab_active=G["light0_hard"],
        handle=G["light0_hard"],
        handle_hover=G["light0_hard"],
        ring=G["dark1"],
    ),
    qt={
        "window.color": G["light0"], "base.color": G["light0"],
        "alt.base.color": G["light0_soft"], "button.color": G["light1"],
        "light.color": G["light0_hard"], "mid.light.color": G["light0_soft"],
        "dark.color": G["light3"], "mid.color": G["light2"],
        "highlight.color": G["aqua"], "inactive.highlight.color": G["light0"],
        "text.color": G["dark1"], "window.text.color": G["dark1"],
        "button.text.color": G["dark1"],
        "disabled.text.color": G["dark1"] + "78",
        "tooltip.text.color": G["dark1"], "highlight.text.color": G["light0"],
        "link.color": G["blue_faded"], "link.visited.color": G["purple_faded"],
        "progress.indicator.text.color": G["dark1"],
    },
    scheme=dict(
        name="Gruvbox Dragon Light", id="GruvboxColorsLight",
        bg_alt=G["light1"],
        fg_active=G["green_faded"], fg_inactive=G["gray"],
        link=G["aqua_faded"], visited=G["purple_faded"],
        negative=G["red_faded"], neutral=G["orange_faded"], positive=G["green_faded"],
        accent_hover=G["blue"],
        selection_fg=G["light0"], selection_alt=G["aqua_faded"],
        wm_inactive_fg=G["gray"], wm_inactive_blend=G["light2"],
    ),
    a=dict(
        menu=0.84, menu_border=0.07,
        btn_fill=0.06, btn_border=0.14, hov_fill=0.10, hov_border=0.60,
        press=0.16, prs_border=0.12, tgl_fill=0.30, tgl_border=0.60,
        edit_fill=0.75, edit_border=0.18, edit_focus=0.90,
        tab_fill=0.04, tab_border=0.09, tab_hov=0.08,
        tab_active=0.90, tab_active_border=0.16,
        frame_fill=0.03, frame_border=0.09,
        item_hov=0.06, item_prs=0.30, item_sel=0.40,
        mitem_hov=0.10, mitem_sel=0.90, shadow=0.16,
        mbar_hov=0.08, mbar_prs=0.14, hairline=0.12,
        groove=0.12, bar_dis=0.20,
        sb_n=0.30, sb_f=0.50, sb_p=0.80,
        sl_groove=0.15, handle_dis=0.30, ring=0.35, focus=0.70,
    ),
)

# Layout metrics shared across the widget system — one spacing rhythm for
# every control (consumed by patch_kvconfig.py)
METRICS = dict(
    layout_spacing="6",           # gap between widgets in layouts
    layout_margin="9",            # margin around layouts / dialog edges
    toolbar_item_spacing="1",
    toolbar_interior_spacing="3",
    control_frame="4",            # frame/padding of buttons/combos/inputs
    text_margin_h="3",            # horizontal text padding inside controls
    text_margin_v="1",            # vertical text padding inside controls
    control_min_height="+0.3font",  # uniform height for buttons/combos/inputs
    itemview_frame="3",           # padding of list/grid item boxes
)

# Plasma desktop theme surface opacities (variant-agnostic: the theme's SVGs
# take their color from the active scheme at runtime)
PLASMA = dict(
    dialog=(0.72, 0.90),        # (translucent variant, normal variant)
    widget=(0.75, 0.90),
    tooltip=(0.80, 0.92),
    panel=(0.65, 0.85),
)
