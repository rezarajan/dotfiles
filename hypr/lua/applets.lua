-- Applet-style dropdown windows.
--
-- KDE panel popups (volume, network, ...) dismiss themselves when you click
-- elsewhere. Hyprland has no built-in "close on focus loss", but the Lua
-- event API makes it a few lines: track applet windows as they open, and
-- when focus moves to anything that isn't one of them, close them all.
--
-- The matching window rules (position under the bar, slide-down animation)
-- live in lua/rules.lua.

local APPLET_CLASSES = {
    ["com.saivert.pwvucontrol"] = true,   -- audio mixer (preferred)
    ["org.pulseaudio.pavucontrol"] = true, -- audio mixer (fallback)
    ["pavucontrol"] = true,
    ["nm-connection-editor"] = true,      -- network settings
    ["blueman-manager"] = true,           -- bluetooth settings
    ["Blueman-manager"] = true,
    [".blueman-manager-wrapped"] = true,  -- nix wrapper name
}

local open_applets = 0

hl.on("window.open", function(w)
    if w and APPLET_CLASSES[w.class] then
        open_applets = open_applets + 1
    end
end)

hl.on("window.close", function(w)
    if w and APPLET_CLASSES[w.class] then
        open_applets = math.max(0, open_applets - 1)
    end
end)

hl.on("window.active", function(w)
    if open_applets == 0 then return end
    if w and APPLET_CLASSES[w.class] then return end
    -- focus went elsewhere (or to the desktop): dismiss every open applet
    for _, win in ipairs(hl.get_windows()) do
        if APPLET_CLASSES[win.class] then
            hl.dispatch(hl.dsp.window.close({ window = win }))
        end
    end
end)
