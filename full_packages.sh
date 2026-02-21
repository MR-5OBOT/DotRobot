#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# PACKAGE LISTS
# -----------------------------
repo_packages=(android-tools base blueman bluez bluez-utils brightnessctl btop discord docker dunst figlet file-roller firefox eza bat fd ripgrep fzf zoxide trash-cli firefoxpwa freerdp gimp git gparted gtk4 gum gvfs gvfs-mtp gvfs-smb hypridle hyprland hyprlock hyprpaper hyprpicker imv kitty lazygit luarocks mpv nano neovim network-manager-applet networkmanager npm nwg-look obs-studio pacman-contrib pamixer pavucontrol pipewire pipewire-alsa pipewire-jack pipewire-pulse polkit-gnome prettier python-black python-debugpy python-pip qalculate-gtk qt5-wayland qt5ct qt6ct rofi rust slurp speedtest-cli starship stylua swappy swaybg thunar thunar-archive-plugin thunar-media-tags-plugin thunar-shares-plugin thunar-volman tk tmux unzip vim waybar wireplumber wl-clip-persist wl-clipboard xdg-desktop-portal-gtk xdg-desktop-portal-hyprland yazi yt-dlp zathura zathura-pdf-mupdf zsh fastfetch less base-devel man-db man-pages ttf-iosevkaterm-nerd swaync acpi polkit-gnome)

aur_packages=(bottles clipse devify grimblast-git localsend-bin telegram-desktop-bin)

# -----------------------------
# FUNCTIONS
# -----------------------------
install_packages() {
    local manager=$1; shift
    local packages=("$@")
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    [ ${#to_install[@]} -eq 0 ] && echo "All $manager packages are already installed." && return

    echo "Installing $manager packages: ${to_install[*]}"

    if [ "$manager" = "AUR" ]; then
        for pkg in "${to_install[@]}"; do
            # Check if package exists in AUR
            if paru -Si "$pkg" &>/dev/null; then
                echo "Installing AUR package: $pkg"
                paru -S "$pkg"   # interactive, lets you choose
            else
                echo "⚠️  AUR package not found: $pkg, skipping."
            fi
        done
    else
        sudo pacman -S --noconfirm "${to_install[@]}"
    fi
}

# -----------------------------
# MAIN
# -----------------------------
echo "Starting installation..."
install_packages "official repo" "${repo_packages[@]}"
install_packages "AUR" "${aur_packages[@]}"
echo "All packages processed!"
