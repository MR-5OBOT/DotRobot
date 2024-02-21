#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper

wallDIR="$HOME/Pictures/wallpapers"

PICS=($(find ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))
RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}

# Transition config
FPS=60
TYPE="random"
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-bezier $BEZIER"

pgrep -x swww-daemon || swww init

swww img ${RANDOMPICS} $SWWW_PARAMS

