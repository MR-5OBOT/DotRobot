#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PACMAN_CONF="/etc/pacman.conf"
TEMPLATE="${PACKAGES_DIR}/pacman.conf"

main() {
  require_arch
  [[ -r "${TEMPLATE}" ]] || die "Missing template: ${TEMPLATE}"

  if prompt_step "Replace ${PACMAN_CONF} with the tracked Arch template?"; then
    if [[ -e "${PACMAN_CONF}.dotrobot.bak" || -L "${PACMAN_CONF}.dotrobot.bak" ]]; then
      log "Kept existing ${PACMAN_CONF}.dotrobot.bak"
    else
      sudo cp "${PACMAN_CONF}" "${PACMAN_CONF}.dotrobot.bak"
      log "Saved ${PACMAN_CONF}.dotrobot.bak"
    fi
    sudo install -m 644 "${TEMPLATE}" "${PACMAN_CONF}"
    log "Installed pacman.conf template"
  else
    log "Skipped pacman.conf changes"
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
