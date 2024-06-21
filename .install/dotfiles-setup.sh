#!/usr/bin/env bash

# Enable error checking
set -e

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT dotfiles setup" 

# Prompt user for confirmation
gum confirm "Have you want to setup dotfiles ? (y/n): "
if [[ $? -ne 0 ]]; then
    echo "Exiting script."
    exit 1
fi

# Display hint message
echo "Hint: Please ensure the following steps before running this script:"
echo "  1. Create a directory named 'repos' in your home directory (~/repos)."
echo "  2. Move the 'DotRoboT' repository into the 'repos' directory."
echo ""

# Prompt user for confirmation
gum confirm "Have you completed the steps above? (y/n): "
if [[ $? -ne 0 ]]; then
    echo "Setup steps not completed. Exiting script."
    exit 1
fi

# Define variables
Dotfiles="$HOME/repos/DotRoboT"
configs="$Dotfiles/.config"

# Check if 'DotRoboT' directory exists
if [[ ! -d "$Dotfiles" ]]; then
    echo "Error: DotRoboT directory $Dotfiles not found."
    echo "Please move the 'DotRoboT' repository into the 'repos' directory."
    exit 1
fi

# Check if '.config' directory exists in DotRoboT
if [[ ! -d "$configs" ]]; then
    echo "Error: .config directory $configs not found in DotRoboT repository."
    echo "The DotRoboT repository may be damaged. Please check and fix the repository."
    exit 1
fi

# Function to safely link files and directories
safe_link() {
    local src=$1
    local dest=$2

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # Remove existing destination if it exists
    if [[ -e "$dest" ]]; then
        if [[ -d "$dest" && -d "$src" ]]; then
            rm -rf "$dest"
        elif [[ -f "$dest" || -h "$dest" ]]; then
            rm -f "$dest"
        fi
    fi
    # Create symbolic link
    ln -sf "$src" "$dest"
}

# Link .config files and directories if .config exists
echo "Linking .config files and directories"
if [[ -d "$configs" ]]; then
    for item in "$configs"/*; do
        dest="$HOME/.config/$(basename "$item")"
        safe_link "$item" "$dest"
    done
else
    echo "Error: .config directory $configs does not exist."
    echo "Stopping the script due to missing .config directory."
    exit 1
fi

# Link .bashrc and .zshrc
echo "Linking Sell zsh"
# safe_link "$Dotfiles/.bashrc" "$HOME/.bashrc"
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

# Link .ssh configuration
echo "Linking .ssh configuration"
safe_link "$Dotfiles/.extra/.ssh" "$HOME/.ssh"

echo "pls link post-checkout file i can't do it"
# Notify success message
if command -v notify-send &> /dev/null; then
    notify-send "Dotfiles linked successfully!"
    notify-send "Enjoy @MR5OBOT"
else
    echo "Dotfiles linked successfully!"
fi
