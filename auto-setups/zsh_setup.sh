#!/usr/bin/env bash

# Check if Zsh is installed
if ! command -v zsh &> /dev/null
then
    echo "Zsh could not be found. Installing Zsh..."
    sudo pacman -S --noconfirm zsh
fi

# Get the path of Zsh
zsh_path=$(which zsh)

# Change the default shell
echo "Changing the default shell to Zsh..."
sudo chsh -s "$zsh_path" "$USER"

echo "Default shell changed to Zsh successfully!"
echo "Please log out and log back in for the changes to take effect."

