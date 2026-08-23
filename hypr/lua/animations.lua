-- Animations: quick and quiet, with the curves the polished community
-- configs converge on — an overshoot for window arrival, material-style
-- decel for menus/workspaces (easings.net lineage), gentle accel for
-- exits. Speeds stay near the KDE session's 0.25x factor. speed is in
-- deciseconds (2.0 = 200 ms).

hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("md3Decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3Accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("menuDecel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 320, dampening = 26 })

hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "md3Decel" })

-- windows arrive with a slight overshoot pop, leave quickly and quietly
hl.animation({ leaf = "windows", enabled = true, speed = 3, spring = "snappy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.2, bezier = "overshot", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.6, bezier = "md3Accel", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, spring = "snappy" })

hl.animation({ leaf = "fade", enabled = true, speed = 1.8, bezier = "md3Decel" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.6, bezier = "md3Decel" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.4, bezier = "md3Accel" })

hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "md3Decel" })

-- shell surfaces (bar, menus, applets) slide in with menu-style decel
hl.animation({ leaf = "layers", enabled = true, speed = 2.4, bezier = "menuDecel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.4, bezier = "md3Accel", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.8, bezier = "menuDecel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.4, bezier = "md3Accel" })

hl.animation({ leaf = "workspaces", enabled = true, speed = 2.6, bezier = "easeOutExpo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.4, bezier = "md3Decel", style = "slidevert" })
