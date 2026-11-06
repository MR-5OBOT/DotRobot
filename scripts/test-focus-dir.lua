-- Self-check for the floating-window Super+HJKL picker in keymaps.lua: loads the real
-- file with a stub `hl` and presses the binds on made-up layouts. Run: lua scripts/test-focus-dir.lua
arg[1] = arg[1] or ((arg[0]:match("^(.*)/scripts/") or ".") .. "/dotfiles/.config/hypr/lua_configs/keymaps.lua")
local function anything()
	return setmetatable({}, { __index = function() return anything() end, __call = function() return anything() end })
end
local binds, last, active, wins, hyprGoes = {}, nil, nil, {}, nil
hl = setmetatable({
	bind = function(k, f) binds[k] = f end,
	dispatch = function(d)
		last = d
		if d.window then active = d.window end
		if d.direction and hyprGoes then active = hyprGoes end -- Hyprland's own movefocus
	end,
	get_active_window = function() return active end,
	get_workspace_windows = function() return wins end,
	dsp = setmetatable({ focus = function(spec) return spec end }, { __index = function() return anything() end }),
}, { __index = function() return anything() end })
package.preload["lua_configs.qs"] = function() return "qs" end
dofile(arg[1])

local function win(name, x, y, w, h, floating, history, fs)
	return { address = name, at = { x = x, y = y }, size = { x = w, y = h }, floating = floating,
		focus_history_id = history or 9, fullscreen = fs or 0, mapped = true, hidden = false, workspace = { id = 1 } }
end
-- from: focused window; goes: what Hyprland's movefocus would pick (nil = nothing that way)
local function press(key, from, goes)
	active, hyprGoes, last = from, goes, nil
	binds["SUPER + " .. key]()
	return last.window and last.window.address or ("dir:" .. last.direction)
end
local function check(label, got, want)
	assert(got == want, label .. ": got " .. tostring(got) .. ", want " .. want)
	print("ok  " .. label .. " -> " .. got)
end

-- two tiles side by side, a float in the middle on top of both
local L, R = win("tileL", 0, 0, 960, 1080, false, 1), win("tileR", 960, 0, 960, 1080, false, 2)
local F = win("float", 560, 240, 800, 600, true, 0)
wins = { L, R, F }
check("float  H", press("H", F), "tileL")
check("float  L", press("L", F), "tileR")
check("float  K, nothing above -> last tile under it", press("K", F), "tileL")
check("tileL  L -> float", press("L", L), "float")
check("tileR  H -> float", press("H", R), "float")
check("tileR  K, nothing above -> float on it", press("K", R), "float")
local F2 = win("float2", 1100, 300, 200, 400, true) -- centre x 1200, tileR centre 1440
wins = { L, R, F, F2 }
check("float  L, float2 nearer than tileR", press("L", F), "float2")

-- tile to tile stays Hyprland's movefocus
wins = { L, R }
check("tileL  L, no floats", press("L", L, R), "dir:right")
local small = win("smallfloat", 1700, 100, 100, 100, true) -- far corner, not on tileL
wins = { L, R, small }
check("tileL  L, tile nearer than float", press("L", L, R), "dir:right")

-- one tile filling the screen, a float centred on it (same centre: no direction)
local T = win("tile", 1285, 5, 1910, 1070, false, 1)
local C = win("float", 1930, 360, 620, 360, true, 0)
local other = win("laptop-window", 0, 0, 1280, 720, false) -- on the monitor to the left
wins = { T, C }
check("tile   L, nothing right -> float", press("L", T), "float")
check("float  L, nothing right -> tile", press("L", C), "tile")
check("float  J, nothing below -> tile", press("J", C), "tile")
check("tile   H, monitor on the left wins", press("H", T, other), "dir:left")
check("float  H, monitor on the left wins", press("H", C, other), "dir:left")

-- fullscreen and nothing focused keep Hyprland's movefocus
check("fullscreen float H", press("H", win("fs", 0, 0, 1920, 1080, true, 0, 1)), "dir:left")
check("nothing focused H", press("H", nil), "dir:left")
print("all passed")
