#!/bin/bash


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

### Install pacakges ####
read -n1 -rep 'Would you like to install packages from AUR ? (y,n)' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    yay -S --noconfirm gtklock \
    noto-fonts-emoji \
    python-requests grimblast slurp \
    nwg-look devify\
    # Clean out other portals
    echo -e "Cleaning out conflicting xdg portals...\n"
    yay ln -s --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk
fi

read -n1 -rep 'Would you like to install some extra packages from arch repository?  (y,n)' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    sudo pacman  -S --noconfirm hyprland kitty waybar \
    swww rofi dunst thunar thunar-archive-plugin \
    polkit-gnome starship \
    slurp pamixer brightnessctl gvfs \
    xdg-desktop-portal-hyprland Viewnior\
fi

### Copy Config Files ###
read -n1 -rep 'Would you like to copy config files? (y,n)' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then

read -n1 -rep "did you creat MR-5OBOT dir ?" mr5obot_dir
if [[ $mr5obot_dir == "Y" || $mr5obot_dir == "y" ]]; then

    echo -e "Creating MR-5OBOT dir ...<>"
    mkdir MR-5OBOT/ || cp DotRoboT / ~/MR-5OBOT/
    
    echo -e "linking config files...\n"
    # .config files
    cp ln -s ~/MR-5OBOT/DotRoboT/.config/* ~/.config/

    echo -e "add walls dir to Pictures/"
    ln -s ~/MR-5OBOT/DotRoboT/wallpapers/ ~/Pictures/

    echo -e "add .bachrc file to home dir"
    cp ln -s home/.bashrc ~/

    eco -e "add firefox css theme <>"
    cp ln -s firefox-css/* ~/.mozilla/firefox/xbugllrt.default-release/

    echo -e "copy fonts & themes & icons to home dir <>"
    cp -R home/.themes/* ~/.themes/
    cp -R home/.fonts/* ~/.themes/
    cp -R .icons/* ~/.icons/

    # Set some files as exacutable 
    chmod u+x ~/.config/hypr/autostart.sh
    chmod u+x ~/.config/hypr/xdg-desktop-portal-hyprland
    chmod u+x ~/.config/hypr/gtk.sh
    chmod u+x ~/.config/scripts/*
fi

### Install teh starship shell ###
read -n1 -rep 'Would you like to install the starship shell? (y,n)' STAR
if [[ $STAR == "Y" || $STAR == "y" ]]; then
    # install the starship shell
    echo -e "Updating .bashrc...\n"
    echo -e '\neval "$(starship init bash)"' >> ~/.bashrc
    echo -e "link starship config file to ~/.confg ...\n"
    ln -s .config/starship.toml ~/.config/
f

### Script is done ###
echo -e "Script had completed.\n"
echo -e "You can start Hyprland by typing Hyprland (note the capital H).\n"
read -n1 -rep 'Would you like to start Hyprland now? (y,n)' HYP
if [[ $HYP == "Y" || $HYP == "y" ]]; then
    exec Hyprland
else
    exit
fi
