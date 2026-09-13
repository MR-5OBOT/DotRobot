#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Lid close = suspend-then-hibernate. Modern laptops often only offer s2idle,
# which drains a full battery overnight; after HIBERNATE_DELAY on battery the
# system wakes, writes RAM to /swapfile and powers off.
#
# zram stays the everyday swap (higher priority); /swapfile only exists so
# there is somewhere on disk to hibernate to. Assumes ext4 root. Resume args
# go to /etc/kernel/cmdline (UKI, embedded at build time) and /etc/default/grub
# (plain GRUB entries), whichever exist - archinstall's GRUB setups can boot a
# UKI that ignores /etc/default/grub entirely.

SWAPFILE="/swapfile"
HIBERNATE_DELAY="30min"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
KERNEL_CMDLINE="/etc/kernel/cmdline"
GRUB_DEFAULT="/etc/default/grub"
LOGIND_DROPIN="/etc/systemd/logind.conf.d/10-lid-hibernate.conf"
SLEEP_DROPIN="/etc/systemd/sleep.conf.d/10-hibernate-delay.conf"

# Set by the steps below rather than printed, because log() writes to stdout.
RESUME_ARGS=""
REBUILD_INITRAMFS=0

setup_swapfile() {
  if [[ -f "${SWAPFILE}" ]]; then
    log "Already have ${SWAPFILE}"
  else
    # Hibernation image is compressed, but RAM + 1G leaves room for a full one.
    local size_g=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 + 1 ))
    log "Creating ${size_g}G ${SWAPFILE}"
    sudo mkswap -U clear --size "${size_g}G" --file "${SWAPFILE}" >/dev/null
  fi

  if ! grep -qE "^\s*${SWAPFILE}\s" /etc/fstab; then
    printf '%s none swap defaults,pri=0 0 0\n' "${SWAPFILE}" | sudo tee -a /etc/fstab >/dev/null
    log "Added ${SWAPFILE} to /etc/fstab"
  fi
  swapon --show=NAME --noheadings | grep -qx "${SWAPFILE}" || sudo swapon -p 0 "${SWAPFILE}"
}

find_resume_args() {
  local root_uuid offset
  root_uuid="$(findmnt -no UUID -T "${SWAPFILE}")"
  offset="$(sudo filefrag -v "${SWAPFILE}" | awk '$1 == "0:" { sub(/\.\.$/, "", $4); print $4 }')"
  [[ -n "${root_uuid}" && -n "${offset}" ]] || die "Could not work out resume device/offset"
  RESUME_ARGS="resume=UUID=${root_uuid} resume_offset=${offset}"
}

setup_resume_hook() {
  if grep -qE '^HOOKS=\(.*\bresume\b' "${MKINITCPIO_CONF}"; then
    log "resume hook already in ${MKINITCPIO_CONF}"
    return 0
  fi
  grep -qE '^HOOKS=\(.*\bfilesystems\b' "${MKINITCPIO_CONF}" \
    || die "No filesystems hook in ${MKINITCPIO_CONF}; add resume before it by hand"
  # Resume must run before the root filesystem is mounted.
  sudo sed -i -E '/^HOOKS=\(/ s/\bfilesystems\b/resume filesystems/' "${MKINITCPIO_CONF}"
  log "Added resume hook to ${MKINITCPIO_CONF}"
  REBUILD_INITRAMFS=1
}

setup_uki_cmdline() {
  [[ -f "${KERNEL_CMDLINE}" ]] || return 0
  if grep -qF "${RESUME_ARGS}" "${KERNEL_CMDLINE}"; then
    log "${KERNEL_CMDLINE} already has ${RESUME_ARGS}"
    return 0
  fi
  # Drop any stale resume args first, then append the current ones.
  sudo sed -i -E -e 's/ ?resume(_offset)?=[^ ]*//g' -e "1 s/\$/ ${RESUME_ARGS}/" "${KERNEL_CMDLINE}"
  log "Added ${RESUME_ARGS} to ${KERNEL_CMDLINE}"
  REBUILD_INITRAMFS=1
}

setup_grub() {
  [[ -f "${GRUB_DEFAULT}" ]] || return 0
  if grep -qF "${RESUME_ARGS}" "${GRUB_DEFAULT}"; then
    log "GRUB already has ${RESUME_ARGS}"
    return 0
  fi
  sudo sed -i -E \
    -e '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/ ?resume(_offset)?=[^ "]*//g' \
    -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"\$/ ${RESUME_ARGS}\"/" \
    "${GRUB_DEFAULT}"
  log "Added ${RESUME_ARGS} to GRUB, regenerating config"
  sudo grub-mkconfig -o /boot/grub/grub.cfg
}

setup_logind() {
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
  require_arch
  [[ $EUID -eq 0 ]] && die "Run as your normal user; the script uses sudo when needed."
  [[ "$(findmnt -no FSTYPE /)" == ext4 ]] || die "Only ext4 root is handled (swapfile offset differs on btrfs)"
  [[ -f "${KERNEL_CMDLINE}" || -f "${GRUB_DEFAULT}" ]] \
    || die "No ${KERNEL_CMDLINE} or ${GRUB_DEFAULT}; add resume args to your bootloader by hand"

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

main "$@"
