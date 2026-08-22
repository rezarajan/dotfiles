-- Environment variables. These are set before any client starts; changing
-- them needs a Hyprland restart (not just a reload) to reach new sessions.

local theme = require("lua/theme")

-- Cursor follows the active variant (theme-mode.sh also runs
-- `hyprctl setcursor` on toggle so running sessions update live).
hl.env("XCURSOR_THEME", theme.cursor.theme)
hl.env("XCURSOR_SIZE", tostring(theme.cursor.size))
hl.env("HYPRCURSOR_SIZE", tostring(theme.cursor.size))

-- Wayland-first toolkits, X11 fallback
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Qt apps: Kvantum carries the Gruvbox Dragon widget style outside KDE.
-- (On the KDE session this is deliberately NOT set — see kde-gruvbox.nix —
-- because plasma pairs kvantum/kvantum-dark itself. Here theme-mode.sh
-- switches the Kvantum theme on toggle instead.)
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Session identity for portals and app launchers
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
