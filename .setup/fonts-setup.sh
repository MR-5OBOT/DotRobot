#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Fonts setup" 

# Prompt user for confirmation
gum confirm "Have you want to custom fonts ? (y/n): "
if [[ $? -ne 0 ]]; then
    echo "Exiting script."
    exit 1
fi

# install fonts by pacman ttf-...
sudo pacman -S --needed --noconfirm ttf-iosevkaterm-nerd ttf-font-awesome ttf-daddytime-mono-nerd


# nonPacman fonts 
font_dirs=(~/repos/DotRoboT/.home/.fonts/*)

# Link all font directories in ~/.fonts/
for dir in ${font_dirs[@]}; do
    if [[ -d "$dir" ]]; then  # Check if it's a directory
        ln -s "$dir" ~/.fonts/
        if [[ $? -ne 0 ]]; then
            echo "Error linking $dir"
        fi
    fi
done

