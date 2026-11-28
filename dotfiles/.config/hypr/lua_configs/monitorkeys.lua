-- Monitor keys (bound in keymaps.lua): focus or send a window to the other screen, and
-- laptop screen off/on. Each flashes a small Hyprland notice; island toasts would pile
-- up in the notification history.

local LAPTOP = "eDP-1"

local notice
local function toast(text)
	if notice and notice:is_alive() then
		notice:dismiss() -- fast presses replace the notice instead of stacking
	end
	notice = hl.notification.create({ text = text, timeout = 1500, icon = "info" })
end

local function label(m)
	return m.name:match("^eDP") and "Laptop" or "Monitor"
end

local M = {}

function M.focusNext()
	local m = hl.get_monitor("+1")
	hl.dispatch(hl.dsp.focus({ monitor = m.name }))
	toast("Focus → " .. label(m))
end

-- onto whatever workspace the other screen is showing
function M.sendWindowNext()
	if not hl.get_active_window() then
		return
	end
	local m = hl.get_monitor("+1")
	hl.dispatch(hl.dsp.window.move({ workspace = m.active_workspace.id }))
	toast("Window → " .. label(m))
end

-- Lets you keep the lid open (a closed lid weakens the Wi-Fi).
function M.toggleLaptop()
	local on = hl.get_monitor(LAPTOP) ~= nil -- nil while off
	if on and #hl.get_monitors() < 2 then
		return toast("No other screen") -- never turn off the only screen
	end
	hl.monitor({ output = LAPTOP, disabled = on })
	toast(on and "Laptop screen off" or "Laptop screen on")
end

-- Monitor lost while the laptop screen is off: turn the laptop screen back on.
hl.on("monitor.removed", function()
	hl.timer(function() -- runs after the removal, not in the middle of it
		for _, m in ipairs(hl.get_monitors()) do
			if m.name ~= "FALLBACK" then -- FALLBACK: Hyprland's stand-in when no screen is left
				return
			end
		end
		hl.monitor({ output = LAPTOP, disabled = false })
	end, { timeout = 500, type = "oneshot" })
end)

return M
