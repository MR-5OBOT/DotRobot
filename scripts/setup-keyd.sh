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
  pacman -Qq keyd >/dev/null 2>&1 || sudo pacman -Syu --needed --noconfirm keyd
  keyd check "${CONF}" || die "keyd rejected ${CONF}; kept the current config"
  sudo install -Dm 644 "${CONF}" "${TARGET}"
  if systemctl is-active --quiet keyd; then
    sudo keyd reload
  else
    sudo systemctl enable --now keyd
  fi
  log "keyd is using ${CONF}. Panic exit: Backspace+Escape+Enter"
}

main "$@"
