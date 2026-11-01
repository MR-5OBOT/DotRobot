-- Wallpaper self-heal for a Hyprland 0.57 bug that hits every layer-shell
-- wallpaper (awww, hyprpaper, mpvpaper alike): a layer that maps while its monitor
-- shows a fullscreen window skips its fade-in, and leaving fullscreen restores only
-- TOP layers, so a wallpaper surface made then (HDMI replug, daemon restart) stays
-- at alpha 0 for good. Note those outputs; once one is uncovered, respawn the daemons.
local RESPAWN = os.getenv("HOME") .. "/.config/quickshell/island/scripts/wallpaper.sh respawn"
local WALL_LAYERS = { ["awww-daemon"] = true, mpvpaper = true }
local stale = {}
local poll

local function covered(mon)
	local ws = mon.active_special_workspace or mon.active_workspace
	return ws ~= nil and ws.has_fullscreen and ws.fullscreen_mode == 2 -- FSMODE_FULLSCREEN: the test onMap uses
end

local function heal()
	if next(stale) == nil then
		return poll:set_enabled(false)
	end
	for _, mon in ipairs(hl.get_monitors()) do
		if stale[mon.name] and not covered(mon) then
			stale = {}
			poll:set_enabled(false)
			hl.exec_cmd(RESPAWN)
			return
		end
	end
end

hl.on("layer.opened", function(ls)
	if WALL_LAYERS[ls.namespace] and ls.monitor and covered(ls.monitor) then
		stale[ls.monitor.name] = true
		-- ponytail: a 1s poll, only while something is stale, catches every way out of
		-- fullscreen (unfullscreen, close, workspace/special switch) without wiring each event.
		poll = poll or hl.timer(heal, { timeout = 1000, type = "repeat" })
		poll:set_enabled(true)
	end
end)

hl.on("monitor.removed", function(mon)
	stale[mon.name] = nil
end)
