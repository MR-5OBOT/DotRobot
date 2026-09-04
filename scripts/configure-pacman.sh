#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PACMAN_CONF="/etc/pacman.conf"
TEMPLATE="${PACKAGES_DIR}/pacman.conf"

main() {
  require_arch
  [[ -r "${TEMPLATE}" ]] || die "Missing template: ${TEMPLATE}"

  if prompt_step "Replace ${PACMAN_CONF} with the tracked Arch template?"; then
    sudo cp "${PACMAN_CONF}" "${PACMAN_CONF}.dotrobot.bak"
    sudo install -m 644 "${TEMPLATE}" "${PACMAN_CONF}"
    log "Installed pacman.conf template and saved ${PACMAN_CONF}.dotrobot.bak"
  else
    log "Skipped pacman.conf changes"
  fi
}

main "$@"
