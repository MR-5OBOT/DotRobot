local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"
local QS = require("lua_configs.qs")

hl.on("hyprland.start", function()
	-- Critical Services (Hyprland and uwsm already export the session env to systemd/dbus)
	hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

	-- Daemons
	hl.exec_cmd("awww-daemon") -- paints the wallpaper; qs only picks it
	hl.exec_cmd(os.getenv("HOME") .. "/.config/quickshell/island/scripts/wallpaper.sh restore")
	-- one quickshell: the island bar (owns notifications) + launcher, clipboard, menus.
	hl.exec_cmd(QS)
	hl.exec_cmd(SCRIPTS .. "/autostart/cliphist.sh")
	hl.exec_cmd(SCRIPTS .. "/autostart/battery-notify.sh") -- low-batt nag; the island draws it as a toast
	hl.exec_cmd("devify")
	hl.exec_cmd("hypridle")
end)
