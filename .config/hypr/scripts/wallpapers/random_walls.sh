#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Random Wallpaper

wallDIR="$HOME/Pictures/wallpapers/"

if ! command -v swww &> /dev/null; then
    echo "swww command not found. Please install swww."
    exit 1
fi

if [ ! -d "$wallDIR" ]; then
    echo "Wallpaper directory '$wallDIR' does not exist."
    exit 1
fi

PICS=($(find ${wallDIR} -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.gif" \)))

if [ ${#PICS[@]} -gt 0 ]; then
  RANDOMPICS=${PICS[ $RANDOM % ${#PICS[@]} ]}

  # Transition config
  FPS=60
  TYPE="random"
  BEZIER=".43,1.19,1,.4"
  SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-bezier $BEZIER"

  # pgrep -x swww-daemon || swww-daemon

  # swww img ${RANDOMPICS} $SWWW_PARAMS
  swaybg -i ${RANDOMPICS}
else
  echo "No images found in $wallDIR"
fi


