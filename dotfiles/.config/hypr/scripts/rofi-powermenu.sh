#!/usr/bin/env bash

theme="${HOME}/.config/rofi/powermenu.rasi"

powermenu=$(
    printf '%s\n' "Quit Hyprland" "Reboot" "Shutdown" |
        rofi -dmenu -theme "${theme}"
)

case "$powermenu" in
"Quit Hyprland")
    hyprctl dispatch exit
    ;;
"Reboot")
    systemctl reboot
    ;;
"Shutdown")
    systemctl poweroff
    ;;
esac
