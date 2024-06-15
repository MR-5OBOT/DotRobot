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

# Run the scripts in sequence
run_script "./.setup/general-packages.sh"
run_script "./.setup/hyprland-pkgs.sh"
run_script "./.setup/custom-pkgs.sh"
run_script "./.setup/dotfiles-setup.sh"

echo "All scripts completed successfully."
echo "Enjoy your system."

