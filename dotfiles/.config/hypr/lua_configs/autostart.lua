-- Autostart

local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
	-- Critical Services
	hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	-- hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("/usr/lib/hyprpolkitagent")

	-- Daemons
	hl.exec_cmd("hyprlauncher -d")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("swaync")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd(SCRIPTS .. "/autostart/clipse.sh >> ~/.hyprland-autostart.log 2>&1")
	hl.exec_cmd("devify")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("hyprsunset")

	-- Launch Scripts
	hl.exec_cmd(SCRIPTS .. "/autostart/gtk.sh >> ~/.hyprland-autostart.log 2>&1")
	hl.exec_cmd(SCRIPTS .. "/autostart/toggle-waybar.sh >> ~/.hyprland-autostart.log 2>&1")
	hl.exec_cmd(SCRIPTS .. "/autostart/BAT-check.sh >> ~/.hyprland-autostart.log 2>&1")
end)
