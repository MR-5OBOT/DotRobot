#!/usr/bin/bash

$SCRIPTS=~/.config/hypr/scripts

exec-once = dunst & # notfication demon
exec-once = nm-applet & # network manager tray
# exec-once = udiskie -t -n & # Automounter for removable media
exec-once = devify & # Notify about devices connecting and disconnecting
# exec-once = swww init
exec-once = blueman-applet & 

exec-once = dbus-update-activation-environment --all & 
exec-once = sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

exec-once = hyprctl setcursor Volantes Light Cursors 27
exec-once = systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)
# exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec-once = $SCRIPTS/autostart/xdgportals
exec-once = wl-paste --type text --watch cliphist store &  #Stores only text data
exec-once = wl-paste --type image --watch cliphist store & #Stores only image data

exec-once = $SCRIPTS/wallpapers/random_walls.sh
exec-once = $SCRIPTS/autostart/lock.sh
exec-once = $SCRIPTS/autostart/Polkit.sh
exec-once = $SCRIPTS/autostart/toggle-waybar.sh
exec-once = $SCRIPTS/autostart/idle_handler.sh
exec-once = $SCRIPTS/autostart/TinkPad_BT_notify.sh


