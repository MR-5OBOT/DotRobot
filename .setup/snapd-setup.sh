#!/usr/bin/env bash

# error checking
set -e

gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT snapd setup" 
# ------------------------------------------------------
# Check if snapd is installed
# ------------------------------------------------------
if sudo pacman -Qs snapd > /dev/null ; then
    echo ":: snapd is already installed!"
else
    echo -e "${GREEN}"
    figlet "snapd"
    echo -e "${NONE}"
    echo ":: snapd is not installed. Starting the installation!"
    yay -S snapd
    # git clone https://aur.archlinux.org/snapd.git
    # cd snapd
    # makepkg -si
    echo ":: snapd has been installed successfully."
fi

gum style --border normal --margin "1 2" --padding "1 2" --align center "enable snapd services!"

echo "Enable the snapd service!"
systemctl enable --now snapd.apparmor && sudo systemctl enable --now snapd.socket

echo ""

echo "Enable classic snap support by creating a symbolic link"
sudo ln -s /var/lib/snapd/snap /snap

