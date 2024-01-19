#!/usr/bin/bash

# exec-once = hyprctl setcursor Volantes Light Cursors 26
exec-once = ~/.config/scripts/dunst-start # notification app
exec-once = ~/.config/scripts/togglebar.sh # toggle waybar
exec-once = ~/.config/scripts/swayidle-locktime.sh # swayidle lockscreen with swaylock
exec-once = ~/.config/scripts/swww-randomize.sh # random wallpapers
exec-once = ~/.config/scripts/low-battery-notify.sh

exec-once = swww init
exec-once = nm-applet & # network manager tray
exec-once = udiskie & # Automounter for removable media
exec-once = devify & # Notify about devices connecting and disconnecting
exec-once = swayidle & # Idle daemon to screen lockh

exec-once = wl-clipboard-history -t
exec-once = wl-paste --type text --watch cliphist store &  #Stores only text data
exec-once = wl-paste --type image --watch cliphist store & #Stores only image data

exec-once = systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec-once = ~/.config/hypr/xdg-portal-hyprland
exec-once = dbus-update-activation-environment --all &
exec-once = sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP


