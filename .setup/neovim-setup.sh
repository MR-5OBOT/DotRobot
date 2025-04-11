#!/usr/bin/env bash
set -eo pipefail

# Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Neovim Setup"

# Colors
GREEN='\033[92m'
RED='\033[91m'
NONE='\033[0m'

# Paths
nvim_repo="$HOME/repos/nvim"
nvim_config="$HOME/.config/nvim"
lazy_path="$HOME/.local/share/nvim/lazy/lazy.nvim"

# Check if Neovim config repo exists
if [[ ! -d "$nvim_repo" ]]; then
	echo -e "${RED}Neovim config not found at $nvim_repo${NONE}"
	echo ":: Please clone it from MR5OBOT GitHub repo"
	exit 1
fi

# Ask for confirmation
echo -e "${GREEN}"
figlet "Neovim"
echo -e "${NONE}"
echo ":: Found Neovim config repo."

if ! gum confirm "Install MR5OBOT Neovim config?"; then
	echo ":: Skipped Neovim config setup."
	exit 0
fi

# Remove old config and symlink the new one
rm -rf "$nvim_config"
ln -sfn "$nvim_repo" "$nvim_config"
echo ":: Linked MR5OBOT config to ~/.config/nvim"

# Install lazy.nvim if not present
if [[ ! -d "$lazy_path" ]]; then
	echo ":: Installing lazy.nvim..."
	git clone --filter=blob:none https://github.com/folke/lazy.nvim.git "$lazy_path"
else
	echo ":: lazy.nvim is already installed."
fi

notify-send "Neovim Setup" "MR5OBOT Neovim config installed successfully 🎉"
echo -e "${GREEN}✔ Neovim setup complete.${NONE}"
