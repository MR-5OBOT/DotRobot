#!/usr/bin/bash

# exec-once = ~/.config/scripts/mako-start
exec-once = swww init
exec-once = ~/.config/scripts/dunst-start
exec-once = ~/.config/scripts/togglebar.sh
exec-once = ~/.config/scripts/rame-treshold.sh
exec-once = ~/.config/scripts/battery-notify.sh
exec-once = ~/.config/scripts/swayidle-locktime.sh
exec-once = ~/.config/scripts/swww-randomize.sh

exec-once = nm-applet &
exec-once = wl-clipboard-history -t
exec-once = wl-paste --type text --watch cliphist store #Stores only text data
exec-once = wl-paste --type image --watch cliphist store #Stores only image data

exec-once = systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = ~/.config/hypr/xdg-portal-hyprland.sh
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP


