#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# wl-kbptr handles SUPER+ALT+F keyboard grid clicking.
# Built from packages/arch/wl-kbptr (the AUR package without OpenCV), not the AUR.
main() {
  require_arch
  if pacman -Qq wl-kbptr >/dev/null 2>&1; then
    log "wl-kbptr is already installed"
    return 0
  fi
  pacman -Qq base-devel >/dev/null 2>&1 || pacman_install base-devel
  build_dir="$(mktemp -d)"
  trap 'rm -rf -- "${build_dir}"' EXIT
  cp "${PACKAGES_DIR}/wl-kbptr/PKGBUILD" "${build_dir}/"
  cd "${build_dir}"
  makepkg -si --needed
  log "wl-kbptr installed; SUPER+ALT+F keyboard grid clicking"
}

main "$@"
