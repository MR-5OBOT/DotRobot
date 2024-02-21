#!/usr/bin/bash


powermenu=$(echo -e "Lock Screen\nQuit Hyprland\nReboot\nShutdown" | rofi -dmenu -config ~/.config/rofi/custom/powermenu.rasi)

Lock_cfg="$HOME/repos/DotRoboT/.config/gtklock/style.css"
lock_cmd="gtklock -i -s $Lock_cfg"

case "$powermenu" in
 "Lock Screen")
    $lock_cmd
    ;;
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
