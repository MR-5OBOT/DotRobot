packagesPacman=(
    "bluez"
    "bluez-utils"
    "neovim"
    "wget"
    "unzip"
    "pamixer"
    "btop"
    "nm-connection-editor"  
    "network-manager-applet"
    "networkmanager"        
    "xdg-user-dirs"
    "xdg-utils"    
    "brightnessctl"
    "base-devel"
    # ---------------------- #
    "pacman-contrib"
    "freerdp" 
    "mousepad"
    "noto-fonts" 
    "python-pip" 
    "python-psutil" 
    "python-rich" 
    "python-click" 
    "tumbler" 
    "man-pages"
    "gvfs"
    "zip"
    "fuse2"
    "gtk4"
    "libadwaita"
    "python-requests"
    "python-pip"
    "qt5ct"
    "qt6ct"
    "yad"
);

packagesYay=(
    "dialog" 
    "mtools" 
    "qt5-wayland"
    "qt6-wayland"
    "dosfstools" 
    "avahi" 
);


# Function to install packages with Pacman, skipping already installed ones
_installPackagesPacman() {
    for package in "$@"; do
        sudo pacman -S --needed --noconfirm $package
    done
}

# Function to install packages with Yay, skipping already installed ones
_installPackagesYay() {
    for package in "$@"; do
        yay -S --needed --noconfirm $package
    done
}

# Main installation process
echo "Starting installation process..."
echo "Installing packages with Pacman..."
_installPackagesPacman "${packagesPacman[@]}"
echo "Installing packages with Yay..."
_installPackagesYay "${packagesYay[@]}"
echo "Installation process completed."
