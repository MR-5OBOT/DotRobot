#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage: scripts/install-packages.sh [group...]

Groups:
  core
  desktop
  aur
  all
EOF
}

install_repo_group() {
  local group="$1"
  mapfile -t packages < <(read_package_file "${PACKAGES_DIR}/${group}.txt")
  [[ ${#packages[@]} -gt 0 ]] || return 0
  log "Installing ${group} packages"
  sudo pacman -S --needed --noconfirm "${packages[@]}"
}

install_aur_group() {
  mapfile -t packages < <(read_package_file "${PACKAGES_DIR}/aur.txt")
  [[ ${#packages[@]} -gt 0 ]] || return 0
  command -v paru >/dev/null 2>&1 || die "paru is required for AUR packages. Run scripts/setup-aur-helper.sh first."
  log "Installing aur packages"
  paru -S --needed "${packages[@]}"
}

main() {
  require_arch

  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  for group in "$@"; do
    case "${group}" in
      core|desktop) install_repo_group "${group}" ;;
      aur) install_aur_group ;;
      all)
        install_repo_group core
        install_repo_group desktop
        install_aur_group
        ;;
      *)
        usage
        die "Unknown group: ${group}"
        ;;
    esac
  done
}

main "$@"
