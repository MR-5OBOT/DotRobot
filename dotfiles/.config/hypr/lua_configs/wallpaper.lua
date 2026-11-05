-- Wallpaper self-heal for a Hyprland 0.57 bug that hits every layer-shell
-- wallpaper: a layer that maps while its monitor shows a fullscreen window skips
-- its fade-in, and leaving fullscreen restores only TOP layers, so a wallpaper
-- surface made then (HDMI replug, daemon restart) stays at alpha 0 for good. awww
-- never remaps a surface, so "opened under fullscreen" means exactly "stuck".
-- Track those surfaces; once their screen is uncovered, `wallpaper.sh heal`
-- respawns awww (only if Hyprland really left one at alpha 0, so a fixed Hyprland
-- costs nothing).
local HEAL = os.getenv("HOME") .. "/.config/quickshell/island/scripts/wallpaper.sh heal"
-- layer namespace -> what `wallpaper.sh heal` restarts
local WALL_LAYERS = { ["awww-daemon"] = "stills" }
-- Kept in this Hyprland instance's runtime dir: `hyprctl reload` rebuilds this Lua
-- state but must not forget a stuck surface, and a new session starts clean.
local RUN, SIG = os.getenv("XDG_RUNTIME_DIR"), os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
local FILE = RUN and SIG and (RUN .. "/hypr/" .. SIG .. "/wallpaper-stale")
local stale = {} -- layer address -> { mon = output name, ns = layer namespace }
local poll

local function covered(mon)
	local ws = mon.active_special_workspace or mon.active_workspace
	return ws ~= nil and ws.has_fullscreen and ws.fullscreen_mode == 2 -- FSMODE_FULLSCREEN: the test onMap uses
end

local function save()
	local f = FILE and io.open(FILE, "w")
	if not f then
		return
	end
	for addr, s in pairs(stale) do
		f:write(addr, "\t", s.mon, "\t", s.ns, "\n")
	end
	f:close()
end

local function heal()
	local owners, changed = {}, false
	for addr, s in pairs(stale) do
		local mon = hl.get_monitor(s.mon)
		if not mon or not covered(mon) then -- an output that is gone takes its surface with it
			stale[addr], changed = nil, true
			if mon and WALL_LAYERS[s.ns] then
				owners[WALL_LAYERS[s.ns]] = true
			end
		end
	end
	if next(stale) == nil then
		poll:set_enabled(false)
	end
	if not changed then
		return
	end
	save()
	local args = ""
	for owner in pairs(owners) do
		args = args .. " " .. owner
	end
	if args ~= "" then
		hl.exec_cmd(HEAL .. args)
	end
end

local function arm()
	-- ponytail: a 250ms poll, only while a surface is stuck, catches every way out of
	-- fullscreen (unfullscreen, close, workspace/special switch) without wiring each event.
	poll = poll or hl.timer(heal, { timeout = 250, type = "repeat" })
	poll:set_enabled(true)
end

hl.on("layer.opened", function(ls)
	if WALL_LAYERS[ls.namespace] and ls.monitor and covered(ls.monitor) then
		stale[ls.address] = { mon = ls.monitor.name, ns = ls.namespace }
		save()
		arm()
	end
end)

hl.on("layer.closed", function(ls)
	if stale[ls.address] then
		stale[ls.address] = nil
		save()
	end
end)

local f = FILE and io.open(FILE)
if f then
	for line in f:lines() do
		local addr, mon, ns = line:match("^(%S+)\t(%S+)\t(%S+)$")
		if addr then
			stale[addr] = { mon = mon, ns = ns }
		end
	end
	f:close()
	if next(stale) then
		arm()
	end
end
