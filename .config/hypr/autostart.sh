#!/usr/bin/bash

$SCRIPTS=~/.config/hypr/scripts

exec-once = hyprctl setcursor Future-dark-cursors 24
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = dbus-update-activation-environment --systemd --all

exec-once = xwaylandvideobridge
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # make sure that xdg-portals get the required variables
exec-once = systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)

exec-once = udiskie -a --tray # front-end that allows to manage removable media
exec-once = nm-applet --indicator # systray app for Network/Wifi
exec-once = dunst
exec-once = devify
exec-once = hypridle

exec-once = clipse -listen  

# clipboard deamon
exec-once = wl-paste --type text --watch cliphist store  # Stores only text data
exec-once = wl-paste --type image --watch cliphist store # Stores only image data

# scripts
exec-once = ~/.local/bin/rame_check
exec-once = $SCRIPTS/autostart/clipse-cpu-usage.sh
exec-once = $SCRIPTS/autostart/Hypridle.sh
exec-once = $SCRIPTS/autostart/xdgportals.sh
exec-once = $SCRIPTS/autostart/pipewire_check.sh
exec-once = $SCRIPTS/wallpapers/random_walls.sh
exec-once = $SCRIPTS/autostart/toggle-waybar.sh
exec-once = $SCRIPTS/autostart/batterynotify.sh



