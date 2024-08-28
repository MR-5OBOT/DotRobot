#!/usr/bin/env bash

# Error checking
set -e

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Firefox Setup"

# Paths
source="$HOME/repos/DotRoboT/Browser/firefox/"
destination="$HOME/.mozilla/firefox"
default_release_dir=$(find "$destination" -type d -name "*.default-release")

# List available themes
echo "Available Firefox themes:"
theme_folders=("$source"*/)
for i in "${!theme_folders[@]}"; do
    echo "$((i + 1)). $(basename "${theme_folders[$i]}")"
done

# Prompt for theme choice
read -p "Enter the number of the theme you want to apply: " theme_choice

# Validate input and get chosen theme
if (( theme_choice < 1 || theme_choice > ${#theme_folders[@]} )); then
    echo "Invalid choice. Exiting..."
    exit 1
fi
theme_folder="${theme_folders[$((theme_choice - 1))]}"

if [ -n "$default_release_dir" ]; then
    # Remove old links and create new ones
    rm -rf "$default_release_dir/chrome" "$default_release_dir/user.js"
    ln -sf "$theme_folder/chrome" "$default_release_dir"
    ln -sf "$theme_folder/user.js" "$default_release_dir"

    notify-send "$theme_folder linked enjoy now"
    echo "Symlinks created in $default_release_dir."
else
    echo "The default-release directory of Firefox was not found."
fi
