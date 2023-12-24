#!/usr/bin/bash

# exec-once = ~/.config/scripts/mako-start
exec-once = ~/.config/scripts/dunst-start
exec-once = swww init
exec-once = ~/.config/scripts/togglebar.sh
exec-once = ~/.config/scripts/rame-treshold.sh
exec-once = ~/.config/scripts/battery-notify.sh

# exec-once = swaybg -m fill -i ~/Pictures/wallpapers/xx1.png
exec-once = ~/.config/scripts/swww-randomize.sh

exec-once = nm-applet &
exec-once = wl-clipboard-history -t
exec-once = wl-paste --type text --watch cliphist store #Stores only text data
exec-once = wl-paste --type image --watch cliphist store #Stores only image data

exec-once = systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = ~/.config/hypr/xdg-portal-hyprland
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
# exec-once = swayidle -w timeout 200 'gtklock -d' timeout 200 'hyprctl dispatch dpms off' resume 'hyprctl dispatch dpms on' before-sleep "gtklock -d"
