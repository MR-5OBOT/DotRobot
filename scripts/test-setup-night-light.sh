#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/hyprsunset"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$SERVICE_LOG"\n' > "$tmp/bin/systemctl"
chmod +x "$tmp/bin/hyprsunset" "$tmp/bin/systemctl"

export HOME="$tmp/home" SERVICE_LOG="$tmp/service.log"
export PATH="$tmp/bin:$PATH"
bash "$(dirname "$0")/setup-night-light.sh"
conf="$HOME/.local/state/island/hyprsunset.conf"
grep -q 'identity = true' "$conf"
grep -q '^ExecStart=/usr/bin/hyprsunset --config ' "$HOME/.config/systemd/user/hyprsunset.service.d/override.conf"
printf 'custom schedule\n' > "$conf"
bash "$(dirname "$0")/setup-night-light.sh"
[[ "$(cat "$conf")" == 'custom schedule' ]]
[[ $(grep -c '^--user daemon-reload$' "$SERVICE_LOG") == 2 ]]
[[ $(grep -c '^--user enable hyprsunset.service$' "$SERVICE_LOG") == 2 ]]
echo 'night-light setup checks passed'
