-- Session services. hyprland.start fires exactly once per session (config
-- reloads fire config.reloaded instead), so this is the exec-once analogue.
--
-- All ordered startup lives in scripts/session-start.sh: theme tokens and
-- wallpaper must exist before the daemons that read them, which a pile of
-- parallel exec calls can't guarantee.

local apps = require("lua/apps")

hl.on("hyprland.start", function()
    -- portals & systemd services need the session environment first
    hl.exec_cmd("dbus-update-activation-environment --systemd "
        .. "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORM "
        .. "XCURSOR_THEME XCURSOR_SIZE")

    hl.exec_cmd(apps.script("session-start.sh"))
end)
