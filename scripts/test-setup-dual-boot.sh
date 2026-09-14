#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup-dual-boot.sh"
log() { :; }
sudo() { "$@"; }

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
GRUB_DEFAULT="${tmp_dir}/grub"

printf 'GRUB_DISABLE_OS_PROBER=true\n' >"${GRUB_DEFAULT}"
setup_os_prober_flag
printf 'GRUB_DISABLE_OS_PROBER=true\nchanged\n' >"${GRUB_DEFAULT}"
setup_os_prober_flag

[[ "$(<"${GRUB_DEFAULT}.dotrobot.bak")" == "GRUB_DISABLE_OS_PROBER=true" ]]
grep -qx 'GRUB_DISABLE_OS_PROBER=false' "${GRUB_DEFAULT}"

printf 'setup-dual-boot tests passed\n'
