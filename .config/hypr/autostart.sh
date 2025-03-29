#!/usr/bin/bash

$SCRIPTS=~/.config/hypr/scripts

exec-once = hyprctl setcursor Future-dark-cursors 24

exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # maket xdg-portals get required variables

# exec-once = udiskie -a --tray # front-end that allows to manage removable media
exec-once = nm-applet --indicator
exec-once = dunst
exec-once = devify
exec-once = hypridle
# exec-once = clipse -listen

# Load cliphist history
exec-once = wl-paste --watch cliphist store

exec-once = swaybg -i ~/Pictures/wallpapers/MR5OBOT.jpg
exec-once = $SCRIPTS/autostart/systeminfo.sh
exec-once = $SCRIPTS/autostart/toggle-waybar.sh
exec-once = $SCRIPTS/autostart/pipewire_check.sh
exec-once = $SCRIPTS/autostart/xdgportals.sh
exec-once = $SCRIPTS/autostart/Hypridle.sh
exec-once = $SCRIPTS/autostart/BAT-check.sh
