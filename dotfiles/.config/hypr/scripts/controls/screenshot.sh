#!/bin/bash
# Quick screenshot capture: grabs the active monitor directly and copies to clipboard

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/shot-$(date +'%Y%m%d-%H%M%S').png"

# Keep the previous shot's toast out of this one; 0.5s lets the notch slide it away.
[ "$(qs ipc call island dropToasts rishot 2>/dev/null)" = true ] && sleep 0.5

mon=$(hyprctl monitors -j 2>/dev/null | jq -r '(.[] | select(.focused) | .name) // empty' 2>/dev/null)

if [ -n "$mon" ]; then
    grim -o "$mon" "$file"
else
    grim "$file"
fi

if [ -s "$file" ]; then
    wl-copy --type image/png < "$file"
    notify-send -a rishot -i "$file" "Screenshot copied" "Fullscreen copied to clipboard" 2>/dev/null || true
fi
