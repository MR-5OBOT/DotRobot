#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# zram swap at half of RAM, at most 8 GiB (packages/arch/zram-generator.conf),
# plus the swap settings that suit compressed swap (packages/arch/99-zram.conf).
# A running zram device keeps its old size until the next boot.
main() {
  require_arch
  pacman -Qq zram-generator >/dev/null 2>&1 || sudo pacman -Syu --needed --noconfirm zram-generator
  sudo install -Dm 644 "${PACKAGES_DIR}/zram-generator.conf" /etc/systemd/zram-generator.conf
  sudo install -Dm 644 "${PACKAGES_DIR}/99-zram.conf" /etc/sysctl.d/99-zram.conf
  sudo systemctl daemon-reload
  sudo systemctl start dev-zram0.swap
  sudo sysctl -q -p /etc/sysctl.d/99-zram.conf
  log "zram swap: $(swapon --show=NAME,SIZE --noheadings | grep zram || echo 'starts at next boot')"
}

main "$@"
