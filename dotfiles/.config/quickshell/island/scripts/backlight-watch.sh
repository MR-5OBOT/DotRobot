#!/usr/bin/env bash
set -u

dev=$(ls /sys/class/backlight 2>/dev/null | head -n1)
[ -n "$dev" ] || exit 0
dir="/sys/class/backlight/$dev"
max=$(cat "$dir/max_brightness")
[[ "$max" =~ ^[0-9]+$ && "$max" -gt 0 ]] || exit 1

# This bash can die without running traps (SIGKILL, SIGPIPE), which orphaned udevadm and leaked fifo dirs;
# pdeathsig ties udevadm to it unconditionally, and process substitution needs no temp files.
exec 3< <(exec setpriv --pdeathsig TERM udevadm monitor --subsystem-match=backlight)

read_brightness() {
    local value
    value=$(cat "$dir/brightness" 2>/dev/null) || return
    [[ "$value" =~ ^[0-9]+$ ]] && echo "$(( value * 100 / max ))"
}

read_brightness
while IFS= read -r line; do
    case "$line" in
        KERNEL*"/$dev (backlight)") read_brightness ;;
    esac
done <&3
