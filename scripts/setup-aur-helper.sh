#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

main() {
  require_arch

  if command -v paru >/dev/null 2>&1; then
    log "paru is already installed"
    exit 0
  fi

  local build_dir
  build_dir="$(mktemp -d)"
  trap 'rm -rf "${build_dir}"' EXIT

  log "Installing paru"
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/paru.git "${build_dir}/paru"
  (
    cd "${build_dir}/paru"
    makepkg -si --noconfirm
  )
}

main "$@"
