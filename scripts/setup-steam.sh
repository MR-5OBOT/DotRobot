#!/usr/bin/env bash
# Steam + Proton: Steam, the 32-bit Vulkan stack Proton needs, and the Vulkan
# driver for each GPU found. Never installs or swaps a kernel GPU driver.
#   scripts/setup-steam.sh [--yes] [--extras]
#   --yes     no prompt (the installer already asked)
#   --extras  also gamescope, mangohud, protontricks
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

main() {
  local yes=0 extras=0 arg vendor
  local -a pkgs=(steam steam-devices vulkan-icd-loader lib32-vulkan-icd-loader vulkan-tools
    ttf-liberation lib32-alsa-plugins lib32-libpulse)

  for arg in "$@"; do
    case "${arg}" in
      --yes | -y) yes=1 ;;
      --extras) extras=1 ;;
      *) die "Usage: $0 [--yes] [--extras]" ;;
    esac
  done
  require_arch
  [[ $EUID -ne 0 ]] || die "Run as your normal user; Steam's library is per-user."
  pacman-conf --repo-list | grep -qx multilib || die "[multilib] is off; run scripts/configure-pacman.sh first."

  for vendor in $(cat /sys/class/drm/card*/device/vendor 2>/dev/null | sort -u); do
    case "${vendor}" in
      0x8086) pkgs+=(vulkan-intel lib32-vulkan-intel lib32-mesa) ;;
      0x1002) pkgs+=(vulkan-radeon lib32-vulkan-radeon lib32-mesa) ;;
      0x10de)
        if pacman -Qq nvidia-utils >/dev/null 2>&1; then
          pkgs+=(lib32-nvidia-utils)
        else
          warn "NVIDIA GPU without nvidia-utils: install its driver, reboot, then re-run"
        fi
        ;;
    esac
  done
  (( extras )) && pkgs+=(gamescope mangohud lib32-mangohud protontricks)

  log "Steam packages: ${pkgs[*]}"
  (( yes )) || prompt_step "Install them" || return 0
  pacman_install "${pkgs[@]}"
  log "Launch Steam once, then Settings > Compatibility > enable Steam Play for all titles"
}

main "$@"
