#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Packages ship their units disabled; without this a fresh install reboots
# with no network. Units not installed are skipped, so this stays safe to rerun.
UNITS=(NetworkManager.service bluetooth.service docker.service power-profiles-daemon.service)

main() {
  require_arch
  local unit
  for unit in "${UNITS[@]}"; do
    if systemctl list-unit-files "${unit}" --no-legend 2>/dev/null | grep -q .; then
      sudo systemctl enable --now "${unit}"
      log "Enabled ${unit}"
    else
      log "Skipped ${unit} (not installed)"
    fi
  done
}

main "$@"
