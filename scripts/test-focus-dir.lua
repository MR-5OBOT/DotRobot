-- Self-check for the floating-window Super+HJKL picker in keymaps.lua: loads the real
-- file with a stub `hl` and presses the binds on made-up layouts. Run: lua scripts/test-focus-dir.lua
arg[1] = arg[1] or ((arg[0]:match("^(.*)/scripts/") or ".") .. "/dotfiles/.config/hypr/lua_configs/keymaps.lua")
local function anything()
	return setmetatable({}, { __index = function() return anything() end, __call = function() return anything() end })
end
local binds, last, active, wins = {}, nil, nil, {}
hl = setmetatable({
	bind = function(k, f) binds[k] = f end,
	dispatch = function(d) last = d end,
	get_active_window = function() return active end,
	get_workspace_windows = function() return wins end,
	dsp = setmetatable({ focus = function(spec) return spec end }, { __index = function() return anything() end }),
}, { __index = function() return anything() end })
package.preload["lua_configs.qs"] = function() return "qs" end
dofile(arg[1])

local function win(name, x, y, w, h, floating, fs)
	return { address = name, at = { x = x, y = y }, size = { x = w, y = h }, floating = floating,
		fullscreen = fs or 0, mapped = true, hidden = false, workspace = { id = 1 } }
end
local function press(key)
	last = nil
	binds["SUPER + " .. key]()
	return last.window and last.window.address or ("dir:" .. last.direction)
end
local function check(label, got, want)
	assert(got == want, label .. ": got " .. tostring(got) .. ", want " .. want)
	print("ok  " .. label .. " -> " .. got)
end

-- two tiles side by side, a float in the middle on top
local L, R = win("tileL", 0, 0, 960, 1080, false), win("tileR", 960, 0, 960, 1080, false)
local F = win("float", 560, 240, 800, 600, true)
wins, active = { L, R, F }, F
check("float  Super+H", press("H"), "tileL")
check("float  Super+L", press("L"), "tileR")
check("float  Super+K (nothing above)", press("K"), "dir:up")
check("float  Super+J (nothing below)", press("J"), "dir:down")

-- a second float just right of the first beats the far tile
local F2 = win("float2", 1100, 300, 200, 400, true) -- centre x 1200, tileR centre 1440
wins = { L, R, F, F2 }
check("float  Super+L, float2 nearer", press("L"), "float2")

-- tiled windows keep Hyprland's own movefocus
active = L
check("tiled  Super+L", press("L"), "dir:right")

-- fullscreen float keeps Hyprland's own movefocus
active = win("fsfloat", 0, 0, 1920, 1080, true, 1)
wins = { L, R, active }
check("fullscreen float Super+H", press("H"), "dir:left")

-- no window focused
active = nil
check("nothing focused Super+H", press("H"), "dir:left")
print("all passed")
