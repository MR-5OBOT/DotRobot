#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_flatpak() {
  if command -v flatpak >/dev/null 2>&1; then
    log "flatpak is already installed"
    return 0
  fi
  require_arch
  log "Installing flatpak"
  sudo pacman -Syu --needed --noconfirm flatpak
}

add_flathub() {
  if flatpak remotes --user | grep -q '^flathub'; then
    log "Flathub user remote is already configured"
    return 0
  fi
  log "Adding Flathub user remote"
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

main() {
  install_flatpak
  add_flathub
  log "Flatpak setup complete — re-login to expose Flatpak app launchers (flatpak's systemd env generator adds them to XDG_DATA_DIRS)"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
