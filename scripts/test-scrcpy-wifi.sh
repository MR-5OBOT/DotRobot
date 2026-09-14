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

printf 'scrcpy-wifi tests passed\n'
