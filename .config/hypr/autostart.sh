#!/usr/bin/bash

# variables
scripts="$HOME/.config/hypr/scripts"
wallpapers="$scripts""/wallpapers"
autostart="$scripts""/autostart"

$scripts/lock.sh
$autostart/rdunst.sh # notification app
$autostart/toggle-waybar.sh # toggle waybar
$autostart/idle_handler.sh # swayidle lockscreen with swaylock
$wallpapers/swww-randomize.sh # random wallpapers
$wallpapers/low-battery-notify.sh
hyprctl setcursor Volantes Light Cursors 25

swww kill ; swww init  # wallpaper demon
nm-applet --indicator &  # network manager tray
blueman-applet  # blueman-applet
udiskie -t -n & # Automounter for removable media
devify & # Notify about devices connecting and disconnecting
# swayidle & # Idle daemon to screen lockh

wl-paste --type text --watch cliphist store &  #Stores only text data
wl-paste --type image --watch cliphist store & #Stores only image data

systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
$scripts/autostart/xdgportals

dbus-update-activation-environment --all & 
sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP 
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP


