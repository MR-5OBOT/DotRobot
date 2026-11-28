-- Smart focus for Super+H/J/K/L (bound in keymaps.lua). Hyprland's focus can't hop
-- between floating and tiled windows (kitty floats), so that hop happens here; tile to
-- tile stays Hyprland's. Nothing that way: switch between a tile and the float on it.
-- shortcut: nearest by centre (sideways counts double); use edge overlap if it misjumps.

-- In fullscreen, H/J/K/L still move to the other windows.
hl.config({ binds = { movefocus_cycles_fullscreen = true } })

local STEP = { left = { -1, 0 }, right = { 1, 0 }, up = { 0, -1 }, down = { 0, 1 } }

local function overlaps(a, b)
	return a.at.x < b.at.x + b.size.x
		and b.at.x < a.at.x + a.size.x
		and a.at.y < b.at.y + b.size.y
		and b.at.y < a.at.y + a.size.y
end

local function smart(dir)
	local cur = hl.get_active_window()
	if not (cur and cur.fullscreen == 0 and cur.workspace) then
		hl.dispatch(hl.dsp.focus({ direction = dir }))
		return
	end
	local dx, dy = STEP[dir][1], STEP[dir][2]
	local cx, cy = cur.at.x + cur.size.x / 2, cur.at.y + cur.size.y / 2
	local best, bestScore, stacked
	for _, w in ipairs(hl.get_workspace_windows(cur.workspace.id)) do
		if w.address ~= cur.address and w.mapped and not w.hidden then
			local ox, oy = w.at.x + w.size.x / 2 - cx, w.at.y + w.size.y / 2 - cy
			local ahead = ox * dx + oy * dy -- distance in the pressed direction
			local score = ahead + 2 * math.abs(ox * dy + oy * dx)
			if ahead > 0 and (not bestScore or score < bestScore) then
				best, bestScore = w, score
			end
			if
				w.floating ~= cur.floating
				and overlaps(w, cur)
				and (not stacked or w.focus_history_id < stacked.focus_history_id)
			then
				stacked = w
			end
		end
	end
	if best and (cur.floating or best.floating) then
		hl.dispatch(hl.dsp.focus({ window = best }))
		return
	end
	hl.dispatch(hl.dsp.focus({ direction = dir }))
	local now = hl.get_active_window()
	if stacked and now and now.address == cur.address then
		hl.dispatch(hl.dsp.focus({ window = stacked }))
	end
end

-- The bind action for one direction. pcall: if a Hyprland update breaks smart(), the
-- key still moves focus the plain way.
return function(dir)
	return function()
		if not pcall(smart, dir) then
			hl.dispatch(hl.dsp.focus({ direction = dir }))
		end
	end
end
