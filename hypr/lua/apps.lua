-- Default applications and helper script paths.
-- Everything user-facing that a keybind launches is named here, once.

local M = {}

local home = os.getenv("HOME")
M.scripts = home .. "/.config/hypr/scripts"

-- Scripts are invoked through bash explicitly so a checkout without
-- executable bits (e.g. cloned on Windows) still works.
local function script(name, args)
    return "bash " .. M.scripts .. "/" .. name .. (args and (" " .. args) or "")
end
M.script = script

M.terminal = "ghostty"
M.browser = "chromium"
M.files = "dolphin"

M.menu = script("menu.sh", "drun")
M.runner = script("menu.sh", "run")
M.clipboard = script("clipboard.sh")
M.audio_out = script("audio.sh", "sink")
M.audio_in = script("audio.sh", "source")
M.screenshot_region = script("screenshot.sh", "region")
M.screenshot_screen = script("screenshot.sh", "screen")
M.screenshot_window = script("screenshot.sh", "window")
M.record_toggle = script("record.sh", "toggle")
M.theme_toggle = script("theme-mode.sh", "toggle")
M.lock = script("lock.sh")
M.logout_menu = script("power-menu.sh")
M.wallpaper_pick = script("wallpaper.sh", "pick")
M.wallpaper_next = script("wallpaper.sh", "next")
M.keybinds_help = script("keybinds-help.sh")

return M
