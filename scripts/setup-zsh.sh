#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

main() {
  require_arch

  if ! command -v zsh >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm zsh
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" == "${zsh_path}" ]]; then
    log "Default shell is already zsh"
    exit 0
  fi

  chsh -s "${zsh_path}"
  log "Changed default shell to ${zsh_path}"
}

main "$@"
