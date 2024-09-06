#!/usr/bin/env bash
# __  ______   ____ 
# \ \/ /  _ \ / ___|
#  \  /| | | | |  _ 
#  /  \| |_| | |_| |
# /_/\_\____/ \____|
#                   

sleep 1

# Kill all possible running xdg-desktop-portals
echo "Killing running xdg-desktop-portals..."
killall -e xdg-desktop-portal-hyprland
killall -e xdg-desktop-portal-gnome
killall -e xdg-desktop-portal-kde
killall -e xdg-desktop-portal-lxqt
killall -e xdg-desktop-portal-wlr
killall -e xdg-desktop-portal-gtk
killall -e xdg-desktop-portal

sleep 1

# Start xdg-desktop-portal-hyprland
echo "Starting xdg-desktop-portal-hyprland..."
/usr/lib/xdg-desktop-portal-wlr &

sleep 2

# Start xdg-desktop-portal-gtk
echo "Starting xdg-desktop-portal-gtk..."
/usr/lib/xdg-desktop-portal-gtk &

# Start xdg-desktop-portal
echo "Starting xdg-desktop-portal..."
/usr/lib/xdg-desktop-portal &

sleep 1
notify-send "xdg-desktop-portals restarted successfully."


