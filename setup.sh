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
echo "The following scripts will be run in sequence:"

echo
### Scripts to be Executed
# echo "- custom-fonts.sh"
echo "- dotfiles-setup.sh"
echo "- neovim-setup.sh"
echo "- thunar-setup.sh"
echo "- archives.sh"

gum confirm "Do you want to start the full dotfiles setup ? (y/n): "
if [ $? -ne 0 ]; then
    echo "Setup cancelled."
    exit 1
fi

echo
# Run the scripts in sequence
run_script "./.setup/bluebooth.sh"
run_script "./.setup/firefox.sh"
run_script "./.install/MR5OBOT-dotfiles-setup.sh"
run_script "./.install/neovim-setup.sh"
run_script "./.install/thunar-setup.sh"
run_script "./.install/archives.sh"

echo -e "All scripts completed successfully."
echo -e "Enjoy your system."
