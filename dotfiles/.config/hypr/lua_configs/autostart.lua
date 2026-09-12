-- Autostart

local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
	-- Critical Services
	hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

	-- Daemons
	hl.exec_cmd("awww-daemon")  -- paints the wallpaper; qs only picks it
	-- screen-time tracker. The env paths must match Caching.getStateDir/getRunDir("focustime"),
	-- which is where the wellbeing tab reads its database from.
	hl.exec_cmd("env QS_STATE_FOCUSTIME=" .. os.getenv("HOME") .. "/.local/state/dotrobot/focustime"
		.. " QS_RUN_FOCUSTIME=" .. (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/dotrobot/focustime"
		.. " python3 " .. os.getenv("HOME") .. "/.config/quickshell/widgets/guide/wellbeing/focus_daemon.py")
	hl.exec_cmd("qs") -- bar + notifications + launcher + tray/network + lock + wallpaper + low-batt notify
	hl.exec_cmd(SCRIPTS .. "/autostart/cliphist.sh")
	hl.exec_cmd("devify")
	hl.exec_cmd("hypridle")
end)
