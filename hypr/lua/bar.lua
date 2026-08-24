-- Bar synchronisation: waybar's workspace pills are custom modules (the
-- built-in hyprland module still speaks the pre-Lua dispatcher protocol,
-- so its clicks are no-ops on Hyprland >= 0.55). Hyprland's own events
-- poke waybar to refresh the pills the moment anything changes.

local function poke()
    hl.exec_cmd("pkill -SIGRTMIN+7 waybar")
end

for _, ev in ipairs({
    "workspace.active", "workspace.created", "workspace.removed",
    "window.open", "window.close", "window.move_to_workspace",
    "monitor.focused",
}) do
    hl.on(ev, poke)
end

-- The displays chip (RTMIN+6) has to react to outputs appearing and
-- disappearing, which is the whole point of it — plugging a projector in
-- should light the chip up without waiting out a poll interval.
local function poke_displays()
    hl.exec_cmd("pkill -SIGRTMIN+6 waybar")
end

for _, ev in ipairs({
    "monitor.added", "monitor.removed", "monitor.layout_changed",
}) do
    hl.on(ev, poke_displays)
end
