# ------------------------------------------------------
# Check if yay is installed
# ------------------------------------------------------
gum style --border normal --margin "1 2" --padding "1 2" --align center "MR5OBOT yay setup" 

if sudo pacman -Qs yay > /dev/null ; then
    echo ":: yay is already installed!"
else
    echo -e "${GREEN}"
    figlet "yay"
    echo -e "${NONE}"
    echo ":: yay is not installed. Starting the installation!"
    git clone https://aur.archlinux.org/yay-git.git ~/yay-git
    cd ~/yay-git
    makepkg -si
    cd $temp_path
    echo ":: yay has been installed successfully."
fi
echo
