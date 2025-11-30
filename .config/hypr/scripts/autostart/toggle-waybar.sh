#!/bin/bash

echo "toggle waybar"

killall -q waybar

while pgrep -x waybar >/dev/null; do sleep 1; done

# Log errors if waybar fails
waybar -c ~/.config/waybar/config_vertical -s ~/.config/waybar/style_vertical.css >~/.cache/waybar.log 2>&1 &
