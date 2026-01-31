#!/usr/bin/env bash
set -e

# -----------------------------
# CONFIG: Lists of packages
# -----------------------------

# Official repo packages (deduplicated)
repo_packages=(
    android-tools base blueman bluez bluez-utils brightnessctl btop discord 
    docker dunst figlet file-roller firefox eza bat fd ripgrep fzf zoxide 
    trash-cli firefoxpwa freerdp gimp git gparted gtk4 gum gvfs gvfs-mtp 
    gvfs-smb hypridle hyprland hyprlock hyprpaper hyprpicker imv kitty 
    lazygit luarocks mpv nano neovim network-manager-applet networkmanager 
    npm nwg-look obs-studio pacman-contrib pamixer pavucontrol pipewire 
    pipewire-alsa pipewire-jack pipewire-pulse polkit-gnome prettier 
    python-black python-debugpy python-pip qalculate-gtk qt5-wayland 
    qt5ct qt6ct rofi rust slurp speedtest-cli starship stylua swappy 
    swaybg thunar thunar-archive-plugin thunar-media-tags-plugin 
    thunar-shares-plugin thunar-volman tk tmux unzip vim waybar 
    wireplumber wl-clip-persist wl-clipboard xdg-desktop-portal-gtk 
    xdg-desktop-portal-hyprland yazi yt-dlp 
    zathura zathura-pdf-mupdf zsh fastfetch
)

# AUR packages
aur_packages=(
    bottles clipse-bin devify grimblast-git localsend-bin paru 
    telegram-desktop-bin swayosd-git
)

# -----------------------------
# FUNCTIONS
# -----------------------------

install_repo_packages() {
    echo "Checking for missing official repo packages..."
    local to_install=()
    for pkg in "${repo_packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -ne 0 ]; then
        echo "Installing: ${to_install[*]}"
        sudo pacman -S --noconfirm "${to_install[@]}"
    else
        echo "All official packages are already installed."
    fi
}

install_aur_packages() {
    echo "Checking for missing AUR packages..."
    local to_install=()
    for pkg in "${aur_packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -ne 0 ]; then
        echo "Installing AUR: ${to_install[*]}"
        paru -S --noconfirm "${to_install[@]}"
    else
        echo "All AUR packages are already installed."
    fi
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
