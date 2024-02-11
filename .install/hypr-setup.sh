#!/usr/bin/env bash

# simple script to install all hyprland packages


### My custom apps ###
read -n1 -rep "would you like to install custom applications for hyrpland ? (y,n)" CUSTOM
if [[ $CUSTOM == "Y" || $CUSTOM == "y" ]]; then

  sudo pacman -S kitty firefox neofetch neovim dunst rofi waybar \
  pavucontrol pamixer bluez-utils blueman swww brightnessctl \
  thunar thunar-media-tags-plugins zathura bluez \
  thunar-volman thunar-archive-plugin Viewnior xed mpv
  
fi

# hyprland required community packages 
read -n1 -rep "would you like to install required packages for hyprland ? (y,n)" CUSTOM
if [[ $CUSTOM == "Y" || $CUSTOM == "y" ]]; then

    sudo pacman -S hyprland pipewire pipewire-alsa pipewire-audio pipewire-jack swayidle \
    pipewire-pulse gst-plugin-pipewire wireplumber polkit-gnome  imagemagick qt5-imageformats ffmpegthumbs \
    starship qt5-wayland networkmanager network-manager-applet kvantum cliphist pacman-contrib jq \
    qt5-quickcontrols qt5-quickcontrols2 qt5-graphicaleffects qt6-wayland xdg-desktop-portal-hyprland acpi 
    
fi

# Clean out other portals
    echo -e "Cleaning out conflicting xdg portals...\n"
    yay ln -s --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk

# yay AUR packages
read -n1 -rep "would you like to install required packages from AUR ? (y,n)" AUR
if [[ $AUR == "Y" || $AUR == "y" ]]; then

    yay -S grimblast-git hyprpicker-git slurp swappy nwg-look sddm-git devify 

fi


#install fonts
if [ $? -eq 0 ]; then
    ~/MR-5OBOT/DotRoboT/.install/nerdfonts-installer.sh
    fi
