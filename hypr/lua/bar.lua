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
