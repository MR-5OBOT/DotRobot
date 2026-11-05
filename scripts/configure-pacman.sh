#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PACMAN_CONF="/etc/pacman.conf"
TEMPLATE="${PACKAGES_DIR}/pacman.conf"

main() {
  require_arch
  [[ -r "${TEMPLATE}" ]] || die "Missing template: ${TEMPLATE}"

  if [[ -e "${PACMAN_CONF}.dotrobot.bak" || -L "${PACMAN_CONF}.dotrobot.bak" ]]; then
    log "Kept existing ${PACMAN_CONF}.dotrobot.bak"
  else
    sudo cp "${PACMAN_CONF}" "${PACMAN_CONF}.dotrobot.bak"
    log "Saved ${PACMAN_CONF}.dotrobot.bak"
  fi
  sudo install -m 644 "${TEMPLATE}" "${PACMAN_CONF}"
  log "Installed the pacman.conf template"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
