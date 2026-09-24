#!/usr/bin/env bash
set -euo pipefail

dev=$(ls /sys/class/backlight 2>/dev/null | head -n1)
if [[ -z "$dev" ]]; then
    echo 'skip backlight watcher (no backlight device)'
    exit 0
fi

tmp=$(mktemp -d)
runner=''
trap '[[ -z "$runner" ]] || kill "$runner" 2>/dev/null || true; rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat > "$tmp/bin/udevadm" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$$" > "$WATCHER_PID_FILE"
printf 'KERNEL[0] /devices/%s (backlight)\n' "$WATCHER_DEVICE"
exec sleep 30
EOF
chmod +x "$tmp/bin/udevadm"
export WATCHER_PID_FILE="$tmp/watcher.pid" WATCHER_DEVICE="$dev"
PATH="$tmp/bin:$PATH" bash "$(dirname "$0")/../dotfiles/.config/quickshell/island/scripts/backlight-watch.sh" > "$tmp/output" &
runner=$!
for _ in {1..40}; do
    [[ -s "$WATCHER_PID_FILE" ]] && break
    sleep 0.05
done
[[ -s "$WATCHER_PID_FILE" ]]
watcher=$(cat "$WATCHER_PID_FILE")
kill "$runner"
wait "$runner" || true
runner=''
sleep 0.1
! kill -0 "$watcher" 2>/dev/null
grep -Eq '^[0-9]+$' "$tmp/output"
echo 'backlight watcher cleanup check passed'
