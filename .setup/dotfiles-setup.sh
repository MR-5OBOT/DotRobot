#!/usr/bin/env bash

# Enable error checking
set -e

# Display hint message
echo "Hint: Please ensure the following steps before running this script:"
echo "  1. Create a directory named 'repos' in your home directory (~/repos)."
echo "  2. Move the 'DotRoboT' repository into the 'repos' directory."
echo ""

# Prompt user for confirmation
read -p "Have you completed the steps above? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Setup steps not completed. Exiting script."
    exit 1
fi

# Define variables
Dotfiles="$HOME/repos/DotRoboT"
configs="$Dotfiles/.config"

# Check if 'repos' directory exists
if [[ ! -d "$HOME/repos" ]]; then
    echo "Error: Directory 'repos' does not exist in your home directory."
    echo "Please create the 'repos' directory and move the 'DotRoboT' repository into it."
    exit 1
fi

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
echo "Linking .bashrc & .zshrc"
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

# Link .ssh configuration
echo "Linking .ssh configuration"
safe_link "$Dotfiles/.extra/.ssh" "$HOME/.ssh"

# Find the Firefox profile directory
echo "Finding Firefox profile directory"
PROFILE=$(find "$HOME/.mozilla/firefox/" -maxdepth 1 -type d -name "*default-release")

# Check if the profile directory was found
if [[ -z "$PROFILE" ]]; then
    echo "Error: Firefox profile directory not found."
else
    echo "Firefox profile directory found"
    for file in "$Dotfiles/Browser"/*; do
        safe_link "$file" "$PROFILE/$(basename "$file")"
    done
fi

# Check if post-checkout file exists in DotRoboT/.setting/
checkout="$Dotfiles/.setting/post-checkout"
if [[ -f "$checkout" ]]; then
    echo "Copying post-checkout file to destination"
    cp "$checkout" "../.git/hooks/"
else
    echo "Error: post-checkout file not found in DotRoboT/.setting/ directory."
    echo "Stopping the script due to missing post-checkout file."
    exit 1
fi

# Notify success message
if command -v notify-send &> /dev/null; then
    notify-send "Dotfiles linked successfully!"
    notify-send "Enjoy @MR5OBOT"
else
    echo "Dotfiles linked successfully!"
fi
