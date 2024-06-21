#!/usr/bin/env bash

gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Thunar setup" 

# Create folders in user directory (eg. Documents,Downloads,etc.)
xdg-user-dirs-update
mkdir ~/Pictures/Screenshots/

# Thunar
sudo pacman -S --noconfirm thunar thunar-archive-plugin thunar-volman file-roller
