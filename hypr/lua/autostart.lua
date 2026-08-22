-- Session services. hyprland.start fires exactly once per session (config
-- reloads fire config.reloaded instead), so this is the exec-once analogue.

local apps = require("lua/apps")

-- Anything optional is guarded with `command -v` so a lean install (or the
-- test VM) starts cleanly without it.
local function try(cmd)
    local bin = cmd:match("^%S+")
    hl.exec_cmd(("command -v %s >/dev/null 2>&1 && %s"):format(bin, cmd))
end

hl.on("hyprland.start", function()
    -- portals & systemd need the session environment before anything launches
    hl.exec_cmd("dbus-update-activation-environment --systemd "
        .. "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORM "
        .. "XCURSOR_THEME XCURSOR_SIZE")

    -- apply the persisted dark/light mode: copies color tokens into place,
    -- broadcasts the portal color-scheme, sets the cursor theme
    hl.exec_cmd(apps.script("theme-mode.sh", "apply"))

    -- authentication agent (systemd unit ships with hyprpolkitagent)
    try("systemctl --user start hyprpolkitagent.service")

    -- first boot: seed the wallpaper from the repo if none is set yet
    hl.exec_cmd("[ -e \"$HOME/.config/hypr/wallpaper.jpg\" ] || "
        .. "cp \"$HOME/git/dotfiles/wallpapers/default.jpg\" "
        .. "\"$HOME/.config/hypr/wallpaper.jpg\" 2>/dev/null")

    -- shell: bar, notifications, wallpaper, idle management
    try("waybar")
    try("swaync")
    try("hyprpaper")
    try("hypridle")

    -- clipboard history for Super+V
    try("wl-paste --type text --watch cliphist store")
    try("wl-paste --type image --watch cliphist store")

    -- tray niceties (present on the full install, skipped on the VM)
    try("nm-applet")
    try("blueman-applet")
end)
