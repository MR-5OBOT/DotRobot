#!/usr/bin/bash


powermenu=$(echo -e "Lock Screen\nQuit Hyprland\nReboot\nShutdown" | rofi -dmenu -config ~/.config/rofi/custom/powermenu.rasi)

Lock_cfg="$HOME/MR-5OBOT/DotRoboT/.config/gtklock/style.css"
lock_cmd="gtklock -i -s $Lock_cfg"

case "$powermenu" in
 "Lock Screen")
    $lock_cmd
    ;;
 "Quit Hyprland")
    systemctl exit
    ;;
 "Reboot")
    sudo reboot
    ;;
 "Shutdown")
    sudo shutdown now
    ;;
esac
