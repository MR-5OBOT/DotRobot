#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ZRAM_CONF="/etc/systemd/zram-generator.conf"
TEMPLATE="${PACKAGES_DIR}/zram-generator.conf"
SYSCTL_CONF="/etc/sysctl.d/99-zram.conf"
SYSCTL_TEMPLATE="${PACKAGES_DIR}/99-zram.conf"
MEMINFO="/proc/meminfo"
SWAPS="/proc/swaps"
CMDLINE="/proc/cmdline"
ZRAM_SYS="/sys/block/zram0"
ZRAM_MODULE="/sys/module/zram"

preflight() {
  if systemd-detect-virt --container --quiet; then
    warn "Skipping zram: containers share the host kernel and memory policy."
    return 1
  fi
  if grep -qE '(^|[[:space:]])systemd.zram=(0|no|false|off)($|[[:space:]])' "${CMDLINE}"; then
    warn "Skipping zram: it is disabled on the kernel command line."
    return 1
  fi
  RAM_KIB=$(awk '/^MemTotal:/ {print $2}' "${MEMINFO}")
  [[ ${RAM_KIB} =~ ^[0-9]+$ && ${RAM_KIB} -gt 0 ]] || die "Cannot read usable RAM."
  local target_mib=$(( RAM_KIB / 1024 / 2 ))
  (( target_mib > 8192 )) && target_mib=8192
  log "Usable RAM: $(( RAM_KIB / 1024 )) MiB; zram target: about ${target_mib} MiB (half RAM, maximum 8 GiB)."

  if [[ ! -d ${ZRAM_MODULE} ]] && ! modinfo zram >/dev/null 2>&1; then
    warn "Skipping zram: the running kernel has no available zram driver."
    return 1
  fi
  if awk 'NR > 1 && $1 ~ /\/zram[0-9]+$/ {found=1} END {exit !found}' "${SWAPS}" \
      && ! systemctl is-active --quiet systemd-zram-setup@zram0.service; then
    warn "Skipping zram: an existing device is managed outside zram-generator."
    return 1
  fi
  for manager in zramswap.service zram-swap.service; do
    if systemctl is-active --quiet "${manager}"; then
      warn "Skipping zram: ${manager} is already managing it."
      return 1
    fi
  done
  log "Compression: zstd when exposed by the kernel; otherwise the kernel default."
}

configure_zram() {
  local config active=0
  awk '$1 == "/dev/zram0" {found=1} END {exit !found}' "${SWAPS}" && active=1
  sudo modprobe zram
  config=$(mktemp)
  cp "${TEMPLATE}" "${config}"
  if [[ ! -r ${ZRAM_SYS}/comp_algorithm ]] || ! tr '[]' '  ' < "${ZRAM_SYS}/comp_algorithm" | grep -qw zstd; then
    sed -i '/^compression-algorithm[[:space:]]*=/d' "${config}"
    log "Using the kernel's supported default compression algorithm."
  fi
  sudo install -Dm 644 "${config}" "${ZRAM_CONF}"
  rm -f "${config}"
  sudo systemctl daemon-reload
  if (( active )); then
    log "Kept active zram running; size/compression changes take effect on the next boot."
  else
    sudo systemctl start dev-zram0.swap
    log "Started zram swap."
  fi

  sudo install -Dm 644 "${SYSCTL_TEMPLATE}" "${SYSCTL_CONF}"
  sudo sysctl -p "${SYSCTL_CONF}"
  log "Installed the zram configuration and its two swap settings."
}

main() {
  case "${1:-}" in
    ""|--check) ;;
    *) die "Usage: $0 [--check]" ;;
  esac
  require_arch
  [[ -r "${TEMPLATE}" ]] || die "Missing template: ${TEMPLATE}"
  [[ -r "${SYSCTL_TEMPLATE}" ]] || die "Missing template: ${SYSCTL_TEMPLATE}"
  preflight || return 0
  [[ ${1:-} == --check ]] && { log "Check complete; no system settings changed."; return 0; }
  pacman -Qq zram-generator >/dev/null 2>&1 || sudo pacman -Syu --needed --noconfirm zram-generator
  configure_zram
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
