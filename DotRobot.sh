#!/usr/bin/env bash

#  Function to run a script and check its exit status
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

gum confirm "Do you want to start the full dotfiles setup ? (y/n): "
if [ $? -ne 0 ]; then
    echo "Setup cancelled."
    exit 1
fi

echo
# Run the scripts in sequence
run_script "./.setup/.config.sh"
run_script "./.setup/zsh_setup.sh"
run_script "./.setup/firefox.sh"
run_script "./.setup/thunar-setup.sh"
run_script "./.setup/themes.sh"
run_script "./.setup/pacman.sh"

echo -e "All scripts completed successfully."
echo -e "Enjoy your system."

