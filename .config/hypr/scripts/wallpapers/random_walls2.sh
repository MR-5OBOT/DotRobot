#!/usr/bin/env bash
# Script for Random Wallpaper

wallDIR="$HOME/Pictures/wallpapers/"

PICS=($(find ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}

if [ ${#PICS[@]} -eq 0 ]; then
    echo "No image files found in ${wallDIR}. Exiting script."
    exit 1
fi

swaybg -i $RANDOMPICS

