#!/usr/bin/env bash
# Pick a wallpaper via rofi and hand it to the already-running hyprpaper daemon.
set -euo pipefail

dir="$HOME/Pictures/wallpapers"

selected=$(find "$dir" -maxdepth 1 -type f -printf '%f\n' | sort |
    rofi -dmenu -p "Select wallpaper image" -lines 3 -columns 2 -width 50 -markup-rows)

[[ -n "$selected" ]] || exit 0

hyprctl hyprpaper reload ,"$dir/$selected"
