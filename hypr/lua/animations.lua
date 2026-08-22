-- Animations: quick and quiet. The KDE side runs at AnimationDurationFactor
-- 0.25 — everything here aims for the same "instant but not abrupt" feel.
-- speed is in deciseconds (2.0 = 200 ms).

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 320, dampening = 26 })

hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "easeOutQuint" })

hl.animation({ leaf = "windows", enabled = true, speed = 3, spring = "snappy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, spring = "snappy", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.4, bezier = "linear", style = "popin 90%" })

hl.animation({ leaf = "fade", enabled = true, speed = 1.6, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.4, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "almostLinear" })

hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "easeOutQuint" })

hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "easeOutQuint", style = "fade" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 2.2, bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, bezier = "easeOutQuint", style = "slidevert" })
