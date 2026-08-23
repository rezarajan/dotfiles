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
    ["gruvbox-media"] = true,             -- media popup (media-panel.py)
    ["media-panel.py"] = true,            -- its fallback app id
    ["gruvbox-calendar"] = true,          -- calendar popup
    ["calendar-panel.py"] = true,
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

local function dismiss_applets(predicate)
    for _, win in ipairs(hl.get_windows()) do
        if APPLET_CLASSES[win.class] and (not predicate or predicate(win)) then
            hl.dispatch(hl.dsp.window.close({ window = win }))
        end
    end
end

hl.on("window.active", function(w)
    if open_applets == 0 then return end
    if w and APPLET_CLASSES[w.class] then return end
    -- focus went elsewhere: dismiss every open applet
    dismiss_applets()
end)

-- Clicking outside an applet also dismisses it — plasma behavior. Focus
-- alone can't catch clicks on the empty desktop or on layer surfaces, so
-- watch every unmodified left click (non_consuming: apps still get it)
-- and close applets whose box doesn't contain the cursor. The top strip
-- is exempt: bar icons toggle their own panels via scripts/panel.sh.
hl.bind("mouse:272", function()
    if open_applets == 0 then return end
    local cur = hl.get_cursor_pos()
    if not cur or cur.y <= 40 then return end
    dismiss_applets(function(win)
        return cur.x < win.at.x or cur.x > win.at.x + win.size.x
            or cur.y < win.at.y or cur.y > win.at.y + win.size.y
    end)
end, { non_consuming = true })
