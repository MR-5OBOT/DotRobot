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

echo
### Scripts to be Executed
# echo "- custom-fonts.sh"
echo "- yay.sh"
echo "- general-packages.sh"
echo "- hyprland-pkgs.sh"
echo "- custom-pkgs.sh"

gum confirm "Do you want to start the full installation? (y/n): "
if [ $? -ne 0 ]; then
    echo "Setup cancelled."
    exit 1
fi

echo
# Run the scripts in sequence
run_script "./.install/yay.sh"
run_script "./.install/packages/general-packages.sh"
run_script "./.install/packages/hyprland-pkgs.sh"
run_script "./.install/packages/custom-pkgs.sh"

echo -e "All scripts completed successfully."
echo -e "Enjoy your system."

