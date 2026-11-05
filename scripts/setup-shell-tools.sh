#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

setup_zinit() {
  local zinit_home="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
  if [[ -d "${zinit_home}" ]]; then
    log "zinit is already installed"
    return 0
  fi

  mkdir -p "$(dirname "${zinit_home}")"
  git clone https://github.com/zdharma-continuum/zinit.git "${zinit_home}"
  log "Installed zinit"
}

main() {
  setup_zinit
}

main "$@"
