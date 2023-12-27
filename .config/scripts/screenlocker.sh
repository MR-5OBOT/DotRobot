#!/bin/bash

swayidle -w \
     timeout 200 'swaylock -f' \
     timeout 200 'swaymsg "output * dpms off"' \
     resume 'swaymsg "output * dpms on"' \
     before-sleep 'swaylock -f'

