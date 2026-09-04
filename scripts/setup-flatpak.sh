#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PROFILE_DROP_IN="${HOME}/.config/environment.d/flatpak-xdg.conf"

install_flatpak() {
  if command -v flatpak >/dev/null 2>&1; then
    log "flatpak is already installed"
    return 0
  fi
  require_arch
  log "Installing flatpak"
  sudo pacman -S --needed --noconfirm flatpak
}

add_flathub() {
  if flatpak remotes | grep -q '^flathub'; then
    log "Flathub remote is already configured"
    return 0
  fi
  log "Adding Flathub remote"
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}

configure_xdg_data_dirs() {
  local flatpak_system="/var/lib/flatpak/exports/share"
  local flatpak_user="${HOME}/.local/share/flatpak/exports/share"

  # systemd user environment drop-in (picked up after re-login)
  mkdir -p "$(dirname "${PROFILE_DROP_IN}")"
  if [[ -f "${PROFILE_DROP_IN}" ]]; then
    log "XDG_DATA_DIRS drop-in already exists at ${PROFILE_DROP_IN}"
  else
    cat > "${PROFILE_DROP_IN}" <<EOF
XDG_DATA_DIRS=${flatpak_system}:${flatpak_user}:\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}
EOF
    log "Wrote ${PROFILE_DROP_IN}"
  fi

  # Apply immediately for this session so Rofi picks up .desktop files now
  export XDG_DATA_DIRS="${flatpak_system}:${flatpak_user}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  log "XDG_DATA_DIRS updated for current session"
}

main() {
  install_flatpak
  add_flathub
  configure_xdg_data_dirs
  log "Flatpak setup complete — re-login to make XDG_DATA_DIRS permanent"
}

main "$@"
