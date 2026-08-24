-- Monitor layout.
--
-- Three layers, each overriding the one before it:
--   1. the catch-all default below — whatever nothing else describes
--   2. lua/monitors-local.lua — the live layout, written by
--      `scripts/monitors.sh save` (the displays applet's Save, and the
--      exit of the wdisplays GUI, both call it). Gitignored.
--   3. lua/local.lua — hand-written per-machine overrides, loaded last
--      by hyprland.lua, so it still wins over a saved layout.
--
-- List outputs with `hyprctl monitors all`; Super+D opens the applet.

-- "preferred" takes the mode the EDID nominates, and on high-refresh
-- panels that is routinely the 60 Hz fallback — an AW3423DW came up at
-- 59.97 Hz on a 175 Hz screen and stayed there. "highrr" asks for the
-- fastest mode the output advertises instead.
hl.monitor({
    output   = "",
    mode     = "highrr",
    position = "auto",
    scale    = "auto",
})

-- The saved layout for this machine, when there is one. pcall because
-- most machines have no such file, and a missing module throws.
pcall(require, "lua/monitors-local")
