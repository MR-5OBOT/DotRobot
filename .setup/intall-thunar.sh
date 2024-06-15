#!/usr/bin/env bash

# Create folders in user directory (eg. Documents,Downloads,etc.)
xdg-user-dirs-update
mkdir ~/Pictures/Screenshots/

# Thunar
sudo pacman -S --noconfirm thunar thunar-archive-plugin thunar-volman file-roller
