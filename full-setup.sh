#!/usr/bin/env bash

# Update the system
echo "Updating the system..."
sudo pacman -Syu --noconfirm
if [ $? -ne 0 ]; then
    echo "Error: System update failed."
    exit 1
fi

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
echo "Starting full setup for Hyprland packages and configurations..."
echo "The following scripts will be run in sequence:"

### Scripts to be Executed
echo "- custom-fonts.sh"
echo "- yay.sh"
echo "- general-packages.sh"
echo "- hyprland-pkgs.sh"
echo "- custom-pkgs.sh"
echo "- dotfiles-setup.sh"
echo "- neovim-setup.sh"
echo "- thunar-setup.sh"

# Run the scripts in sequence
run_script "./.install/custom-fonts.sh"
run_script "./.install/yay.sh"
run_script "./.install/general-packages.sh"
run_script "./.install/hyprland-pkgs.sh"
run_script "./.install/custom-pkgs.sh"
run_script "./.install/dotfiles-setup.sh"
run_script "./.install/neovim-setup.sh"
run_script "./.install/thunar-setup.sh"

echo -e "\033[92m All scripts completed successfully. \033[0m"
echo -e "\033[92m Enjoy your system. \033[0m"
