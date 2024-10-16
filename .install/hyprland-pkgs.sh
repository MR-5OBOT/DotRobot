#!/usr/bin/env bash

# Define packages for Pacman and Yay
packagesPacman=(
    "hyprland"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-wlr"
    "waybar"
    "slurp"
    "swappy"
    "dunst"
    "rofi"
    "starship"
    "pipewire"
    "blueman"
    "pavucontrol"
    "brightnessctl"
    "acpi"
    "wl-clipboard"
    "polkit-gnome"
    "networkmanager"
)

packagesYay=(
    # "gtklock"
    # "swww"
    "grimblast-git"
    # "cliphist"
    "nwg-look"
    "hyprlock"
    "hypridle"
    "hyprpicker"
)

# Function to install packages with Pacman, skipping already installed ones
_installPackagesPacman() {
    for package in "$@"; do
        echo "Installing $package with Pacman..."
        sudo pacman -S --needed --noconfirm $package
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install $package with Pacman."
            exit 1
        fi
    done
}

# Function to install packages with Yay, skipping already installed ones
_installPackagesYay() {
    for package in "$@"; do
        echo "Installing $package with Yay..."
        yay -S --needed --noconfirm $package
        if [ $? -ne 0 ]; then
            echo "Error: Failed to install $package with Yay."
            exit 1
        fi
    done
}

# Main installation process
echo "Starting installation process of hyprland packages..."
echo "Installing packages with Pacman..."
_installPackagesPacman "${packagesPacman[@]}"
echo "Installing packages with Yay..."
_installPackagesYay "${packagesYay[@]}"
echo "Installation process completed successfully."



