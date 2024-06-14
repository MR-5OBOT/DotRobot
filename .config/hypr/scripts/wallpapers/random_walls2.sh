#!/usr/bin/env bash
# Script for Random Wallpaper

wallDIR="$HOME/Pictures/wallpapers/"

PICS=($(find ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPICS=${PICS[$RANDOM % ${#PICS[@]}]}

if [ ${#PICS[@]} -eq 0 ]; then
    echo "No image files found in ${wallDIR}. Exiting script."
    exit 1
fi

# Log the selected wallpaper for debugging
echo "Selected wallpaper: $RANDOMPICS" > "$HOME/wallpaper.log"

# Option 1: Directly set the wallpaper with swaybg
swaybg -i "$RANDOMPICS"

# Option 2: Use swaymsg to set wallpaper with scaling
# Replace 'OUTPUT' with your sway output name (e.g., 'HDMI-A-1')
# swaymsg output '*' bg "$RANDOMPICS" fill

