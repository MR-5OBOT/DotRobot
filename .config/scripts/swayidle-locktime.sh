#!/bin/bash

pgrep_output=$(pgrep swayidle)
pgrep_arr=($pgrep_output)

if [[ "${#pgrep_arr[@]}" == "0" ]]; then

 paplay /usr/share/sounds/freedesktop/stereo/service-login.oga
 notify-send -i ~/.config/dunst/icons/sleep-timer.png  "Swayidle is not running. Starting Swayidle (2min befor sleep)"

 swayidle -w \
    timeout 60 'swaylock -f' \
    timeout 40 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' &

else

 echo "Swayidle is running. Killing swayidle."
 killall swayidle

fi

