#!/usr/bin/env bash

notify-send -i ~/.config/dunst/icons/sleep-timer.png "Starting Swayidle!"

swayidle -w \
   timeout 120 'hyprlock' \
   timeout 12 'hyprctl dispatch dpms off' \
   resume 'hyprctl dispatch dpms on' &
