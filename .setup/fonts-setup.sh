#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Fonts setup" 

# Prompt user for confirmation
gum confirm "Have you want to custom fonts ? (y/n): "
if [[ $? -ne 0 ]]; then
    echo "Exiting script."
    exit 1
fi

# Install fonts by pacman ttf-...
sudo pacman -S --needed --noconfirm ttf-iosevkaterm-nerd ttf-font-awesome ttf-daddytime-mono-nerd

# Non-Pacman fonts 
font_dirs=("$HOME/repos/DotRobot/.extra/.home/.fonts/")

echo "Linking fonts to .fonts/ directory"

# Loop through the font directories
for dir in "$font_dirs"/*; do
    if [[ -d "$dir" ]]; then
        # Check if it's a directory and link it
        ln -sf "$dir" ~/.fonts/
        if [[ $? -eq 0 ]]; then
            echo "Successfully linked: $dir"
        else
            echo "Error linking $dir"
        fi
    else
        echo "Not a directory: $dir"
    fi
done

echo "Font linking completed."
