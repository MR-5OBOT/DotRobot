-- Autostart

local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
	-- Critical Services
	hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

	-- Daemons
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd(
		"sleep 1 && awww img " .. os.getenv("HOME") .. "/Pictures/wallpapers/MR5OBOT.jpg --transition-type none"
	)
	hl.exec_cmd("qs") -- bar + notifications + launcher
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd(SCRIPTS .. "/autostart/cliphist.sh")
	hl.exec_cmd("devify")
	-- hl.exec_cmd("hypridle")

	hl.exec_cmd(SCRIPTS .. "/autostart/BAT-check.sh")
end)
