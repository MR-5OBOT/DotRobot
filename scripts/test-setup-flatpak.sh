#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
source "$(dirname "$0")/setup-flatpak.sh"

PROFILE_DROP_IN="$tmp/flatpak-xdg.conf"
LOG_FILE="$tmp/test.log"
flatpak() {
  [[ $1 == remotes ]] && return 0
  printf '%s\n' "$*" >"$tmp/action"
}

main
[[ $(<"$tmp/action") == 'remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo' ]]
grep -Fq '/var/lib/flatpak/exports/share' "$PROFILE_DROP_IN"
echo "Flatpak user setup test passed"
