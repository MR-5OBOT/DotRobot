# ------------------------------------------------------
# Check if yay is installed
# ------------------------------------------------------
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
