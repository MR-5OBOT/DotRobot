#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Services needed by the desktop are automatic. Hardware/features the user may
# not use are opt-in so running the installer does not silently start them.
DEFAULT_UNITS=(NetworkManager.service power-profiles-daemon.service thermald.service)
OPTIONAL_UNITS=(bluetooth.service docker.service)

enable_unit() {
  local unit="$1"
  if systemctl list-unit-files "${unit}" --no-legend 2>/dev/null | grep -q .; then
    sudo systemctl enable --now "${unit}"
    log "Enabled ${unit}"
  else
    log "Skipped ${unit} (not installed)"
  fi
}

main() {
  require_arch
  local unit answer
  for unit in "${DEFAULT_UNITS[@]}"; do
    enable_unit "${unit}"
  done
  for unit in "${OPTIONAL_UNITS[@]}"; do
    printf 'Enable optional %s? [y/N]: ' "${unit}"
    read -r answer || answer=""
    if [[ ${answer} =~ ^[Yy]$ ]]; then
      enable_unit "${unit}"
    else
      log "Skipped optional ${unit}"
    fi
  done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
