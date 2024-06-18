#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Scripts for Managing Your Dotfiles and Configurations"
# gum style --border normal --margin "1 2" --padding "1 2" --align center "Neovim Setup"

# Define colors
RED='\033[91m'
GREEN='\033[92m'
NONE='\033[0m'

# Check if the nvim repository exists
if [ ! -d ~/repos/MR-NV/nvim ]; then
    echo -e "${RED}"
    figlet "Neovim Not Found"
    echo -e "${NONE}"
    echo ":: The script has detected that the nvim repository does not exist."
    echo "Please clone the repository from MR5OBOT github repo"
    exit 1
fi

# Check if the user wants to install the MR5OBOT Neovim configuration
echo -e "${GREEN}"
figlet "  Neovim"
echo -e "${NONE}"
echo ":: The script has detected a nvim folder."
echo
if gum confirm "Do you want to install the MR5OBOT Neovim configuration?"; then
    echo ":: MR5OBOT Neovim configuration will be installed"
    neovim=1
    # Check if ~/.config/nvim exists
    if [ -d ~/.config/nvim ]; then
        # Remove the existing directory
        rm -rf ~/.config/nvim
    fi
    # Link the nvim repository to ~/.config
    if ln -sf ~/repos/MR-NV/nvim ~/.config/nvim; then
        notify-send ":: MR5OBOT Neovim configuration installed successfully"
    else
        echo -e "${RED}"
        figlet "Error: Neovim Configuration Installation Failed"
        echo -e "${NONE}"
        echo ":: The script failed to install the MR5OBOT Neovim configuration."
        exit 1
    fi
fi
