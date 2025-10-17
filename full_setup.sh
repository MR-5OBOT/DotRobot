#!/usr/bin/env bash

# Function to run a script and check its exit status
run_script() {
	local script=$1
	echo "Running $script..."
	bash "$script"
	if [ $? -ne 0 ]; then
		echo "Error: $script failed."
		exit 1
	fi
	echo "$script completed successfully."
}

## Full Setup for Hyprland Packages and Configurations
echo "Starting full setup for MR5OBOT dotfiles"

# Check if gum is installed
if ! command -v gum &>/dev/null; then
	echo "Error: gum is not installed. Install it with 'sudo pacman -S gum'"
	exit 1
fi

if ! gum confirm "Do you want to start the full system setup?"; then
	echo "Setup cancelled."
	exit 1
fi

echo
# Run the scripts in sequence
run_script "full_packages.sh"
run_script "auto-setups/dotfiles.sh"
run_script "auto-setups/zsh_setup.sh"
run_script "auto-setups/firefox.sh"
run_script "auto-setups/thunar-setup.sh"
run_script "auto-setups/pacman.sh"
run_script "auto-setups/neovim-setup.sh"

echo -e "All scripts completed successfully."
echo -e "Enjoy your system."

