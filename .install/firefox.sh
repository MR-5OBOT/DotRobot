#!/usr/bin/env bash

# errors checking
set -e

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Firefox Setup"

# Path to the original folder
original_folder="$HOME/repos/DotRoboT/Browser"

# Path to the .mozilla/firefox folder
firefox_folder="$HOME/.mozilla/firefox"

# Find the default-release directory
default_release_dir=$(find "$firefox_folder" -type d -name "*.default-release")

# Prompt the user to choose a theme
echo "Please choose a Firefox theme to apply:"
echo "1. Firefox-old"
echo "2. Firefox-new"
echo
read -p "Enter your choice type : (old or new): " theme_choice
echo

case $theme_choice in
    old)
        theme_folder="firefox-old"
        ;;
    new)
        theme_folder="firefox-new"
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

if [ -n "$default_release_dir" ]; then
    # Delete the "chrome" folder if it exists
    rm -rf "$default_release_dir/chrome"

    # Create a symlink to the chosen theme folder
    ln -sf "$original_folder/$theme_folder/chrome" "$default_release_dir"
    
    # Delete the "user.js" file if it exists
    rm -f "$default_release_dir/user.js"

    # Create a symlink to the "user.js" file
    ln -sf "$original_folder/$theme_folder/user.js" "$default_release_dir"

    notify-send "Symlinks created in $default_release_dir."
    echo "Symlinks created in $default_release_dir."
else
    echo "The default-release directory of Firefox was not found."
fi
