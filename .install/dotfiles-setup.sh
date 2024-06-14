#!/usr/bin/env bash

# Enable error checking
set -e

# Define variables
Dotfiles="$HOME/repos/DotRoboT"
configs="$Dotfiles/.config"

# Ensure Dotfiles directory exists
if [[ ! -d "$Dotfiles" ]]; then
    echo "Error: Dotfiles directory $Dotfiles does not exist."
    exit 1
fi

# Function to safely link files and directories
safe_link() {
    src=$1
    dest=$2

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    if [[ -e "$dest" ]]; then
        if [[ -d "$dest" && -d "$src" ]]; then
            rm -rf "$dest"
        elif [[ -f "$dest" || -h "$dest" ]]; then
            rm -f "$dest"
        fi
    fi

    ln -sf "$src" "$dest"
}

# Link .config files and directories
echo "Linking all .config files and directories"
if [[ -d "$configs" ]]; then
    for item in "$configs"/*; do
        dest="$HOME/.config/$(basename "$item")"
        safe_link "$item" "$dest"
    done
else
    echo "Warning: .config directory $configs does not exist."
fi

# Link zshrc & bashrc
echo "Linking zshrc & bashrc"
safe_link "$Dotfiles/.bashrc" "$HOME/.bashrc"
safe_link "$Dotfiles/.zshrc" "$HOME/.zshrc"

# Link .local/bin scripts
echo "Linking .local/bin scripts"
mkdir -p "$HOME/.local/bin"
for script in "$Dotfiles/.local/bin"/*; do
    safe_link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# Link wallpapers
echo "Linking wallpapers"
safe_link "$Dotfiles/wallpapers" "$HOME/Pictures/wallpapers"

# Find the firefox profile directory
echo "Getting the Firefox Profile!"
PROFILE=$(find "$HOME/.mozilla/firefox/" -maxdepth 1 -type d -name "*default-release")

# Check if the profile directory was found
if [[ -z "$PROFILE" ]]; then
    echo "Error: Firefox profile directory not found."
else
    echo "Firefox Profile is located"
    for file in "$Dotfiles/Browser"/*; do
        safe_link "$file" "$PROFILE/$(basename "$file")"
    done
fi

# Success message after all commands have executed
if command -v notify-send &> /dev/null; then
    notify-send "Dotfiles linked successfully!"
else
    echo "Dotfiles linked successfully!"
fi

