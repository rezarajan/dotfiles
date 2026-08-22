-- Design tokens for the Hyprland stack.
--
-- Colors come from lua/palette.lua, which is GENERATED from
-- home-manager/desktop/kvantum/tools/palette.py (the single source of truth
-- for the whole desktop — KDE, GTK, Kvantum and this). Do not put hex values
-- anywhere else; change palette.py and run generate_all.py instead.
--
-- The active variant (dark/light) is a state file written by
-- scripts/theme-mode.sh; Hyprland re-reads it on every config reload, so a
-- mode toggle is just "write file + hyprctl reload".

local palette = require("lua/palette")

local M = {}

local function read_mode()
    local state = os.getenv("XDG_STATE_HOME")
        or (os.getenv("HOME") .. "/.local/state")
    local f = io.open(state .. "/gruvbox/mode", "r")
    if not f then return "dark" end
    local mode = f:read("*l")
    f:close()
    return mode == "light" and "light" or "dark"
end

M.mode = read_mode()
M.colors = palette[M.mode]

-- Geometry shared with the KDE side: window radius 12 (kwinrc Round-Corners),
-- 8px gap rhythm (kwin tiling padding), thin borders.
M.radius = 12
M.gaps_in = 8
M.gaps_out = 14
M.border = 2

-- Typography mirrors home-manager/desktop/fonts.nix (Inter UI @ 10.5,
-- JetBrains Mono fixed). Referenced by groupbar and misc font settings;
-- waybar/rofi/swaync carry their own generated copies of these names.
M.font = { ui = "Inter", mono = "JetBrains Mono" }

M.cursor = {
    theme = M.mode == "light" and "Gruvbox-Dragon-Cursors-Light"
        or "Gruvbox-Dragon-Cursors",
    size = 24,
}

-- "#rrggbb" -> hyprland color strings
function M.rgb(hex)
    return "rgb(" .. (hex:gsub("#", "")) .. ")"
end

function M.rgba(hex, alpha)
    return string.format("rgba(%s%02x)",
        (hex:gsub("#", "")), math.floor(alpha * 255 + 0.5))
end

return M
