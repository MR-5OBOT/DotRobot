#!/usr/bin/env bash

set -euo pipefail

# rofi menu -> capture -> edit in satty -> copy to clipboard
args=()
case "$(printf 'area\nwindow\ndelay 5s' | rofi -dmenu -p screenshot -theme ~/.config/rofi/screenshot.rasi)" in
    area)       args=(-g "$(slurp -d)") ;;
    window)     args=(-g "$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')") ;;
    'delay 5s')  sleep 5 ;;  # ponytail: whole output; slurp/window won't survive a sleep
    *) exit 0 ;;             # dismissed
esac

grim -t ppm "${args[@]}" - | satty --filename - --fullscreen --copy-command wl-copy --early-exit
