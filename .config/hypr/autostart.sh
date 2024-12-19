#!/usr/bin/bash

$SCRIPTS=~/.config/hypr/scripts

exec-once = hyprctl setcursor Future-dark-cursors 24
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP # maket xdg-portals get required variables
exec-once = systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)


# exec-once = udiskie -a --tray # front-end that allows to manage removable media
exec-once = nm-applet --indicator # systray app for Network/Wifi
exec-once = dunst
exec-once = devify
exec-once = hypridle
exec-once = clipse -listen  

exec-once = swaybg -i ~/Pictures/wallpapers/MR5OBOT.jpg
exec-once = $SCRIPTS/autostart/pipewire_check.sh
exec-once = $SCRIPTS/autostart/xdgportals.sh
exec-once = $SCRIPTS/autostart/toggle-waybar.sh
exec-once = $SCRIPTS/autostart/Hypridle.sh
exec-once = $SCRIPTS/autostart/BAT-check.sh
exec-once = ~/.local/bin/mount_gdrive


exec-once = xdg-settings set default-web-browser thorium-browser.desktop
