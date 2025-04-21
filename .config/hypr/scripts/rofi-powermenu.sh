#!/usr/bin/bash

powermenu=$(echo -e "Quit Hyprland\nReboot\nShutdown" | rofi -dmenu -config ~/.config/rofi/custom/powermenu.rasi)

case "$powermenu" in
"Quit Hyprland")
    pkill -u $USER
    ;;
"Reboot")
    reboot
    ;;
"Shutdown")
    systemctl exit
    ;;
esac
