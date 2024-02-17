#!/usr/bin/env bash

# Set up a trap to run a specific command if the script fails
trap 'echo -e "\e[91mScript failed. Please check if SDDM is installed in your system.\e[0m"' ERR

# SDDM installation
sudo pacman -S --noconfirm sddm && echo -e "\e[92mSDDM installed successfully\e[0m"

# Setup SDDM theme
SDDM_THEME=~/repos/DotRoboT/.extra/sddm/sddm-slice/
sudo cp -r $SDDM_THEME /usr/share/sddm/themes/ && echo -e "\e[92m--now you need to add sddm-slice to themes in /usr/lib/sddm/sddm.conf.d/default.conf--\e[0m"


