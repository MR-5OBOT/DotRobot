#!/usr/bin/env bash
# Uses nmcli offline; package installation, services and modem operations are mocked.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_STATE="$(mktemp -d)"
trap 'rm -rf "${TEST_STATE}"' EXIT
export XDG_STATE_HOME="${TEST_STATE}/state"
source "${SCRIPT_DIR}/setup-mobile-broadband.sh"
SYS_CLASS="${TEST_STATE}/sys"
require_arch() { :; }
pacman() { return "${PACKAGES_MISSING:-0}"; }
nmcli() {
  [[ "$*" == '-g connection.type connection show id Existing' ]] || return 1
  printf 'gsm\n'
}
mmcli() {
  if [[ "$*" == -L ]]; then
    if [[ -f "${TEST_STATE}/reprobe" ]]; then
      local polls
      polls="$(cat "${TEST_STATE}/reprobe")"
      if ((polls < 2)); then
        printf '%s' "$((polls+1))" > "${TEST_STATE}/reprobe"
        return 0
      fi
    fi
    if [[ "${NO_MODEM:-0}" != 1 ]]; then
      printf '    /org/freedesktop/ModemManager1/Modem/%s [Fibocom] FM101R-GL\n' "$(cat "${TEST_STATE}/modem-index" 2>/dev/null || printf 0)"
      [[ "${MULTIPLE_MODEMS:-0}" != 1 ]] || printf '    /org/freedesktop/ModemManager1/Modem/9 [Other] Modem\n'
    fi
    return 0
  fi
  [[ "$*" == *' -K' ]] || return 1
  printf 'modem.generic.primary-port : %s\n' "${MODEM_CONTROL:-cdc-wdm0}"
  printf 'modem.generic.ports.value[1] : cdc-wdm0 (%s)\n' "${MODEM_PROTOCOL:-mbim}"
  printf 'modem.generic.primary-sim-slot : %s\n' "$(cat "${TEST_STATE}/sim-slot" 2>/dev/null || printf 2)"
  printf 'modem.generic.sim-slots.length : 2\n'
  printf 'modem.generic.sim-slots.value[1] : /\nmodem.generic.sim-slots.value[2] : /\n'
  # Reproduce the empty-eSIM bug: an apparently valid SIM object without an ICCID.
  printf 'modem.generic.sim : %s\n' "${SIM_PATH:-/org/freedesktop/ModemManager1/SIM/1}"
}
sleep() { :; }
makepkg() {
  [[ -f PKGBUILD && -f arch.patch ]]
  printf 'makepkg %s\n' "$*" >> "${TEST_STATE}/actions"
}
sudo() {
  printf '%q ' "$@" >> "${TEST_STATE}/actions"
  printf '\n' >> "${TEST_STATE}/actions"
  if [[ "${CONNECT_FAIL:-0}" == 1 && "$1 $2 ${3:-}" == 'nmcli --ask connection' ]]; then
    return 1
  fi
  if [[ "$1 $2 ${3:-}" == 'nmcli connection add' ]]; then
    command nmcli --offline "${@:2}" > "${TEST_STATE}/profile"
  elif [[ "$1 $2 ${3:-}" == 'env LC_ALL=C mbimcli' ]]; then
    printf "Hardware radio state: '%s'\n" "${RADIO_HARDWARE:-on}"
  elif [[ "$*" == *'--query-subscriber-ready-status' ]]; then
    printf "Ready state: '%s'\n" "${SIM_READY:-initialized}"
  elif [[ "$1" == mmcli && "$*" == *'--set-primary-sim-slot='* ]]; then
    printf '%s' "${4#*=}" > "${TEST_STATE}/sim-slot"
    printf '1' > "${TEST_STATE}/modem-index"
    printf '0' > "${TEST_STATE}/reprobe"
  fi
}
journalctl() {
  [[ "$*" == *'--since '* ]] || return 1
  printf 'Cannot power-up: hardware radio switch is OFF\n'
}

main </dev/null > /dev/null
[[ ! -e "${TEST_STATE}/actions" ]]
mkdir -p "${SYS_CLASS}/wwan/wwan0mbim0"
detect_modem > /dev/null
mkdir -p "${SYS_CLASS}/usbmisc/cdc-wdm0/usb/interface"
ln -s usb/interface "${SYS_CLASS}/usbmisc/cdc-wdm0/device"
printf '413c\n' > "${SYS_CLASS}/usbmisc/cdc-wdm0/usb/idVendor"
printf 'ffff\n' > "${SYS_CLASS}/usbmisc/cdc-wdm0/usb/idProduct"
setup_fibocom_unlock </dev/null > /dev/null
[[ ! -e "${TEST_STATE}/actions" ]]
printf '8213\n' > "${SYS_CLASS}/usbmisc/cdc-wdm0/usb/idProduct"
setup_fibocom_unlock <<< n > /dev/null
[[ ! -e "${TEST_STATE}/actions" ]]

for entry in '1 www.iamgprs1.ma' '2 www.iamgprs2.ma' '3 internet.orange.ma' '4 www.inwi.ma'; do
  read -r number expected <<< "${entry}"
  choose_carrier <<< "${number}" > /dev/null 2>&1
  [[ "${APN}" == "${expected}" ]]
done
choose_carrier <<< $'invalid\n6' > /dev/null 2>&1
[[ -z "${CARRIER}" ]]

# Fresh-machine flow installs build/runtime support, verifies the radio and saves an offline profile.
PACKAGES_MISSING=1
main <<< $'y\ny\ny\n3\n\n\n\ny\n1' > /dev/null 2>&1
grep -q 'pacman -Syu --needed networkmanager modemmanager' "${TEST_STATE}/actions"
grep -q 'pacman -Syu --needed base-devel curl' "${TEST_STATE}/actions"
grep -q 'makepkg -si --needed' "${TEST_STATE}/actions"
grep -q 'systemctl enable --now fibo_helper.service fibo_helper_mbim.service' "${TEST_STATE}/actions"
grep -q 'timeout 30 /opt/fibocom/fibo_ma_service/fibo_ma' "${TEST_STATE}/actions"
grep -q 'mbimcli --device=/dev/cdc-wdm0 --device-open-proxy --query-radio-state' "${TEST_STATE}/actions"
! grep -q 'fibo_flash\|fibo_config\|radio wwan on\|connection up' "${TEST_STATE}/actions"
for setting in 'apn=internet.orange.ma' 'username=MEDINET' 'autoconnect=false' 'metered=1' 'home-only=true' 'password-flags=2'; do
  grep -qx "${setting}" "${TEST_STATE}/profile"
done
! grep -q '^password=' "${TEST_STATE}/profile"

# Re-running uses the installed package; a zero tool exit cannot hide a still-locked radio.
PACKAGES_MISSING=0
rm "${TEST_STATE}/actions"
setup_fibocom_unlock <<< y > /dev/null
! grep -q 'makepkg\|pacman' "${TEST_STATE}/actions"
RADIO_HARDWARE=off
if (setup_fibocom_unlock <<< y) > "${TEST_STATE}/output" 2>&1; then exit 1; fi
grep -q 'hardware radio is still off' "${TEST_STATE}/output"

# Reusing an existing profile does not rewrite it; connecting needs an explicit choice.
configure_profile <<< $'1\nExisting\ny' > /dev/null 2>&1
[[ "${PROFILE}" == Existing ]]
connect_profile <<< $'2\n2' > /dev/null 2>&1
grep -q 'nmcli --ask connection up id Existing ifname cdc-wdm0' "${TEST_STATE}/actions"
! grep -q 'connection add' "${TEST_STATE}/actions"
CONNECT_FAIL=1
if (connect_profile <<< $'2\n2') > "${TEST_STATE}/output" 2>&1; then exit 1; fi
grep -q 'before reaching carrier authentication' "${TEST_STATE}/output"
journalctl() { return 1; }
if (connect_profile <<< $'2\n2') > "${TEST_STATE}/output" 2>&1; then exit 1; fi
grep -q 'the profile is saved' "${TEST_STATE}/output"

# Empty eSIMs and missing physical SIMs never reach carrier authentication.
CONNECT_FAIL=0
SIM_READY=no-esim-profile
rm "${TEST_STATE}/actions"
connect_profile <<< $'2\ninvalid\n2' > "${TEST_STATE}/output" 2>&1
grep -q 'eSIM with no profile' "${TEST_STATE}/output"
! grep -q 'connection up' "${TEST_STATE}/actions"
SIM_READY=sim-not-inserted
connect_profile <<< $'2\n1' > "${TEST_STATE}/output" 2>&1
grep -q 'SIM is not ready' "${TEST_STATE}/output"
grep -q 'mmcli -m /org/freedesktop/ModemManager1/Modem/0 --set-primary-sim-slot=1' "${TEST_STATE}/actions"
[[ "$(cat "${TEST_STATE}/modem-index")" == 1 ]]
[[ "$(cat "${TEST_STATE}/reprobe")" == 2 ]]
grep -q 'slot 1 = physical SIM tray' "${TEST_STATE}/output"
! grep -q 'connection up' "${TEST_STATE}/actions"
SIM_READY=device-locked
prepare_sim <<< 1 > /dev/null 2>&1
[[ "${MODEM_PORT}" == cdc-wdm0 ]]
MULTIPLE_MODEMS=1
prepare_sim <<< $'invalid\n1\n1' > /dev/null 2>&1
MULTIPLE_MODEMS=0
NO_MODEM=1
if prepare_sim > /dev/null 2>&1; then exit 1; fi
NO_MODEM=0
MODEM_PROTOCOL=qmi
SIM_PATH=--
if prepare_sim <<< 1 > /dev/null 2>&1; then exit 1; fi
MODEM_PROTOCOL=mbim
SIM_READY=initialized
rm "${TEST_STATE}/actions"
connect_profile <<< $'2\n3' > /dev/null 2>&1
! grep -q 'connection up\|set-primary-sim-slot' "${TEST_STATE}/actions"

configure_profile <<< $'5\nCustom SIM\n\nprivate.apn\n\ny' > /dev/null 2>&1
grep -qx 'id=Custom SIM' "${TEST_STATE}/profile"
grep -qx 'apn=private.apn' "${TEST_STATE}/profile"
! grep -q '^username=' "${TEST_STATE}/profile"
printf 'mobile broadband setup tests passed\n'
