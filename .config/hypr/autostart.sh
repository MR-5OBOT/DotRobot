#!/usr/bin/bash


# variables
# scripts="$HOME/scripts"

exec-once = $HOME/.config/scripts/dunst-start # notification app
exec-once = $HOME/MR-5OBOT/DotRoboT/.config/hypr/scripts/toggle-waybar.sh # toggle waybar
exec-once = $HOME/.config/scripts/swayidle_screenlocker.sh # swayidle lockscreen with swaylock
# exec-once = ~/.config/scripts/swww-randomize.sh # random wallpapers
exec-once = swww img ~/Pictures/wallpapers/b.jpg
exec-once = $HOME/.config/scripts/low-battery-notify.sh

exec-once = swww init
exec-once = nm-applet & # network manager tray
exec-once = blueman-applet # blueman-applet
exec-once = udiskie & # Automounter for removable media
exec-once = devify & # Notify about devices connecting and disconnecting
exec-once = swayidle & # Idle daemon to screen lockh

exec-once = wl-clipboard-history -t
exec-once = wl-paste --type text --watch cliphist store &  #Stores only text data
exec-once = wl-paste --type image --watch cliphist store & #Stores only image data

exec-once = systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)
exec-once= sleep 1 && systemctl --user start pipewire pipewire-pulse wireplumber
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

exec-once = $HOME/.config/hypr/xdg-portal-hyprland
exec-once = dbus-update-activation-environment --all &

exec-once = sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP


