#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ZRAM_CONF="/etc/systemd/zram-generator.conf"
TEMPLATE="${PACKAGES_DIR}/zram-generator.conf"
SYSCTL_CONF="/etc/sysctl.d/99-zram.conf"
SYSCTL_TEMPLATE="${PACKAGES_DIR}/99-zram.conf"

main() {
  require_arch
  [[ -r "${TEMPLATE}" ]] || die "Missing template: ${TEMPLATE}"
  [[ -r "${SYSCTL_TEMPLATE}" ]] || die "Missing template: ${SYSCTL_TEMPLATE}"
  pacman -Qq zram-generator >/dev/null 2>&1 || sudo pacman -S --needed --noconfirm zram-generator

  sudo install -Dm 644 "${TEMPLATE}" "${ZRAM_CONF}"
  sudo systemctl daemon-reload
  # Restarting swaps zram off and back on; anything in it moves to RAM first.
  sudo systemctl restart systemd-zram-setup@zram0.service
  log "Installed ${ZRAM_CONF} ($(zramctl --noheadings --output DISKSIZE /dev/zram0 | tr -d ' ') zram)"

  sudo install -Dm 644 "${SYSCTL_TEMPLATE}" "${SYSCTL_CONF}"
  sudo sysctl --system >/dev/null
  log "Installed ${SYSCTL_CONF} (swappiness=$(sysctl -n vm.swappiness))"
}

main "$@"
