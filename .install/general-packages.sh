#!/usr/bin/env bash

packagesPacman=(
    "bluez"
    "bluez-utils"
    "npm"
    "neovim"
    "wget"
    "unzip"
    "figlet"
    "gum"
    "pamixer"
    "btop"
    "nm-connection-editor"
    "network-manager-applet"
    "networkmanager"
    "xdg-user-dirs"
    "xdg-utils"
    "noto-fonts-cjk"
    "brightnessctl"
    "base-devel"
    "pacman-contrib"
    "mousepad"
    "python-pip"
    "tumbler"
    "man-pages"
    "gvfs"
    "zip"
    "fuse2"
    "gtk4"
    "libadwaita"
    "python-requests"
    "qt5ct"
    "qt6ct"
    "yad"
)

packagesYay=(
    "dialog"
    "mtools"
    "qt5-wayland"
    "qt6-wayland"
    "dosfstools"
    "avahi"
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
echo "Starting installation process of general packages..."
echo "Installing packages with Pacman..."
_installPackagesPacman "${packagesPacman[@]}"
echo "Installing packages with Yay..."
_installPackagesYay "${packagesYay[@]}"
echo "Installation process completed successfully."



