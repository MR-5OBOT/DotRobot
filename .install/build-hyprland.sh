#!/usr/bin/env bash

# Install dependencies
yay -S --needed --noconfirm base-devel cmake curl git glslang go hwids jq libavcodec libavformat libavutil libcairo libdeflate libdrm libegl libgbm gdk-pixbuf2.0 gobject-introspection gtk3 gulkan ini-config inputproto jbigkit jpeg lerc liftoff lzlib meson ninja openssl pambase pango pipewire-0.3 qt6-svg scdoc seatd startup-notification swresample systemd tomlplusplus udev vkfft vulkan-devel vulkan-headers vulkan-tools wayland-protocols xdg-desktop-portal xorg-xinput xxhash

# Clone the Hyprland repository
git clone https://github.com/hyprland/hyprland.git
cd hyprland

# Build and install Hyprland
meson build
ninja -C build
sudo ninja -C build install

# Copy necessary files
sudo cp ./example/hyprland.desktop /usr/share/wayland-sessions
