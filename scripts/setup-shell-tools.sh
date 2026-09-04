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

setup_tpm() {
  local tpm_dir="${HOME}/.tmux/plugins/tpm"
  if [[ -d "${tpm_dir}" ]]; then
    log "tmux plugin manager is already installed"
    return 0
  fi

  mkdir -p "$(dirname "${tpm_dir}")"
  git clone https://github.com/tmux-plugins/tpm "${tpm_dir}"
  log "Installed tmux plugin manager"
}

main() {
  setup_zinit
  setup_tpm
}

main "$@"
