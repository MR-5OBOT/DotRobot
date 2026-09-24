#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dotfiles/.local/bin/scrcpy-wifi"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
STATE_FILE="${tmp_dir}/last"
NET_CLASS="${tmp_dir}/net"
mkdir -p "${NET_CLASS}/wlan0/device" "${NET_CLASS}/docker0"
ip() { printf '3: wlan0 inet 10.20.30.4/24 scope global wlan0\n'; }

printf '192.168.8.9:5555\n' >"${STATE_FILE}"
[[ "$(scan_bases)" == $'192.168.8\n10.20.30' ]]
rm "${STATE_FILE}"
[[ "$(scan_bases)" == '10.20.30' ]]

# The first open port can be another device. Keep trying the discovered IPs.
mkdir -p "$tmp_dir/bin"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" > "$SCRCPY_TEST_LOG"\n' > "$tmp_dir/bin/scrcpy"
chmod +x "$tmp_dir/bin/scrcpy"
export PATH="$tmp_dir/bin:$PATH" SCRCPY_TEST_LOG="$tmp_dir/scrcpy.log"
STATE_DIR="$tmp_dir/cache"
STATE_FILE="$STATE_DIR/last"
seq() { printf '1\n2\n'; }
timeout() { return 0; }
adb() { return 0; }
scan_bases() { printf '10.20.30\n'; }
try_connect() { [[ "$1" == '10.20.30.2:5555' ]]; }
( main )
[[ "$(cat "$STATE_FILE")" == '10.20.30.2:5555' ]]
grep -q -- '-s 10.20.30.2:5555' "$SCRCPY_TEST_LOG"

printf 'scrcpy-wifi tests passed\n'
