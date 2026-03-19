#!/usr/bin/bash

# Variables
time=$(date +%Y-%m-%d_%H:%M:%S)
dir="$HOME/Pictures/Screenshots"
file="Screenshot_${time}.png"

# Ensure the screenshot directory exists
if [[ ! -d "$dir" ]]; then
	mkdir -p "$dir"
fi

# Notify user
notify_user() {
	if [[ -e "$dir/$file" ]]; then
		dunstify -u low --replace=699 -i /usr/share/icons/Papirus-Dark/symbolic/devices/camera-photo-symbolic.svg "Saved as ${dir}/${file}"
	else
		dunstify -u low --replace=699 -i /usr/share/icons/Papirus-Dark/symbolic/devices/camera-photo-symbolic.svg "Screenshot Deleted."
	fi
}

# Screenshot full screen
shotnow() {
	sleep 0.5 # Delay to let Rofi disappear
	cd "$dir" && grim "$file"
	cat "$file" | wl-copy
	notify_user
}

# Screenshot selected area
shotarea() {
	sleep 0.5 # Delay before capturing
	cd "$dir" && grim -g "$(slurp)" "$file"
	cat "$file" | wl-copy
	notify_user
}

# Screenshot selection menu
val=$(printf "1.Screen\n2.Area" | rofi -dmenu -l 2 -p 'Screenshot:')

case "$val" in
"1.Screen") shotnow ;;
"2.Area") shotarea ;;
*) echo "Cancelled." ;;
esac

exit 0
