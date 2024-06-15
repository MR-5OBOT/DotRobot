#!/usr/bin/env bash

# Define packages for Pacman and Yay
packagesPacman=(
    "hyprland"
    "xdg-desktop-portal-hyprland"
    "waybar"
    "slurp"
    "gtklock"
    "swappy"
    "dunst"
    "kitty"
    "rofi"
    "starship"
    "mpv"
    "thunar"
    "thunar-archive-plugin"
    "pipewire"
    "eza"
    "blueman"
    "pavucontrol"
    "brightnessctl"
    "acpi"
    "xdg-desktop-portal"
    "wl-clipboard"
    "polkit-gnome"
)

packagesYay=(
    "swww"
    "grimblast-git"
    "cliphist"
    "nwg-look"
    "emote"
    "hyprlock"
    "hypridle"
)

# Function to install packages with Pacman, skipping already installed ones
_installPackagesPacman() {
    for package in "$@"; do
        sudo pacman -S --needed --noconfirm $package
    done
}

# Function to install packages with Yay, skipping already installed ones
_installPackagesYay() {
    for package in "$@"; do
        yay -S --needed --noconfirm $package
    done
}

# Main installation process
echo "Starting installation process..."
echo "Installing packages with Pacman..."
_installPackagesPacman "${packagesPacman[@]}"
echo "Installing packages with Yay..."
_installPackagesYay "${packagesYay[@]}"
echo "Installation process completed."
