-- Core options: layout, decoration, input. All colors come from the theme
-- module — no hex values in this file.

local theme = require("lua/theme")
local c = theme.colors

hl.config({
    general = {
        gaps_in = theme.gaps_in,
        gaps_out = theme.gaps_out,
        border_size = theme.border,

        col = {
            -- accent -> bright-accent sweep, matching the KDE focus decoration
            active_border = {
                colors = { theme.rgb(c.border_active), theme.rgb(c.accent_alt) },
                angle = 45,
            },
            inactive_border = theme.rgba(c.border_inactive, 0.85),
        },

        layout = "dwindle",
        resize_on_border = true, -- KDE-style: grab borders/gaps to resize

        snap = { enabled = true }, -- floating windows snap like KWin quick-tiles
    },

    decoration = {
        rounding = theme.radius, -- 12, same as the KWin Round-Corners setup
        rounding_power = 2,

        active_opacity = 1.0,
        inactive_opacity = 1.0,

        -- acrylic: blur behind the translucent bar/menus and any app that
        -- ships transparency (ghostty at 0.96)
        blur = {
            enabled = true,
            size = 8,
            passes = 2,
            popups = true,
            vibrancy = 0.17,
        },

        -- soft plasma-style shadow: outside-only, no harsh spread
        shadow = {
            enabled = true,
            range = 14,
            render_power = 3,
            color = theme.rgba("#000000", c.alpha_shadow + 0.1),
            offset = { 0, 4 },
        },
    },

    input = {
        kb_layout = "us",
        numlock_by_default = true,
        follow_mouse = 1,
        mouse_refocus = false,
        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
            disable_while_typing = true,
            tap_to_click = true,
        },
    },

    binds = {
        workspace_back_and_forth = false,
        drag_threshold = 10,
    },

    group = {
        col = {
            border_active = theme.rgb(c.accent),
            border_inactive = theme.rgba(c.border_inactive, 0.85),
        },
        groupbar = {
            font_family = theme.font.ui,
            font_size = 11,
            height = 20,
            gradients = false,
            text_color = theme.rgb(c.fg_bright),
            col = {
                active = theme.rgba(c.accent, 0.85),
                inactive = theme.rgba(c.bg_alt, 0.85),
            },
        },
    },

    dwindle = {
        preserve_split = true,
        smart_resizing = true,
    },

    master = {
        -- mirrors the KDE tiling layout: ~63/37 master-stack split
        mfact = 0.634,
        new_status = "slave",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        font_family = theme.font.ui,
        background_color = theme.rgb(c.bg),
        focus_on_activate = true, -- meeting links etc. raise their window
        key_press_enables_dpms = true,
    },

    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})

-- three-finger swipe switches workspaces (KDE gesture parity)
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
