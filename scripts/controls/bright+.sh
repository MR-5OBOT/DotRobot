#!/usr/bin/env sh

icon="~/.config/dunst/icons/brightness-100.png"

if ! [ -x "$(command -v brightnessctl)" ]; then
  notify-send "brightnessctl not found"
  exit 1
fi

brightnessctl +10%
notify-send -i "$icon" "$(brightnessctl g)"
