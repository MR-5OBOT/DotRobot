#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dotfiles/.local/bin/dell-sleep-power-drain-fix"
sudo() { "$@"; }
mkinitcpio() {
  echo "$*" >>"${LOG}"
  if [[ $1 == -U ]]; then
    cp "$4" "${LOG}.cmdline"
    cp "$6" "${LOG}.osrel"
    : >"$2"
  fi
}
# A real sleep adds its hardware-sleep time to the running total; FAKE_SUSPEND_FAIL refuses it.
rtcwake() {
  local total="${DELL_SLEEP_FIX_ROOT}/sys/power/suspend_stats/total_hw_sleep"
  [[ ${FAKE_SUSPEND_FAIL:-0} == 0 ]] || return 1
  echo $(($(<"${total}") + FAKE_HW_SLEEP)) >"${total}"
}
journalctl() { :; }
export -f sudo mkinitcpio rtcwake journalctl
export DELL_SLEEP_FIX_ROOT="${tmp}/root" XDG_STATE_HOME="${tmp}/state" LOG="${tmp}/log"
r=${DELL_SLEEP_FIX_ROOT}
entry="${r}/efi/EFI/Linux/arch-linux-ssdtest.efi"
mkdir -p "${r}/etc/kernel" "${r}/etc/mkinitcpio.d" "${r}/proc" "${r}/sys/power/suspend_stats" "${r}/efi/EFI/Linux"
printf 'default_uki="/efi/EFI/Linux/arch-linux.efi"\n' >"${r}/etc/mkinitcpio.d/linux.preset"
printf 'NAME="Arch Linux"\nPRETTY_NAME="Arch Linux"\n' >"${r}/etc/os-release"
# A good sleep earlier this boot: the test must look at this sleep, not the total so far.
echo 5000000 >"${r}/sys/power/suspend_stats/total_hw_sleep"
base='root=PARTUUID=abcd rw resume=UUID=ef01 resume_offset=42'
printf '%s\n' "${base}" >"${r}/etc/kernel/cmdline"
printf '%s\n' "${base}" >"${r}/proc/cmdline"
run() { bash "${script}" "$@"; }
refused() { if run "$@" >/dev/null 2>&1; then echo "accepted: $*" >&2 && exit 1; fi; }
builds() { grep -cx -- "$1" "${LOG}" || true; }

# No passed test yet: on is refused and the boot line stays untouched.
refused on
[[ $(<"${r}/etc/kernel/cmdline") == "${base}" ]]

# Stock kernel, broken sleep: test builds the one-boot entry beside the preset's UKI.
export FAKE_HW_SLEEP=0
run test >/dev/null
[[ -e ${entry} ]]
[[ $(<"${LOG}.cmdline") == "${base} pcie_aspm=force" ]]
grep -q 'PRETTY_NAME="Arch Linux (SSD power test)"' "${LOG}.osrel"
[[ $(<"${r}/etc/kernel/cmdline") == "${base}" ]]

# Test kernel, suspend refused: not blamed on the fix, nothing recorded.
printf '%s\n' "${base} pcie_aspm=force" >"${r}/proc/cmdline"
out=$(FAKE_SUSPEND_FAIL=1 run test 2>&1 || true)
[[ ${out} == *"run test again"* && ${out} != *FAIL:* ]]
refused on

# Test kernel, still broken: fail, no pass recorded; purge deletes the entry without a rebuild.
refused test
refused on
run purge >/dev/null
[[ ! -e ${entry} ]]
[[ $(<"${r}/etc/kernel/cmdline") == "${base}" ]]
[[ $(builds -P) -eq 0 ]]

# Test kernel, sleep works: pass unlocks on, which removes the test entry; on/off are idempotent.
export FAKE_HW_SLEEP=25000000
[[ $(run test) == *PASS* ]]
: >"${entry}"
run on >/dev/null
run on >/dev/null
[[ $(<"${r}/etc/kernel/cmdline") == "${base} pcie_aspm=force" ]]
[[ ! -e ${entry} ]]

# Fix on but not rebooted yet: test says reboot and builds nothing.
printf '%s\n' "${base}" >"${r}/proc/cmdline"
: >"${LOG}"
out=$(run test 2>&1 || true)
[[ ${out} == *reboot* ]]
[[ ! -s ${LOG} ]]

run off >/dev/null
run off >/dev/null
[[ $(<"${r}/etc/kernel/cmdline") == "${base}" ]]
[[ $(builds -P) -eq 1 ]]

# Purge with the fix on: boot line back to stock, test result gone, on locked again.
run on >/dev/null
run purge >/dev/null
[[ $(<"${r}/etc/kernel/cmdline") == "${base}" ]]
[[ ! -e ${XDG_STATE_HOME}/dell-sleep-power-drain-fix.passed ]]
[[ $(builds -P) -eq 3 ]]
refused on

# Stock kernel where sleep already works: nothing is built.
: >"${LOG}"
[[ $(run test) == *"no fix needed"* ]]
[[ ! -s ${LOG} ]]

# Never writes a boot line without root=, even with a passed test.
: >"${XDG_STATE_HOME}/dell-sleep-power-drain-fix.passed"
printf 'rw quiet\n' >"${r}/etc/kernel/cmdline"
refused on
[[ $(<"${r}/etc/kernel/cmdline") == 'rw quiet' ]]

printf 'dell-sleep-power-drain-fix tests passed\n'
