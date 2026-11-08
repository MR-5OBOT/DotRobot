-- Keymaps

local mainMod = "SUPER"
local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
local SCRIPT = SCRIPTS .. "/controls"
local RISHOT = os.getenv("HOME") .. "/.config/quickshell/rishot/bin/rishot"
local POWERPROFILE = os.getenv("HOME") .. "/.local/bin/powerprofile"
local QS = require("lua_configs.qs")
-- the island bar lives inside the main quickshell config (quickshell/island/)
local ISLAND = "qs ipc call island"

-- Window Management
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + C", hl.dsp.window.center())
hl.bind("ALT + Space", hl.dsp.window.float({ action = "toggle" }))
-- lockscreen: pauses whatever is playing, then hyprlock (fingerprint unlock)
local LOCK = os.getenv("HOME") .. "/.config/quickshell/island/scripts/lock.sh"
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(LOCK))

-- Application Launchers
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("uwsm app -- kitty"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(ISLAND .. ' home ""')) -- dashboard
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("blueman-manager")) -- bluetooth manager
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("kitty --class nmtui -e nmtui")) -- network manager (tui)
hl.bind(mainMod .. " + ALT + I", hl.dsp.exec_cmd("nm-connection-editor")) -- network connections editor (gui)
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("kitty --class nmtui -e nmtui connect")) -- direct wifi connection picker
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("pkill -x qs; " .. QS)) -- restart quickshell (island included)
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(ISLAND .. ' power ""'))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpicker toggle"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(ISLAND .. ' peek ""'))
hl.bind(mainMod .. " + equal", hl.dsp.exec_cmd("qs ipc call calc toggle"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("qs ipc call keymaps toggle")) -- keymap cheat sheet
-- keyd on/off (its panic combo only stops it); hyprpolkitagent asks for the password
hl.bind(mainMod .. " + ALT + K", hl.dsp.exec_cmd(
	"if systemctl is-active -q keyd; then systemctl stop keyd; else systemctl start keyd; fi; "
		.. 'notify-send -a keyd "keyd $(systemctl is-active keyd)"'
))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("qs ipc call calc toggle"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a -n"))

-- Screenshots
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(SCRIPT .. "/screenshot.sh"))
hl.bind("Print", hl.dsp.exec_cmd(RISHOT)) -- drag region or click a window
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(RISHOT .. " monitor")) -- whole output

-- Keyboard clicking (wl-kbptr), Vimium-style; colors in ~/.config/wl-kbptr/config
-- labels only on things that can be pressed; nothing pressable = nothing opens
-- type label = press it (tmux: switch tab/pane, open link); same key or Esc closes;
-- browsers too (accessibility on via uwsm/env + browser flags)
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(SCRIPT .. "/kbptr.py"))
-- grid over the whole screen, for spots SUPER+F can't label (tab group headers...):
-- type a tile's label, narrow with more letters, g = left click, h = right, Enter = move only
hl.bind(mainMod .. " + ALT + F", hl.dsp.exec_cmd("pkill -x wl-kbptr || wl-kbptr"))

-- Volume & Brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --inc"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --dec"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --toggle-mic"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --toggle"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(SCRIPT .. "/brightness.sh --dec"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(SCRIPT .. "/brightness.sh --inc"), { locked = true })

-- Power profile picker: tap to move down the list, Enter to apply
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd(POWERPROFILE .. " menu"))

-- Focus Navigation
hl.config({
	binds = {
		movefocus_cycles_fullscreen = 1,
	},
})
-- Hyprland's movefocus never crosses between floating and tiled windows (a float only
-- sees floats, a tile only tiles, then the next monitor) and no option changes that
-- (0.57). So find the nearest window that way ourselves and use it when the hop starts
-- or ends on a float; tile to tile stays Hyprland's. If nothing is that way (no window,
-- no monitor), switch between a tile and the float stacked on it (last focused first).
-- Check: lua scripts/test-focus-dir.lua
-- ponytail: nearest by centre, sideways counts double; use edge overlap if it misjumps.
local STEP = { left = { -1, 0 }, right = { 1, 0 }, up = { 0, -1 }, down = { 0, 1 } }
local function overlaps(a, b)
	return a.at.x < b.at.x + b.size.x and b.at.x < a.at.x + a.size.x
		and a.at.y < b.at.y + b.size.y and b.at.y < a.at.y + a.size.y
end
local function focusDir(dir)
	return function()
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
				if w.floating ~= cur.floating and overlaps(w, cur)
					and (not stacked or w.focus_history_id < stacked.focus_history_id) then
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
end
hl.bind(mainMod .. " + H", focusDir("left"))
hl.bind(mainMod .. " + L", focusDir("right"))
hl.bind(mainMod .. " + K", focusDir("up"))
hl.bind(mainMod .. " + J", focusDir("down"))

-- Moving Windows
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Resizing Windows
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

-- Workspaces
for i = 1, 9 do
	hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Monitors: O (the letter, not 0) jumps to the other screen, SHIFT + O carries the
-- active window there (onto whatever workspace that screen is showing). SHIFT + H/L
-- also cross over at the edge. Each switch flashes a Hyprland notification rather
-- than an island toast, which would pile up in the notification history.
local monToast
local function toast(text)
	if monToast and monToast:is_alive() then
		monToast:dismiss()
	end -- rapid presses replace, not stack
	monToast = hl.notification.create({ text = text, timeout = 1500, icon = "info" })
end
local function label(m)
	return m.name:match("^eDP") and "Laptop" or "Monitor"
end
hl.bind(mainMod .. " + O", function()
	local m = hl.get_monitor("+1")
	hl.dispatch(hl.dsp.focus({ monitor = m.name }))
	toast("Focus → " .. label(m))
end)
hl.bind(mainMod .. " + SHIFT + O", function()
	if not hl.get_active_window() then
		return
	end
	local m = hl.get_monitor("+1")
	hl.dispatch(hl.dsp.window.move({ workspace = m.active_workspace.id }))
	toast("Window → " .. label(m))
end)

-- Move/Resize mouse bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Thumb side buttons:
hl.bind("mouse:275", hl.dsp.exec_cmd(SCRIPT .. "/volume.sh --toggle-mic"))
hl.bind("mouse:276", hl.dsp.exec_cmd(RISHOT))
