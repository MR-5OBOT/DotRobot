#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Dual boot: list Windows (or any other OS) in the GRUB menu. grub-mkconfig
# only adds other systems by running os-prober, which Arch does not install by
# default and GRUB 2.06+ disables in /etc/default/grub.
#
# os-prober mounts partitions itself, so a Windows bootloader on its own EFI
# partition is found without mounting it.

GRUB_DEFAULT="/etc/default/grub"

setup_os_prober_flag() {
  if grep -qx 'GRUB_DISABLE_OS_PROBER=false' "${GRUB_DEFAULT}"; then
    log "os-prober already enabled in ${GRUB_DEFAULT}"
    return 0
  fi
  if grep -q '^GRUB_DISABLE_OS_PROBER=' "${GRUB_DEFAULT}"; then
    sudo sed -i 's/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' "${GRUB_DEFAULT}"
  else
    # The stock file only has it commented out; leave that note in place.
    printf 'GRUB_DISABLE_OS_PROBER=false\n' | sudo tee -a "${GRUB_DEFAULT}" >/dev/null
  fi
  log "Enabled os-prober in ${GRUB_DEFAULT}"
}

main() {
  require_arch
  [[ $EUID -eq 0 ]] && die "Run as your normal user; the script uses sudo when needed."
  if [[ ! -f "${GRUB_DEFAULT}" ]]; then
    log "No ${GRUB_DEFAULT}; os-prober only feeds GRUB, skipping"
    return 0
  fi

  sudo pacman -S --needed --noconfirm os-prober
  setup_os_prober_flag
  log "Regenerating GRUB config; look for a \"Found Windows Boot Manager\" line"
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  # BitLocker's TPM unlock is tied to the boot path, and GRUB is a new one.
  log "Done. If Windows uses BitLocker, have the recovery key ready: https://aka.ms/myrecoverykey"
}

main "$@"
