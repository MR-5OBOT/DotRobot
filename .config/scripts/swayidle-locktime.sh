#!/bin/bash

pgrep_output=$(pgrep swayidle)
pgrep_arr=($pgrep_output)

if [[ "${#pgrep_arr[@]}" == "0" ]]; then
 echo "Swayidle is not running. Starting Swayidle."
 swayidle -w \
    timeout 20 'swaylock -f' \
    timeout 20 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' &
else
 echo "Swayidle is running. Killing swayidle."
 killall swayidle
fi

