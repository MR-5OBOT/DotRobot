#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PACMAN_CONF="/etc/pacman.conf"
TEMPLATE="${PACKAGES_DIR}/pacman.conf"

main() {
  require_arch
  [[ -r "${TEMPLATE}" ]] || die "Missing template: ${TEMPLATE}"

  # --update=none never overwrites the backup, so it stays the untouched original.
  sudo cp --update=none "${PACMAN_CONF}" "${PACMAN_CONF}.dotrobot.bak"
  log "Original saved as ${PACMAN_CONF}.dotrobot.bak"
  sudo install -m 644 "${TEMPLATE}" "${PACMAN_CONF}"
  log "Installed the pacman.conf template"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
