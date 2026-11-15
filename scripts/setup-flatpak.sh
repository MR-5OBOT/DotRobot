#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

main() {
  require_arch
  pacman_install flatpak
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  log "Flatpak setup complete — re-login to expose Flatpak app launchers (flatpak's systemd env generator adds them to XDG_DATA_DIRS)"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
