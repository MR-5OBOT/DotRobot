#!/usr/bin/env bash
# __  ______   ____
# \ \/ /  _ \ / ___|
#  \  /| | | | |  _
#  /  \| |_| | |_| |
# /_/\_\____/ \____|
#

echo "starting xdgportals..."


# Kill all possible running xdg-desktop-portals
# killall -e xdg-desktop-portal-hyprland
# killall -e xdg-desktop-portal-gnome
# killall -e xdg-desktop-portal-kde
# killall -e xdg-desktop-portal-lxqt
# killall -e xdg-desktop-portal-wlr
# killall -e xdg-desktop-portal-gtk
# killall xdg-desktop-portal
# sleep 1

# set required environment variable
# dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # Set environment variables for XDG Desktop Portal

# start xdg-desktop-portal-hyprland
/usr/lib/xdg-desktop-portal-hyprland &
/usr/lib/xdg-desktop-portal &

# start xdg-desktop-portal-gtk
# /usr/lib/xdg-desktop-portal-gtk &

echo "xdg portals script finish"
