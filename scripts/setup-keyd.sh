#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

readonly CONF="${DOTFILES_DIR}/keyd/default.conf"
readonly TARGET="/etc/keyd/default.conf"

# Copied root-owned rather than symlinked: keyd runs as root and its command()
# action runs shell as root, so a config your user can write is a root shell.
# Re-run after editing the repo copy; reloading needs sudo either way.
main() {
  require_arch
  [[ -r "${CONF}" ]] || die "Missing ${CONF}"
  pacman -Qq keyd >/dev/null 2>&1 || pacman_install keyd
  keyd check "${CONF}" || die "keyd rejected ${CONF}; kept the current config"
  sudo install -Dm 644 "${CONF}" "${TARGET}"
  # restart, not `keyd reload`: keyd 2.6.0 segfaulted seconds after a reload,
  # while a fresh start with the same config ran fine (2026-11-06)
  sudo systemctl enable keyd
  sudo systemctl restart keyd
  log "keyd is using ${CONF}. Panic exit: Backspace+Escape+Enter"
}

main "$@"
