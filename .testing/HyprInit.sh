#!/usr/bin/env bash

start() {
	nohup "$@" &> /dev/null &
}

SCRIPTS=~/.config/hypr/scripts/
WALLPAPER_PATH="$(find "$HOME"/Pictures/wallpapers/ -type f | shuf -n1)"

#Check if a marker file exists.
if [ ! -f ~/.config/hypr/.initial_startup_done ]; then

pgrep -x swww-deamon	|| start swww init && swww img "$WALLPAPER_PATH" --transition-type random
pgrep -x nm-applet    || start nm-applet
pgrep -x blueman	    || start blueman-applet
pgrep -x uudiskie     || start udiskie -t -n
pgrep -x dunst		    || start dunst
pgrep -x devify       || start devify 
pgrep -x swayidle	    || start bash -c '$HOME/.config/hypr/scripts/autostart/lock.sh'

# start /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
start systemctl --user restart pipewire # RESTARTS PIPEWIRE (RECOMMENDED BY HYPRLAND DOC)
start $SCRIPTS/autostart/xdgportals

# start hyprctl setcursor Volantes Light Cursors 27
start wl-paste --type text --watch cliphist store
start wl-paste --type image --watch cliphist store

start dbus-update-activation-environment --all &                                                   
start sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP  
start systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP                      

start $SCRIPTS/autostart/lock.sh               
start $SCRIPTS/autostart/Polkit.sh
start $SCRIPTS/autostart/swww-daemon.sh        
start $SCRIPTS/wallpapers/random_walls.sh
start $SCRIPTS/autostart/toggle-waybar.sh      
start $SCRIPTS/autostart/idle_handler.sh       
start $SCRIPTS/autostart/TinkPad_BT_notify.sh

# initiate GTK dark mode and apply icon and cursor theme
gsettings set org.gnome.desktop.interface color-scheme prefer-dark > /dev/null 2>&1 &
gsettings set org.gnome.desktop.interface gtk-theme paradise > /dev/null 2>&1 &
gsettings set org.gnome.desktop.interface icon-theme Gruvebox Plus Dark > /dev/null 2>&1 &
gsettings set org.gnome.desktop.interface cursor-theme Volantes Light Cursors > /dev/null 2>&1 &
gsettings set org.gnome.desktop.interface cursor-size 27 > /dev/null 2>&1 &

 # Create a marker file to indicate that the script has been executed.
touch ~/.config/hypr/.initial_startup_done

exit
