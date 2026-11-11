local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
local QS = require("lua_configs.qs")

-- cliphist, hypridle, hyprpolkitagent and battery-notify run as systemd user units
-- (scripts/enable-services.sh enables them): uwsm starts them with the session,
-- restarts them on a crash, and `journalctl --user -u <name>` shows their logs.

-- uwsm runs Hyprland inside a wayland-wm@ unit. Without it (the plain "Hyprland"
-- login entry, or `Hyprland` typed in a TTY) those units and ~/.config/uwsm/env
-- never load, so say so instead of failing quietly.
local function started_by_uwsm()
	local f = io.open("/proc/self/cgroup")
	if not f then
		return true -- can't tell: don't nag
	end
	local cgroup = f:read("a")
	f:close()
	return cgroup:find("wayland%-wm@") ~= nil
end

hl.on("hyprland.start", function()
	if not started_by_uwsm() then
		hl.notification.create({
			text = 'Started without uwsm: no clipboard history, idle lock, polkit or theme env. Log out and pick "Hyprland (uwsm-managed)".',
			timeout = 30000,
			icon = "warning",
		})
	end

	-- Daemons
	hl.exec_cmd("awww-daemon") -- paints the wallpaper; qs only picks it
	hl.exec_cmd(os.getenv("HOME") .. "/.config/quickshell/island/scripts/wallpaper.sh restore")
	-- one quickshell: the island bar (owns notifications) + launcher, clipboard, menus.
	hl.exec_cmd(QS)
end)
