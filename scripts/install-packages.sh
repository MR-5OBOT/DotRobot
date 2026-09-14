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

cpu_microcode_package() {
  case "$1" in
    GenuineIntel) printf '%s\n' intel-ucode ;;
    AuthenticAMD) printf '%s\n' amd-ucode ;;
    *) return 1 ;;
  esac
}

gpu_video_package() {
  case "${1,,}" in
    0x8086) printf '%s\n' intel-media-driver ;;
    0x1002) printf '%s\n' mesa ;;
    *) return 1 ;;
  esac
}

install_repo_group() {
  local group="$1"
  local vendor microcode device class package
  local nvidia_gpu=0
  local -a packages
  local -A gpu_packages=()
  mapfile -t packages < <(read_package_file "${PACKAGES_DIR}/${group}.txt")
  [[ ${#packages[@]} -gt 0 ]] || return 0

  if [[ ${group} == core ]]; then
    vendor="$(awk -F: '/^vendor_id/{gsub(/[[:space:]]/, "", $2); print $2; exit}' /proc/cpuinfo)"
    if microcode="$(cpu_microcode_package "${vendor}")"; then
      packages+=("${microcode}")
    else
      warn "Unknown CPU vendor '${vendor:-missing}'; skipped CPU microcode"
    fi

    for device in /sys/bus/pci/devices/*; do
      [[ -r ${device}/class && -r ${device}/vendor ]] || continue
      read -r class <"${device}/class"
      [[ ${class} == 0x03* ]] || continue
      read -r vendor <"${device}/vendor"
      if package="$(gpu_video_package "${vendor}")"; then
        gpu_packages["${package}"]=1
      elif [[ ${vendor,,} == 0x10de ]]; then
        nvidia_gpu=1
      fi
    done
    for package in "${!gpu_packages[@]}"; do
      packages+=("${package}")
    done
    (( nvidia_gpu == 0 )) || warn "Nvidia GPU detected; install the driver matching its GPU and kernel manually"
  fi

  log "Installing ${group} packages"
  sudo pacman -Syu --needed --noconfirm "${packages[@]}"
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

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
