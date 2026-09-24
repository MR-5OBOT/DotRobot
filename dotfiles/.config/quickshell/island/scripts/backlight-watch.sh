#!/usr/bin/env bash
set -u

dev=$(ls /sys/class/backlight 2>/dev/null | head -n1)
[ -n "$dev" ] || exit 0
dir="/sys/class/backlight/$dev"
max=$(cat "$dir/max_brightness")
[[ "$max" =~ ^[0-9]+$ && "$max" -gt 0 ]] || exit 1

tmp=$(mktemp -d)
mkfifo "$tmp/events"
udevadm monitor --subsystem-match=backlight > "$tmp/events" &
watcher=$!
parent=$PPID

cleanup() {
    kill "$watcher" "$watchdog" 2>/dev/null || true
    wait "$watcher" 2>/dev/null || true
    rm -rf "$tmp"
}
trap cleanup EXIT
trap 'exit 0' TERM INT

# If Quickshell is killed without closing the process, stop only our watcher.
( while [ -d "/proc/$parent" ] && [ -d "/proc/$$" ]; do sleep 3; done
  kill -TERM "$watcher" "$$" 2>/dev/null || true ) &
watchdog=$!

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
done < "$tmp/events"
