#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Monitor backlights (if supported) using brightnessctl

# Show the quickshell OSD island (icon + progress bar); it reads the level
# itself. No-op if qs is down.
osd() { qs ipc call osd "$1" >/dev/null 2>&1; }

# Get brightness
get_backlight() {
	echo $(brightnessctl -m | cut -d, -f4)
}

# Get icons
get_icon() {
	current=$(get_backlight | sed 's/%//')
	if [ "$current" -le "20" ]; then
		icon=""
	elif [ "$current" -le "40" ]; then
		icon=""
	elif [ "$current" -le "60" ]; then
		icon=""
	elif [ "$current" -le "80" ]; then
		icon=""
	else
		icon=""
	fi
}

# Notify
notify_user() {
	osd brightness
}

# Change brightness
change_backlight() {
	brightnessctl set "$1" && get_icon && notify_user
}

# Execute accordingly
case "$1" in
"--get")
	get_backlight
	;;
"--inc")
	change_backlight "+10%"
	;;
"--dec")
	change_backlight "10%-"
	;;
*)
	get_backlight
	;;
esac
