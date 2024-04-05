#!/usr/bin/env bash

# Set directory to wallpaper folder
dir="$HOME/Pictures/wallpapers/"

# Create array of images in directory
images=( $(ls $dir) )

# Use Rofi to display image selection menu
selected=$(printf '%s\n' "${images[@]}" | rofi -dmenu -p "Select wallpaper image" -markup-rows)

# If user selects an image, run command with selected image as argument
if [[ -n $selected ]]; then
  # swww img "$dir/$selected" --transition-step 60 --transition-type random --transition-fps 60
  swaybg -i  "$dir/$selected"
fi
