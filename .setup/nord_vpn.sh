#!/usr/bin/env bash

if pacman -Q nordvpnd-bin >/dev/null 2>&1; then
    systemctl start nordvpnd.service
    systemctl enable nordvpnd.socket
else
    yay -S nordvpn-bin
    systemctl start nordvpnd.service
    systemctl enable nordvpnd.socket
fi
notify-send "nordvpn is ready now "



