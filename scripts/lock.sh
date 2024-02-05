#!/usr/bin/bash

gtklock_dir=$HOME/MR-5OBOT/DotRoboT/.config/gtklock/style.css

swayidle -w \
    timeout 5 "hyprctl dispatch dpms off" \
    resume 'hyprctl dispatch dpms on' &

gtklock -i -s $gtklock_dir 

kill %%



