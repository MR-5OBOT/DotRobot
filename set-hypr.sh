#!/bin/bash


echo "hello, this is a simple script to install DotRoboT_hyprland cfgs
checking yay ...."
#### Check for yay ####
ISYAY=/sbin/yay
if [ -f "$ISYAY" ]; then 
    echo -e "yay was located, moving on.\n"
    echo -e "updaing ....."
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
    dunst udiskie nm-applet swayidle \
    cliphist zathura pavucontrol waybar 
fi

### Copy Config Files ###
read -n1 -rep 'Would you like to copy config files? (y,n)' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then

read -n1 -rep "did you creat MR-5OBOT dir ?" mr5obot_dir
if [[ $mr5obot_dir == "Y" || $mr5obot_dir == "y" ]]; then

    echo -e "Creating MR-5OBOT dir ...<>"
    mkdir -p MR-5OBOT ; mv DotRoboT/ ~/MR-5OBOT/
fi    
    echo -e "linking config files...\n"
    # .config files
    ln -s ~/MR-5OBOT/DotRoboT/.config/* ~/.config/

    echo -e "add walls dir to Pictures/"
    ln -s ~/MR-5OBOT/DotRoboT/wallpapers/ ~/Pictures/

    echo -e "add .bachrc file to home dir"
    ln -s ~/MR-5OBOT/DotRoboT/home/.bashrc ~/

    
    echo -e "copy fonts & themes & icons to home dir <>"
    cp -R ~/MR-5OBOT/DotRoboT/home/.themes/* ~/.themes/
    cp -R ~/MR-5OBOT/DotRoboT/home/.fonts/* ~/.themes/
    cp -R ~/MR-5OBOT/DotRoboT/home/.icons/* ~/.icons/

    # Set some files as exacutable 
    chmod u+x ~/.config/hypr/autostart.sh
    chmod u+x ~/.config/hypr/xdg-desktop-portal-hyprland
    chmod u+x ~/.config/scripts/*
fi

read -n1 -rep 'Would you want to add firefox css style to ur browser ? (y,n)' Firefox
if [[ Firefox == "Y" || Firefox == "y" ]]; then
  
#find the firefox profile dir and creat symbolic link for it
PROFILE=$(find ~/.mozilla/firefox/ -maxdepth 1 -type d -name "*default-release")

# Check if the profile directory was found
if [ -z "$PROFILE" ]; then
echo "Could not find the Firefox profile directory."
exit 1
fi
# Use the profile directory in your script
ln -s ~/MR-5OBOT/DotRoboT/firefox-css/* "$PROFILE"/
echo -e "firefox css theme is done. enjoy <>"

fi

### Install teh starship shell ###
read -n1 -rep 'Would you like to install the starship shell? (y,n)' STAR
if [[ $STAR == "Y" || $STAR == "y" ]]; then
    # install the starship shell
    echo -e "Updating .bashrc...\n"
    echo -e '\neval "$(starship init bash)"' >> ~/.bashrc
    echo -e "link starship config file to ~/.confg ...\n"
    ln -s ~/MR-5OBOT/DotRoboT/.config/starship.toml ~/.config/
fi

### Script is done ###
echo -e "Script had completed.\n"
echo -e "all done now you can do whatever you want! \n"

