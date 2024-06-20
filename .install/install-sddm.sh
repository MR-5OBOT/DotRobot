#!/usr/bin/env bash

# MR5OBOT Header
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT Scripts for Managing Your Dotfiles and Configurations"
gum style --border normal --margin "1 2" --padding "1 2" --align center "SDDM setup"

# Set up a trap to run a specific command if the script fails
trap 'echo -e "\e[91mScript failed. Please check if SDDM is installed in your system.\e[0m"' ERR

# SDDM installation
sudo pacman -S --noconfirm sddm qt5-graphicaleffects && echo -e "\e[92mSDDM installed successfully\e[0m"

# Setup SDDM theme
SDDM_THEME=~/repos/DotRoboT/.extra/sddm/sddm-slice/
sudo cp -r $SDDM_THEME /usr/share/sddm/themes/ && gum style --border normal --margin "1 2" --padding "1 2" --align center "sddm theme installed successfully"
gum style --border normal --margin "1 2" --padding "1 2" --align center "now you need to add sddm-slice to themes in /usr/lib/sddm/sddm.conf.d/default.conf"



