#!/usr/bin/env bash

# Enable error checking
set -e

# Define variables
Dotfiles="$HOME/repos/DotRoboT"
configs="$Dotfiles/.config"

# Link .config files
echo "Linking all .config files"
ln -sf $configs/* ~/.config/

# Link zshrc & bashrc
echo "Linking zshrc & bashrc"
ln -sf "$Dotfiles/.bashrc" ~/
ln -sf "$Dotfiles/.zshrc" ~/

# Link .local/bin scripts
echo "Linking .local/bin scripts"
mkdir -p ~/.local/bin
ln -sf $Dotfiles/.local/bin/* ~/.local/bin/

# Link walls
echo "Linking walls"
ln -sf $Dotfiles/wallpapers/ ~/Pictures/

# Find the firefox profile directory
echo "Getting the Firefox Profile!"
PROFILE=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*default-release")

# Check if the profile directory was found
if [[ -z "$PROFILE" ]]; then
    echo "Profile variable is empty"
else
    echo "Firefox Profile is located"
    ln -sf $Dotfiles/Browser/* "$PROFILE"/
fi

# Success message after all commands have executed
notify-send "Dotfiles linked successfully!"
