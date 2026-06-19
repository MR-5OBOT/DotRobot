-- Autostart

local SCRIPTS = os.getenv("HOME") .. "/.config/hypr/scripts"

hl.on("hyprland.start", function()
	-- Critical Services
	hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	-- hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
	-- xdg-desktop-portal: no-op under uwsm, manual fallback under plain Hyprland
	hl.exec_cmd(SCRIPTS .. "/autostart/xdgportals.sh")

	-- Daemons
	hl.exec_cmd("hyprlauncher -d")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("swaync")
	hl.exec_cmd("nm-applet --indicator")
	hl.exec_cmd(SCRIPTS .. "/autostart/clipse.sh")
	hl.exec_cmd("devify")
	hl.exec_cmd("hypridle")

	hl.exec_cmd(SCRIPTS .. "/autostart/toggle-waybar.sh")
	hl.exec_cmd(SCRIPTS .. "/autostart/BAT-check.sh")
end)
