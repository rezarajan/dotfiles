-- Keybindings. Vim-flavoured and Super-based, carrying the KDE global
-- shortcuts' muscle memory (Meta+HJKL focus, Meta+Q close, Meta+F
-- fullscreen, Meta+V clipboard, Meta+Ctrl+L lock, ...).
-- `hyprctl binds` lists everything, Super+F1 shows a searchable cheatsheet.

local apps = require("lua/apps")

local mod = "SUPER"
local dirs = { h = "l", j = "d", k = "u", l = "r" }
local dir_names = { l = "left", d = "down", u = "up", r = "right" }

local function bind(keys, action, flags)
    hl.bind(keys, action, flags)
end

-- ------------------------------------------------------------ applications
bind(mod .. " + Return", hl.dsp.exec_cmd(apps.terminal), { description = "Terminal" })
bind(mod .. " + Space", hl.dsp.exec_cmd(apps.menu), { description = "App launcher" })
bind(mod .. " + B", hl.dsp.exec_cmd(apps.browser), { description = "Browser" })
bind(mod .. " + E", hl.dsp.exec_cmd(apps.files), { description = "File manager" })
bind(mod .. " + V", hl.dsp.exec_cmd(apps.clipboard), { description = "Clipboard history" })
-- Super+/ — "?" mnemonic; no function keys anywhere (40% keyboards)
bind(mod .. " + slash", hl.dsp.exec_cmd(apps.keybinds_help), { description = "Keybinding cheatsheet" })

-- ---------------------------------------------------------------- windows
bind(mod .. " + Q", hl.dsp.window.close(), { description = "Close window" })
bind(mod .. " + F", hl.dsp.window.fullscreen(), { description = "Fullscreen" })
bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Maximize" })
bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
bind(mod .. " + SHIFT + T", hl.dsp.window.pin(), { description = "Pin floating window" })
bind(mod .. " + C", hl.dsp.window.center(), { description = "Center floating window" })
bind(mod .. " + Tab", hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })

-- focus / move (vim keys)
for key, dir in pairs(dirs) do
    bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }),
        { description = "Focus " .. dir_names[dir] })
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }),
        { description = "Move window " .. dir_names[dir] })
end

-- resize: quick chords plus a hold-to-resize submap (Super+R, like Meta+T
-- entering KDE's tile editor)
local resize_step = {
    h = { x = -40, y = 0 }, l = { x = 40, y = 0 },
    k = { x = 0, y = -40 }, j = { x = 0, y = 40 },
}
for key, d in pairs(resize_step) do
    bind(mod .. " + ALT + " .. key,
        hl.dsp.window.resize({ x = d.x, y = d.y, relative = true }),
        { repeating = true, description = "Resize window" })
end

bind(mod .. " + R", hl.dsp.submap("resize"), { description = "Resize mode (hjkl, Esc exits)" })
hl.define_submap("resize", function()
    for key, d in pairs(resize_step) do
        hl.bind(key, hl.dsp.window.resize({ x = d.x, y = d.y, relative = true }),
            { repeating = true })
    end
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

-- groups (tabbed windows)
bind(mod .. " + G", hl.dsp.group.toggle(), { description = "Toggle window group" })
bind(mod .. " + bracketright", hl.dsp.group.next(), { description = "Next window in group" })
bind(mod .. " + bracketleft", hl.dsp.group.prev(), { description = "Previous window in group" })

-- mouse: drag to move / resize
bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ------------------------------------------------------------- workspaces
for i = 1, 10 do
    local key = i % 10
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }),
        { description = "Workspace " .. i })
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
        { description = "Move window to workspace " .. i })
end
bind(mod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })
bind(mod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }), { description = "Previous workspace" })
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- scratchpad
bind(mod .. " + S", hl.dsp.workspace.toggle_special("scratch"), { description = "Scratchpad" })
bind(mod .. " + CTRL + S", hl.dsp.window.move({ workspace = "special:scratch" }),
    { description = "Send to scratchpad" })

-- ------------------------------------------------------ desktop utilities
bind(mod .. " + CTRL + L", hl.dsp.exec_cmd(apps.lock), { description = "Lock screen" })
bind(mod .. " + BackSpace", hl.dsp.exec_cmd(apps.logout_menu), { description = "Session menu (lock/power)" })
bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd(apps.theme_toggle), { description = "Toggle dark/light" })
bind(mod .. " + W", hl.dsp.exec_cmd(apps.wallpaper_pick), { description = "Wallpaper carousel" })
bind(mod .. " + ALT + W", hl.dsp.exec_cmd(apps.wallpaper_next), { description = "Next wallpaper" })
bind(mod .. " + A", hl.dsp.exec_cmd(apps.audio_out), { description = "Switch audio output" })
bind(mod .. " + SHIFT + A", hl.dsp.exec_cmd(apps.audio_in), { description = "Switch microphone" })
bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"), { description = "Notification center" })

-- screenshots & recording
bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(apps.screenshot_region), { description = "Screenshot region" })
bind("Print", hl.dsp.exec_cmd(apps.screenshot_screen), { description = "Screenshot screen" })
bind(mod .. " + Print", hl.dsp.exec_cmd(apps.screenshot_window), { description = "Screenshot window" })
bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd(apps.record_toggle), { description = "Screen recording on/off" })

-- ------------------------------------------------- media & hardware keys
-- media keys go through the OSD script so every press shows the
-- volume/brightness slider popup
local osd = apps.script("osd.sh")
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(osd .. " volume-up"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(osd .. " volume-down"), { locked = true, repeating = true })
bind("XF86AudioMute", hl.dsp.exec_cmd(osd .. " volume-mute"), { locked = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd(osd .. " mic-mute"), { locked = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(osd .. " brightness-up"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osd .. " brightness-down"), { locked = true, repeating = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- --------------------------------------------------------- VM passthrough
-- Super+P hands every key to the focused window (nested VMs / remote
-- desktops); Super+Escape returns. The submap stays otherwise empty so all
-- non-bound keys pass straight through.
bind(mod .. " + P", hl.dsp.submap("passthrough"), { description = "Keyboard passthrough" })
hl.define_submap("passthrough", function()
    hl.bind(mod .. " + escape", hl.dsp.submap("reset"))
end)
