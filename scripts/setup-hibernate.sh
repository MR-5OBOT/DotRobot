#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Disk swap supplies a hibernation target and a lower-priority memory fallback.
# Only configure layouts that this script can verify: ext4 with mkinitcpio and
# GRUB and/or a UKI using /etc/kernel/cmdline. Unsupported layouts are skipped.
# Laptops additionally get suspend-then-hibernate on lid close; desktops keep
# their existing lid/sleep policy.

SWAPFILE="/swapfile"
HIBERNATE_DELAY="30min"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
KERNEL_CMDLINE="/etc/kernel/cmdline"
GRUB_DEFAULT="/etc/default/grub"
LOGIND_DROPIN="/etc/systemd/logind.conf.d/10-lid-hibernate.conf"
SLEEP_DROPIN="/etc/systemd/sleep.conf.d/10-hibernate-delay.conf"
MEMINFO="/proc/meminfo"
SWAPS="/proc/swaps"
FSTAB="/etc/fstab"
POWER_STATE="/sys/power/state"
LOCKDOWN="/sys/kernel/security/lockdown"
POWER_SUPPLIES="/sys/class/power_supply"
MKINITCPIO_DROPINS="/etc/mkinitcpio.conf.d"
PRESET_DIR="/etc/mkinitcpio.d"
GRUB_CONFIG="/boot/grub/grub.cfg"

# Set by the steps below rather than printed, because log() writes to stdout.
RESUME_ARGS=""
REBUILD_INITRAMFS=0
UPDATE_UKI=0
UPDATE_GRUB=0
HAS_BATTERY=0
SWAP_SIZE_G=0
HOOKS_LIST=()

skip() {
  warn "Skipping hibernation setup: $*"
  return 1
}

preflight() {
  local ram_kib required_bytes free_bytes filesystem type preset hook_line
  if systemd-detect-virt --container --quiet; then
    skip "containers cannot configure host hibernation."; return 1
  fi
  if [[ ! -r ${POWER_STATE} ]] || ! grep -qw disk "${POWER_STATE}"; then
    skip "the running kernel does not expose hibernation support."; return 1
  fi
  if [[ -r ${LOCKDOWN} ]] && ! grep -q '\[none\]' "${LOCKDOWN}"; then
    skip "kernel lockdown blocks hibernation; leaving Secure Boot settings alone."; return 1
  fi
  filesystem=$(findmnt -no FSTYPE -T "$(dirname "${SWAPFILE}")")
  if [[ ${filesystem} != ext4 ]]; then
    skip "${filesystem} needs a filesystem-specific swap/resume setup; automatic setup currently supports ext4."; return 1
  fi
  if ! command -v mkinitcpio >/dev/null || [[ ! -r ${MKINITCPIO_CONF} ]]; then
    skip "mkinitcpio is not configured on this machine."; return 1
  fi
  for type in "${MKINITCPIO_DROPINS}"/*.conf; do
    if [[ -f ${type} ]] && grep -qE '^[[:space:]]*HOOKS[+]?=' "${type}"; then
      skip "${type} overrides HOOKS; configure resume in that custom initramfs setup."; return 1
    fi
  done
  hook_line=$(grep -E '^[[:space:]]*HOOKS=\([^)]*\)[[:space:]]*(#.*)?$' "${MKINITCPIO_CONF}" || true)
  if [[ -z ${hook_line} || ${hook_line} == *$'\n'* \
      || $(grep -cE '^[[:space:]]*HOOKS[+]?=' "${MKINITCPIO_CONF}") != 1 ]]; then
    skip "the custom mkinitcpio HOOKS layout cannot be edited automatically."; return 1
  fi
  read -r -a HOOKS_LIST <<< "$(printf '%s\n' "${hook_line}" | sed -E 's/^[^(]*\(([^)]*)\).*$/\1/' | tr "\"'" '  ')"
  if [[ " ${HOOKS_LIST[*]} " != *' filesystems '* ]]; then
    skip "mkinitcpio has no filesystems hook to place resume before."; return 1
  fi
  for type in "${HOOKS_LIST[@]}"; do
    if [[ ! ${type} =~ ^[a-zA-Z0-9_-]+$ ]]; then
      skip "computed mkinitcpio hooks need manual configuration."; return 1
    fi
  done

  UPDATE_UKI=0
  UPDATE_GRUB=0
  local found_preset=0
  for preset in "${PRESET_DIR}"/*.preset; do
    [[ -f ${preset} ]] || continue
    found_preset=1
    if grep -qE '^[[:space:]]*[[:alnum:]_]+_(config|cmdline)=' "${preset}"; then
      skip "${preset} selects custom initramfs/cmdline files; configure resume there."; return 1
    fi
    if grep -qE '^[[:space:]]*[[:alnum:]_]+_options=.*(--cmdline|--no-cmdline|--config)' "${preset}"; then
      skip "${preset} overrides initramfs/cmdline handling in its options."; return 1
    fi
    if grep -qE '^[[:space:]]*[[:alnum:]_]+_uki=' "${preset}"; then
      UPDATE_UKI=1
    fi
  done
  if (( ! found_preset )); then
    skip "no mkinitcpio kernel presets were found."; return 1
  fi
  if (( UPDATE_UKI )) && [[ ! -s ${KERNEL_CMDLINE} ]]; then
    skip "the UKI needs an existing ${KERNEL_CMDLINE}."; return 1
  fi
  if (( UPDATE_UKI )) && [[ $(grep -cvE '^[[:space:]]*(#|$)' "${KERNEL_CMDLINE}") != 1 ]]; then
    skip "the UKI command line must contain exactly one non-comment line."; return 1
  fi
  if [[ -f ${GRUB_DEFAULT} && -f ${GRUB_CONFIG} ]] && command -v grub-mkconfig >/dev/null; then
    if [[ $(grep -c '^GRUB_CMDLINE_LINUX_DEFAULT=' "${GRUB_DEFAULT}") != 1 ]] \
        || ! grep -qE '^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*"[[:space:]]*$' "${GRUB_DEFAULT}"; then
      skip "the custom GRUB command-line format cannot be edited automatically."; return 1
    fi
    UPDATE_GRUB=1
  fi
  if (( ! UPDATE_UKI && ! UPDATE_GRUB )); then
    skip "no supported GRUB or mkinitcpio UKI boot configuration was found."; return 1
  fi
  if awk -v target="${SWAPFILE}" 'NR > 1 && $1 != target && $1 !~ /\/zram[0-9]+$/ {found=1} END {exit !found}' "${SWAPS}"; then
    skip "another disk swap area already exists; preserve it and configure resume for that layout."; return 1
  fi
  if awk -v target="${SWAPFILE}" '$1 !~ /^#/ && $3 == "swap" && $1 != target && $1 !~ /\/zram[0-9]+$/ {found=1} END {exit !found}' "${FSTAB}"; then
    skip "another swap area is configured in fstab, even if inactive; preserve that layout."; return 1
  fi

  ram_kib=$(awk '/^MemTotal:/ {print $2}' "${MEMINFO}")
  [[ ${ram_kib} =~ ^[0-9]+$ && ${ram_kib} -gt 0 ]] || die "Cannot read usable RAM."
  # Round up to a whole GiB, always leaving some space above usable RAM.
  SWAP_SIZE_G=$(( ram_kib / 1024 / 1024 + 1 ))
  required_bytes=$(( SWAP_SIZE_G * 1024 * 1024 * 1024 ))
  if [[ -L ${SWAPFILE} || ( -e ${SWAPFILE} && ! -f ${SWAPFILE} ) ]]; then
    skip "${SWAPFILE} is not a regular, non-symlink file."; return 1
  elif [[ -f ${SWAPFILE} ]]; then
    if (( $(stat -c %s "${SWAPFILE}") < required_bytes )); then
      skip "${SWAPFILE} is smaller than the ${SWAP_SIZE_G} GiB target; it will not be resized or reformatted automatically."; return 1
    fi
    log "Reusing ${SWAPFILE}; its size meets the ${SWAP_SIZE_G} GiB target."
  else
    free_bytes=$(df -B1 --output=avail "$(dirname "${SWAPFILE}")" | awk 'NR == 2 {print $1}')
    if [[ ! ${free_bytes} =~ ^[0-9]+$ ]] || (( free_bytes < required_bytes + 2 * 1024 * 1024 * 1024 )); then
      skip "creating ${SWAP_SIZE_G} GiB of swap would leave less than 2 GiB free on the filesystem."; return 1
    fi
    log "Disk space is sufficient for ${SWAP_SIZE_G} GiB of swap plus 2 GiB left free."
  fi
  HAS_BATTERY=0
  for type in "${POWER_SUPPLIES}"/*/type; do
    if [[ -r ${type} ]] && [[ $(<"${type}") == Battery ]]; then
      HAS_BATTERY=1
    fi
  done
  log "Supported ext4 layout; UKI=${UPDATE_UKI}, GRUB=${UPDATE_GRUB}, battery=${HAS_BATTERY}."
}

setup_swapfile() {
  if [[ -f "${SWAPFILE}" ]]; then
    [[ $(sudo blkid -p -s TYPE -o value "${SWAPFILE}") == swap ]] \
      || die "${SWAPFILE} has no swap signature; refusing to reformat it."
    log "Already have ${SWAPFILE}"
  else
    log "Creating ${SWAP_SIZE_G}G ${SWAPFILE}"
    sudo mkswap -U clear --size "${SWAP_SIZE_G}G" --file "${SWAPFILE}" >/dev/null
  fi

  # Verify that the file can be activated before making its fstab entry permanent.
  swapon --show=NAME --noheadings | grep -qx "${SWAPFILE}" || sudo swapon -p 0 "${SWAPFILE}"
  if ! awk -v target="${SWAPFILE}" '$1 == target {found=1} END {exit !found}' "${FSTAB}"; then
    printf '%s none swap defaults,pri=0 0 0\n' "${SWAPFILE}" | sudo tee -a "${FSTAB}" >/dev/null
    log "Added ${SWAPFILE} to /etc/fstab"
  fi
}

find_resume_args() {
  local root_uuid offset page_size extent_map
  root_uuid="$(findmnt -no UUID -T "${SWAPFILE}")"
  page_size=$(getconf PAGESIZE)
  [[ ${page_size} =~ ^[0-9]+$ && ${page_size} -gt 0 ]] || die "Cannot read the memory page size."
  # resume_offset is measured in memory pages, not filesystem blocks.
  # filefrag's optional -b argument must be attached: -b4096, not -b 4096.
  extent_map=$(sudo filefrag "-b${page_size}" -v "${SWAPFILE}") \
    || die "Cannot map ${SWAPFILE}; resume configuration was not changed."
  offset="$(awk '$1 == "0:" { sub(/\.\.$/, "", $4); print $4 }' <<< "${extent_map}")"
  [[ ${root_uuid} =~ ^[a-fA-F0-9-]+$ && ${offset} =~ ^[0-9]+$ ]] || die "Could not work out resume device/offset"
  RESUME_ARGS="resume=UUID=${root_uuid} resume_offset=${offset}"
}

setup_resume_hook() {
  if [[ " ${HOOKS_LIST[*]} " == *' systemd '* ]]; then
    log "The systemd initramfs already provides resume support."
    return 0
  fi
  local hook hooks=()
  for hook in "${HOOKS_LIST[@]}"; do
    [[ ${hook} == resume ]] && continue
    [[ ${hook} == filesystems ]] && hooks+=(resume)
    hooks+=("${hook}")
  done
  [[ ${hooks[*]} == "${HOOKS_LIST[*]}" ]] && return 0
  # Resume follows device/unlock hooks and precedes mounting the filesystem.
  sudo sed -i -E "s/^[[:space:]]*HOOKS=.*/HOOKS=(${hooks[*]})/" "${MKINITCPIO_CONF}"
  log "Placed resume before filesystems in ${MKINITCPIO_CONF}"
  REBUILD_INITRAMFS=1
}

setup_uki_cmdline() {
  (( UPDATE_UKI )) || return 0
  if grep -vE '^[[:space:]]*(#|$)' "${KERNEL_CMDLINE}" | grep -qF "${RESUME_ARGS}"; then
    log "${KERNEL_CMDLINE} already has ${RESUME_ARGS}"
    return 0
  fi
  # Drop any stale resume args first, then append the current ones.
  sudo sed -i -E "/^[[:space:]]*(#|\$)/! { s/(^|[[:space:]])resume(_offset)?=[^[:space:]]+//g; s/[[:space:]]*\$/ ${RESUME_ARGS}/; }" "${KERNEL_CMDLINE}"
  log "Added ${RESUME_ARGS} to ${KERNEL_CMDLINE}"
  REBUILD_INITRAMFS=1
}

setup_grub() {
  (( UPDATE_GRUB )) || return 0
  if grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "${GRUB_DEFAULT}" | grep -qF "${RESUME_ARGS}"; then
    log "GRUB already has ${RESUME_ARGS}"
    return 0
  fi
  sudo sed -i -E \
    -e '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/([ "])resume(_offset)?=[^ "]+/\1/g' \
    -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/[[:space:]]*\"[[:space:]]*\$/ ${RESUME_ARGS}\"/" \
    "${GRUB_DEFAULT}"
  log "Added ${RESUME_ARGS} to GRUB, regenerating config"
  sudo grub-mkconfig -o "${GRUB_CONFIG}"
}

setup_logind() {
  if (( ! HAS_BATTERY )); then
    log "No battery detected; keeping the desktop's existing sleep/lid policy."
    return 0
  fi
  sudo install -Dm 644 /dev/stdin "${LOGIND_DROPIN}" <<'EOF'
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend
EOF
  sudo install -Dm 644 /dev/stdin "${SLEEP_DROPIN}" <<EOF
[Sleep]
HibernateDelaySec=${HIBERNATE_DELAY}
EOF
  log "Installed ${LOGIND_DROPIN} and ${SLEEP_DROPIN}"
  # logind reads its config only at start; a reload keeps the session alive.
  sudo systemctl kill -s HUP systemd-logind
}

main() {
  case "${1:-}" in
    ""|--check) ;;
    *) die "Usage: $0 [--check]" ;;
  esac
  require_arch
  preflight || return 0
  [[ ${1:-} == --check ]] && { log "Check complete; no system settings changed."; return 0; }
  [[ $EUID -eq 0 ]] && die "Run as your normal user; the script uses sudo when needed."

  local backup_dir config
  backup_dir=$(sudo mktemp -d /var/tmp/dotrobot-hibernate-backup.XXXXXX)
  for config in "${FSTAB}" "${MKINITCPIO_CONF}" "${KERNEL_CMDLINE}" "${GRUB_DEFAULT}" "${LOGIND_DROPIN}" "${SLEEP_DROPIN}"; do
    [[ -f ${config} ]] && sudo cp --parents -a "${config}" "${backup_dir}/"
  done
  log "Saved existing configuration in ${backup_dir}."

  setup_swapfile
  find_resume_args
  setup_resume_hook
  setup_uki_cmdline
  setup_grub
  if (( REBUILD_INITRAMFS )); then
    log "Rebuilding initramfs/UKI"
    sudo mkinitcpio -P
  fi
  setup_logind

  log "Hibernate set up. Reboot, then test once with: systemctl hibernate"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
