#!/usr/bin/env bash
# __  ______   ____
# \ \/ /  _ \ / ___|
#  \  /| | | | |  _
#  /  \| |_| | |_| |
# /_/\_\____/ \____|
#

# Setup Timers
_sleep1="0.1"
_sleep2="0.5"

# Kill all possible running xdg-desktop-portals
killall -e xdg-desktop-portal-gnome
killall -e xdg-desktop-portal-kde
killall -e xdg-desktop-portal-lxqt
killall -e xdg-desktop-portal-wlr
killall -e xdg-desktop-portal-gtk

sleep 1
killall -e xdg-desktop-portal-hyprland
killall xdg-desktop-portal
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &

# # __  ______   ____
# # \ \/ /  _ \ / ___|
# #  \  /| | | | |  _
# #  /  \| |_| | |_| |
# # /_/\_\____/ \____|
#
# # Setup Timers
# _sleep1="0.1"
# _sleep2="0.5"
# _sleep3="2"
#
# # Kill any running xdg-desktop-portals
# killall -e xdg-desktop-portal-hyprland
# killall -e xdg-desktop-portal-gnome
# killall -e xdg-desktop-portal-kde
# killall -e xdg-desktop-portal-lxqt
# killall -e xdg-desktop-portal-wlr
# killall -e xdg-desktop-portal-gtk
# killall -e xdg-desktop-portal
# sleep 1
# # Set required env vars
# dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland
#
# # Stop all services
# systemctl --user stop pipewire
# systemctl --user stop wireplumber
# systemctl --user stop xdg-desktop-portal
# systemctl --user stop xdg-desktop-portal-gnome
# systemctl --user stop xdg-desktop-portal-kde
# systemctl --user stop xdg-desktop-portal-wlr
# systemctl --user stop xdg-desktop-portal-hyprland
# sleep $_sleep1
#
# # Start hyprland portal
# /usr/lib/xdg-desktop-portal-hyprland &
# sleep $_sleep1
#
# # Start gtk portal
# if command -v /usr/lib/xdg-desktop-portal-gtk >/dev/null; then
#     /usr/lib/xdg-desktop-portal-gtk &
#     sleep $_sleep1
# fi
#
# # Start required services
# systemctl --user start pipewire
# systemctl --user start wireplumber
# systemctl --user start xdg-desktop-portal
# systemctl --user start xdg-desktop-portal-hyprland
