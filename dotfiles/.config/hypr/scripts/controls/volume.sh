#!/bin/bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Volume and mic keys. The island shows volume and mic changes by itself.

case "$1" in
--inc) pamixer -u; pamixer -i 5 ;;   # raising the volume also unmutes
--dec) pamixer -u; pamixer -d 5 ;;
--toggle) pamixer -t ;;
--toggle-mic) pamixer --default-source -t ;;
*) echo "usage: volume.sh --inc | --dec | --toggle | --toggle-mic" >&2; exit 2 ;;
esac
