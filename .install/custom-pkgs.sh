packagesPacman=(
    "viewnior"
    "gimp"
    "rclone"
    "figlet" 
    "neovim"
    "kitty"
    "thunar"
    "fileroller"           
)

packagesYay=(
    "devify"
    "texlive-latex"
    "texlive-full"
)


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
