#!/usr/bin/bash
# ----------------------------------------------------- 
# Autostart
# ----------------------------------------------------- 

$SCRIPTS=~/.config/hypr/scripts

exec-once = dunst
exec-once = devify
exec-once = swww init
# exec-once = hypridle

exec-once = udiskie --no-automount --smart-tray # front-end that allows to manage removable media
exec-once = nm-applet --indicator # systray app for Network/Wifi

exec-once = hyprctl setcursor Future-dark-cursors 24
exec-once = wl-clipboard --watch -t
exec-once = wl-paste --type text --watch cliphist store  # Stores only text data
exec-once = wl-paste --type image --watch cliphist store # Stores only image data

exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 || /usr/lib/polkit-gnome-authentication-agent-1
exec-once = dbus-update-activation-environment --all
exec-once = sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # Some fix idk
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # for XDPH
exec-once = systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)

exec-once = $SCRIPTS/autostart/xdgportals
exec-once = $SCRIPTS/wallpapers/random_walls.sh
exec-once = $SCRIPTS/autostart/toggle-waybar.sh
exec-once = $SCRIPTS/autostart/TinkPad_BT_notify.sh
# exec-once = $SCRIPTS/autostart/gtk.sh # Load GTK settings


