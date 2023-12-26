#!/bin/bash

swayidle -w \
     timeout 3 'swaylock -f' \
     timeout 6 'swaymsg "output * dpms off"' \
     resume 'swaymsg "output * dpms on"' \
     before-sleep 'swaylock -f'

