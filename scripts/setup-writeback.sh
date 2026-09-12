#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SYSCTL_CONF="/etc/sysctl.d/99-writeback.conf"
TEMPLATE="${PACKAGES_DIR}/99-writeback.conf"

main() {
  require_arch
  [[ -r "${TEMPLATE}" ]] || die "Missing template: ${TEMPLATE}"

  if prompt_step "Install writeback tuning to ${SYSCTL_CONF}?"; then
    sudo install -Dm 644 "${TEMPLATE}" "${SYSCTL_CONF}"
    sudo sysctl --system >/dev/null
    log "Installed ${SYSCTL_CONF} (dirty_bytes=$(sysctl -n vm.dirty_bytes))"
  else
    log "Skipped writeback tuning"
  fi
}

main "$@"
