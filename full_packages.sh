#!/usr/bin/env bash
set -e

# -----------------------------
# CONFIG: Lists of packages
# -----------------------------

# Official repo packages
repo_packages=(
android-tools
base
blueman
bluez
bluez-utils
brightnessctl
btop
discord
docker
dunst
figlet
file-roller
firefox
firefoxpwa
freerdp
fzf
gimp
git
gparted
gtk4
gum
gvfs
gvfs-mtp
gvfs-smb
hypridle
hyprland
hyprlock
hyprpaper
hyprpicker
imv
kitty
lazygit
luarocks
mpv
nano
neovim
network-manager-applet
networkmanager
npm
nwg-look
obs-studio
pacman-contrib
pamixer
pavucontrol
pipewire
pipewire-alsa
pipewire-jack
pipewire-pulse
polkit-gnome
prettier
python-black
python-debugpy
python-pip
qalculate-gtk
qt5-wayland
qt5ct
qt6ct
rofi
rust
slurp
speedtest-cli
starship
stylua
swappy
swaybg
thunar
thunar-archive-plugin
thunar-media-tags-plugin
thunar-shares-plugin
thunar-volman
tk
tmux
trash-cli
unzip
vim
waybar
wireplumber
wl-clip-persist
wl-clipboard
xdg-desktop-portal-gtk
xdg-desktop-portal-hyprland
xdg-desktop-portal-wlr
yazi
yt-dlp
zathura
zathura-pdf-mupdf
zoxide
zsh
)

# AUR packages
aur_packages=(
bottles
clipse-bin
devify
grimblast-git
localsend-bin
neofetch
paru
telegram-desktop-bin
)

# -----------------------------
# FUNCTIONS
# -----------------------------

install_repo_packages() {
    echo "Installing official repo packages with pacman..."
    for pkg in "${repo_packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            echo "Installing $pkg..."
            sudo pacman -S --noconfirm "$pkg"
        else
            echo "Skipping $pkg (already installed)"
        fi
    done
}

install_aur_packages() {
    echo "Installing AUR packages with paru..."
    for pkg in "${aur_packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            echo "Installing $pkg..."
            paru -S --noconfirm "$pkg"
        else
            echo "Skipping $pkg (already installed)"
        fi
    done
}

# -----------------------------
# MAIN
# -----------------------------

echo "Starting installation script..."
echo

install_repo_packages
install_aur_packages

echo
echo "All packages processed!"
