#!/usr/bin/bash

paplay /usr/share/sounds/freedesktop/stereo/service-login.oga
notify-send -i ~/.config/dunst/icons/sleep-timer.png "Starting Swayidle!"

swayidle -w \
   timeout 220 'gtklock -i -s ~/.config/gtklock/style.css ' \
   timeout 120 'hyprctl dispatch dpms off' \
   resume 'hyprctl dispatch dpms on' &
