#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

main() (
  require_arch

  if command -v paru >/dev/null 2>&1; then
    log "paru is already installed"
    exit 0
  fi

  build_dir="$(mktemp -d)"
  trap 'rm -rf -- "${build_dir}"' EXIT

  # paru-bin: the prebuilt release, so no Rust compile and no paru-debug package.
  log "Installing paru"
  sudo pacman -Syu --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/paru-bin.git "${build_dir}/paru-bin"
  (
    cd "${build_dir}/paru-bin"
    makepkg -si --noconfirm
  )
)

main "$@"
