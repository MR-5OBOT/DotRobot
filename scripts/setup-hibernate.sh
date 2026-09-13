#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Lid close = suspend-then-hibernate. Modern laptops often only offer s2idle,
# which drains a full battery overnight; after HIBERNATE_DELAY on battery the
# system wakes, writes RAM to /swapfile and powers off.
#
# zram stays the everyday swap (higher priority); /swapfile only exists so
# there is somewhere on disk to hibernate to. Assumes ext4 root + GRUB.

SWAPFILE="/swapfile"
HIBERNATE_DELAY="30min"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
GRUB_DEFAULT="/etc/default/grub"
LOGIND_DROPIN="/etc/systemd/logind.conf.d/10-lid-hibernate.conf"
SLEEP_DROPIN="/etc/systemd/sleep.conf.d/10-hibernate-delay.conf"

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

setup_initramfs() {
  if grep -qE '^HOOKS=\(.*\bresume\b' "${MKINITCPIO_CONF}"; then
    log "resume hook already in ${MKINITCPIO_CONF}"
    return 0
  fi
  grep -qE '^HOOKS=\(.*\bfilesystems\b' "${MKINITCPIO_CONF}" \
    || die "No filesystems hook in ${MKINITCPIO_CONF}; add resume before it by hand"
  # Resume must run before the root filesystem is mounted.
  sudo sed -i -E '/^HOOKS=\(/ s/\bfilesystems\b/resume filesystems/' "${MKINITCPIO_CONF}"
  log "Added resume hook, rebuilding initramfs"
  sudo mkinitcpio -P
}

setup_grub() {
  local root_uuid offset args
  root_uuid="$(findmnt -no UUID -T "${SWAPFILE}")"
  offset="$(sudo filefrag -v "${SWAPFILE}" | awk '$1 == "0:" { sub(/\.\.$/, "", $4); print $4 }')"
  [[ -n "${root_uuid}" && -n "${offset}" ]] || die "Could not work out resume device/offset"
  args="resume=UUID=${root_uuid} resume_offset=${offset}"

  if grep -qF "${args}" "${GRUB_DEFAULT}"; then
    log "GRUB already has ${args}"
    return 0
  fi
  # Drop any stale resume args first, then append the current ones.
  sudo sed -i -E \
    -e '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/ ?resume(_offset)?=[^ "]*//g' \
    -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"\$/ ${args}\"/" \
    "${GRUB_DEFAULT}"
  log "Added ${args} to GRUB, regenerating config"
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
  [[ -f "${GRUB_DEFAULT}" ]] || die "Only GRUB is handled"

  setup_swapfile
  setup_initramfs
  setup_grub
  setup_logind

  log "Hibernate set up. Reboot, then test once with: systemctl hibernate"
}

main "$@"
