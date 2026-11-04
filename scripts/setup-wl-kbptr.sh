#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# wl-kbptr draws the SUPER+F click labels (hypr/scripts/controls/kbptr.py).
# Built from packages/arch/wl-kbptr (the AUR package without OpenCV), not the AUR.
main() {
  require_arch
  if pacman -Qq wl-kbptr >/dev/null 2>&1; then
    log "wl-kbptr is already installed"
    return 0
  fi
  pacman -Qq base-devel >/dev/null 2>&1 || sudo pacman -Syu --needed base-devel
  build_dir="$(mktemp -d)"
  trap 'rm -rf -- "${build_dir}"' EXIT
  cp "${PACKAGES_DIR}/wl-kbptr/PKGBUILD" "${build_dir}/"
  cd "${build_dir}"
  makepkg -si --needed
  log "wl-kbptr installed; SUPER+F labels pressable things"
}

main "$@"
