-- Animations
--
-- Tuned for this workflow: fast hops between app-pinned workspaces (1-10),
-- precision dragging/resizing in Kdenlive/Krita/Blender, and a 60Hz laptop
-- panel next to a 240Hz monitor.
--
-- Springs carry the window motion (they settle instead of stopping dead),
-- beziers are kept for fades where an overshoot would read as flicker.
-- `speed` is a multiplier: higher = faster.

hl.config({
    animations = {
        enabled = true,
    }
})

-- Bezier curves
hl.curve("easeOutQuint",    { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("linear",          { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",    { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0}  } })
hl.curve("quick",           { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Spring curves (0.57+)
-- snap:   tiny overshoot, lands almost instantly — for opening/focus changes
-- swift:  critically damped, no bounce — for moves, where lag is felt
-- settle: soft landing — for closes, so nothing snaps out of existence
hl.curve("snap",   { type = "spring", mass = 0.6, stiffness = 480, damping = 30 })
hl.curve("swift",  { type = "spring", mass = 1.0, stiffness = 260, damping = 30 })
hl.curve("settle", { type = "spring", mass = 1.0, stiffness = 190, damping = 26 })

-- Animations
hl.animation({ leaf = "global",        enabled = true,  speed = 8,    bezier = "default"      })
hl.animation({ leaf = "border",        enabled = true,  speed = 5,    bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 6,    spring = "snap"         })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 5.5,  spring = "snap",   style = "popin 90%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 4.5,  spring = "settle", style = "popin 90%" })
hl.animation({ leaf = "windowsMove",   enabled = true,  speed = 9,    spring = "swift"        })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 5,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 4.5,  bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 5,    bezier = "quick"        })
hl.animation({ leaf = "layers",        enabled = true,  speed = 5,    spring = "swift"        })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 5,    spring = "swift",  style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 4.5,  spring = "settle", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 5,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 4.5,  bezier = "almostLinear" })

-- Workspaces: enabled again, but kept short. This is the biggest perceived
-- change for 1-10 app hopping; slidefade keeps the direction readable without
-- the full-screen slide that feels slow when switching every few seconds.
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 6,    spring = "swift",  style = "slidefade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 5,    spring = "swift",  style = "slidefade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 4.5,  spring = "settle", style = "slidefade" })

-- Scratchpad / special workspace drops in from the top.
hl.animation({ leaf = "specialWorkspace",    enabled = true, speed = 6,   spring = "snap",   style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 6,   spring = "snap",   style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4.5, spring = "settle", style = "slidevert" })

-- Leaves that most configs never touch. They are what makes the whole shell
-- feel choreographed instead of only the windows moving.
hl.animation({ leaf = "fadePopups",    enabled = true,  speed = 10,   bezier = "quick"        }) -- menus/tooltips: no lag
hl.animation({ leaf = "fadeSwitch",    enabled = true,  speed = 6,    bezier = "quick"        }) -- layout switches
hl.animation({ leaf = "fadeShadow",    enabled = true,  speed = 5,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeGlow",      enabled = true,  speed = 5,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeDim",       enabled = true,  speed = 5,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeDpms",      enabled = true,  speed = 3,    bezier = "almostLinear" }) -- screen off/on
hl.animation({ leaf = "monitorAdded",  enabled = true,  speed = 4,    bezier = "easeOutQuint" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick"        })
