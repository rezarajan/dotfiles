-- Monitor layout.
--
-- Only the catch-all default lives here; real machines describe their
-- monitors in lua/local.lua (gitignored — see lua/local.lua.example).
-- List outputs with `hyprctl monitors all`.

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
