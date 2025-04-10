#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Neovim setup" 

# Define colors
RED='\033[91m'
GREEN='\033[92m'
NONE='\033[0m'

# Check if the nvim repository exists
if [ ! -d ~/repos/nvim ]; then
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
    if ln -sf ~/repos/nvim ~/.config/nvim; then
        echo ":: Successfully linked MR5OBOT Neovim configuration"
    else
        echo -e "${RED}"
        figlet "Error: Neovim Configuration Installation Failed"
        echo -e "${NONE}"
        echo ":: The script failed to install the MR5OBOT Neovim configuration."
        exit 1
    fi

    # Check if lazy.nvim is installed
    if [ ! -d ~/.local/share/nvim/site/pack/packer/start/lazy.nvim ]; then
        echo -e "${GREEN}"
        figlet "Installing lazy.nvim"
        echo -e "${NONE}"
        # Install lazy.nvim
        git clone https://github.com/folke/lazy.nvim.git ~/.local/share/nvim/site/pack/packer/start/lazy.nvim
    fi

    # Ensure lazy.nvim is set up in the configuration
    CONFIG_LAZY_PATH="$HOME/repos/nvim/lua/config/lazy-cfg.lua"
    if ! grep -q "require('lazy').setup()" "$CONFIG_LAZY_PATH"; then
        echo ":: Adding lazy.nvim setup to the configuration..."
        # Add lazy.nvim setup to the config if it's not already there
        echo "require('lazy').setup()" >> "$CONFIG_LAZY_PATH"
    fi

    # Modify init.lua to load the lazy.nvim plugin manager if not present
    INIT_LUA_PATH="$HOME/repos/nvim/init.lua"
    if ! grep -q "require('lazy').setup()" "$INIT_LUA_PATH"; then
        echo ":: Adding lazy.nvim to init.lua..."
        echo "require('lazy').setup()" >> "$INIT_LUA_PATH"
    fi

    # Notify the user that the setup is complete
    notify-send ":: MR5OBOT Neovim configuration with lazy.nvim installed successfully"
else
    echo ":: Skipping MR5OBOT Neovim configuration installation."
fi

