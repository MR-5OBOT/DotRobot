#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Backlight keys (brightnessctl). The island shows brightness changes by itself.

case "$1" in
--inc) brightnessctl set +10% ;;
--dec) brightnessctl set 10%- ;;
*) echo "usage: brightness.sh --inc | --dec" >&2; exit 2 ;;
esac
