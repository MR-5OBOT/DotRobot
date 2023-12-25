#!/bin/bash

# here's the most important packages i can't use my sys without it .


#### Check for yay ####
ISYAY=/sbin/yay
if [ -f "$ISYAY" ]; then 
    echo -e "yay was located, moving on.\n"
    yay -Suy
else 
    echo -e "yay was not located, please install yay. Exiting script.\n"
    exit 
fi

### Disable wifi powersave mode ###
read -n1 -rep 'Would you like to disable wifi powersave? (y,n)' WIFI
if [[ $WIFI == "Y" || $WIFI == "y" ]]; then
    LOC="/etc/NetworkManager/conf.d/wifi-powersave.conf"
    echo -e "The following has been added to $LOC.\n"
    echo -e "[connection]\nwifi.powersave = 2" | sudo tee -a $LOC
    echo -e "\n"
    echo -e "Restarting NetworkManager service...\n"
    sudo systemctl restart NetworkManager
    sleep 3
fi

### Install all of the above pacakges ####
read -n1 -rep 'Would you like to install packages from AUR ? (y,n)' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    yay -S --noconfirm gtklock \
    ttf-jetbrains-mono-nerd noto-fonts-emoji \
    python-requests grimblast slurp \
    nwg-look \
    # Clean out other portals
    echo -e "Cleaning out conflicting xdg portals...\n"
    yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk
fi

read -n1 -rep 'Would you like to install some extra packages from arch repository?  (y,n)' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    sudo pacman  -S --noconfirm hyprland kitty waybar \
    swaybg wofi swaync thunar thunar-archive-plugin \
    polkit-gnome starship \
    slurp pamixer brightnessctl gvfs \
    xdg-desktop-portal-hyprland \
fi

### Copy Config Files ###
read -n1 -rep 'Would you like to copy config files? (y,n)' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "Copying config files...\n"
    cp -R hypr ~/.config/
    cp -R kitty ~/.config/
    cp -R sc-im ~/.config/
    cp -R mpv ~/.config/
    cp -R zatura ~/.config/
    cp -R waybar ~/.config/
    cp -R rofi ~/.config/
    cp -R mako ~/.config/
    cp -R .bashrc ~/
    cp -R firefox/chrome ~/.mozilla/firefox/xbugllrt.default-release/
    cp firefox/user.js ~/.mozilla/firefox/xbugllrt.default-release/
    cp -R .themes/paradise ~/.themes/
    cp -R .icons/Bibata-Modern-Ice.tar.xz ~/.icons/

    
    # Set some files as exacutable 
    chmod +x ~/.config/hypr/autostart.sh
    chmod +x ~/.config/hypr/xdg-portal-hyprland
    chmod +x ~/.config/hypr/scripts/togglebar.sh
    chmod +x ~/.config/hypr/scripts/lockscreentime.sh
    chmod +x ~/.config/hypr/scripts/brightness.sh
    chmod +x ~/.config/hypr/scripts/volume.sh
fi

### Install teh starship shell ###
read -n1 -rep 'Would you like to install the starship shell? (y,n)' STAR
if [[ $STAR == "Y" || $STAR == "y" ]]; then
    # install the starship shell
    echo -e "Updating .bashrc...\n"
    echo -e '\neval "$(starship init bash)"' >> ~/.bashrc
    echo -e "copying starship config file to ~/.confg ...\n"
    cp starship.toml ~/.config/
fi

### Script is done ###
echo -e "Script had completed.\n"
echo -e "You can start Hyprland by typing Hyprland (note the capital H).\n"
read -n1 -rep 'Would you like to start Hyprland now? (y,n)' HYP
if [[ $HYP == "Y" || $HYP == "y" ]]; then
    exec Hyprland
else
    exit
fi
