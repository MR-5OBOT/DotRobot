#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

SYS_CLASS=/sys/class
PROFILE=""
MODEM_PORT=""

detect_modem() {
  local port found=0
  # shortcut: detects kernel WWAN/MBIM/QMI ports; add serial-only discovery when needed.
  for port in "${SYS_CLASS}"/usbmisc/cdc-wdm* "${SYS_CLASS}"/wwan/*; do
    [[ -e "${port}" ]] || continue
    log "Detected modem port: ${port}"
    found=1
  done
  (( found ))
}

setup_fibocom_unlock() (
  local port build_dir control radio_state
  for port in "${SYS_CLASS}"/usbmisc/cdc-wdm*/device; do
    [[ -r "${port}/../idVendor" && -r "${port}/../idProduct" ]] || continue
    [[ "$(<"${port}/../idVendor"):$(<"${port}/../idProduct")" == 413c:8213 ]] || continue
    log "Dell DW5825e / Fibocom FM101R-GL needs its vendor FCC unlock helper."
    prompt_step "Set up and enable Fibocom unlock support (no firmware flashing)" || return 0
    if ! pacman -Qq fibocom-fm101r-unlock >/dev/null 2>&1; then
      pacman -Qq base-devel curl >/dev/null 2>&1 || sudo pacman -Syu --needed base-devel curl
      build_dir="$(mktemp -d)"
      trap 'rm -rf -- "${build_dir}"' EXIT
      cp "${PACKAGES_DIR}/fibocom-fm101r-unlock/"* "${build_dir}/"
      cd "${build_dir}"
      makepkg -si --needed
    fi
    sudo systemctl daemon-reload
    sudo systemctl enable --now fibo_helper.service fibo_helper_mbim.service
    sudo timeout 30 /opt/fibocom/fibo_ma_service/fibo_ma || die "Fibocom unlock failed; inspect journalctl -b -t MaService."
    control="${port%/device}"
    radio_state="$(sudo env LC_ALL=C mbimcli --device="/dev/${control##*/}" --device-open-proxy --query-radio-state)" \
      || die "Could not read back the modem radio state."
    [[ "${radio_state}" == *"Hardware radio state: 'on'"* ]] || die "The modem hardware radio is still off; inspect journalctl -b -t MaService."
    log "Fibocom hardware radio is on; the installed services and unlock hook will handle future boots."
    return 0
  done
)

choose_carrier() {
  local choice
  CARRIER=""; APN=""; APN_USER=""
  printf '\nCarrier presets can be edited for your SIM/data plan.\n'
  PS3='Carrier number: '
  select choice in "Maroc Telecom (subscription)" "Maroc Telecom (Jawal/prepaid)" \
    "Orange Morocco" "inwi" "Other carrier / custom APN" "Configure later"; do
    case "${REPLY}" in
      1) CARRIER="Maroc Telecom"; APN=www.iamgprs1.ma; return ;;
      2) CARRIER="Maroc Telecom Jawal"; APN=www.iamgprs2.ma; return ;;
      3)
        CARRIER="Orange Morocco"; APN=internet.orange.ma; APN_USER=MEDINET
        log "Orange's published APN password is MEDINET, if requested when connecting."
        return ;;
      4) CARRIER=inwi; APN=www.inwi.ma; return ;;
      5) CARRIER=Custom; return ;;
      6) return ;;
      *) warn "Choose a listed carrier number." ;;
    esac
  done
}

configure_profile() {
  local answer name apn username existing_type
  local -a settings
  PROFILE=""
  choose_carrier
  [[ -n "${CARRIER}" ]] || return 0

  while true; do
    read -rp "Connection name [Mobile - ${CARRIER}]: " answer || return 0
    name="${answer:-Mobile - ${CARRIER}}"
    if existing_type="$(nmcli -g connection.type connection show id "${name}" 2>/dev/null)"; then
      if [[ "${existing_type}" == gsm ]]; then
        if prompt_step "Use existing '${name}' with its settings unchanged"; then
          PROFILE="${name}"
          return 0
        fi
      fi
      warn "That name is already in use; enter a different connection name."
    else
      break
    fi
  done

  while true; do
    read -rp "APN [${APN:-enter your carrier APN}]: " answer || return 0
    apn="${answer:-${APN}}"
    [[ -n "${apn}" ]] && break
    warn "An APN is required; use the value provided for your SIM/data plan."
  done
  read -rp "APN username [${APN_USER:-none}; '-' = none]: " answer || return 0
  username="${answer:-${APN_USER}}"
  [[ "${username}" != - ]] || username=""

  printf '\nConnection: %s\nAPN: %s\nUsername: %s\n' "${name}" "${apn}" "${username:-none}"
  printf 'Automatic connection: off. Roaming: off. Data marked as metered.\n'
  prompt_step "Save this mobile broadband connection" || return 0
  settings=(type gsm ifname "*" con-name "${name}" apn "${apn}" autoconnect no
    connection.metered yes gsm.home-only yes gsm.password-flags 2)
  [[ -z "${username}" ]] || settings+=(gsm.username "${username}")
  sudo nmcli connection add "${settings[@]}"
  PROFILE="${name}"
  log "Saved '${PROFILE}'. PINs and APN passwords are requested by nmcli when connecting."
}

list_modems() {
  mmcli -L | sed -n 's|^[[:space:]]*\(/org/freedesktop/ModemManager1/Modem/[0-9]*\).*|\1|p'
}

prepare_sim() {
  local modem info port primary count slot choice path attempt ready sim
  local -a modems slots
  MODEM_PORT=""
  mapfile -t modems < <(list_modems)
  ((${#modems[@]})) || { warn "No modem is ready in ModemManager; try again after it finishes starting."; return 1; }
  modem="${modems[0]}"
  if ((${#modems[@]} > 1)); then
    PS3='Modem number: '
    select choice in "${modems[@]}" "Cancel connection"; do
      [[ "${choice}" != 'Cancel connection' ]] || return 1
      [[ -z "${choice}" ]] || { modem="${choice}"; break; }
      warn "Choose a listed modem number."
    done
    [[ -n "${choice:-}" ]] || return 1
  fi
  info="$(mmcli -m "${modem}" -K)" || return 1
  port="$(awk '$1 == "modem.generic.primary-port" {print $3}' <<< "${info}")"
  primary="$(awk '$1 == "modem.generic.primary-sim-slot" {print $3}' <<< "${info}")"
  count="$(awk '$1 == "modem.generic.sim-slots.length" {print $3}' <<< "${info}")"
  if [[ "${count}" =~ ^[0-9]+$ ]] && ((count > 1)); then
    printf '\nSIM slots (current: %s). Choose the slot containing your SIM.\n' "${primary}"
    printf 'An empty eSIM profile cannot use the SIM in the physical tray.\n'
    if [[ -r "${SYS_CLASS}/usbmisc/${port}/device/../idVendor" && -r "${SYS_CLASS}/usbmisc/${port}/device/../idProduct" ]] \
      && [[ "$(<"${SYS_CLASS}/usbmisc/${port}/device/../idVendor"):$(<"${SYS_CLASS}/usbmisc/${port}/device/../idProduct")" == 413c:8213 ]]; then
      printf 'Dell DW5825e: slot 1 = physical SIM tray; slot 2 = eSIM.\n'
    fi
    for ((slot=1; slot<=count; slot++)); do
      path="$(awk -v key="modem.generic.sim-slots.value[${slot}]" '$1 == key {print $3}' <<< "${info}")"
      if [[ "${path}" == /org/freedesktop/ModemManager1/SIM/* ]]; then
        slots+=("Slot ${slot}: SIM detected")
      else
        slots+=("Slot ${slot}: no SIM reported")
      fi
    done
    PS3='SIM slot number: '
    select choice in "${slots[@]}" "Cancel connection"; do
      [[ "${choice}" != 'Cancel connection' ]] || return 1
      if [[ -n "${choice}" ]]; then slot="${REPLY}"; break; fi
      warn "Choose a listed SIM slot number."
    done
    [[ -n "${choice:-}" ]] || return 1
    if [[ "${slot}" != "${primary}" ]]; then
      sudo mmcli -m "${modem}" --set-primary-sim-slot="${slot}" || return 1
      log "Waiting for the modem after switching SIM slots..."
      # Switching slots may remove the old D-Bus object and create one with a new index.
      for ((attempt=0; attempt<30; attempt++)); do
        while read -r modem; do
          info="$(mmcli -m "${modem}" -K 2>/dev/null)" || continue
          [[ "$(awk '$1 == "modem.generic.primary-port" {print $3}' <<< "${info}")" == "${port}" ]] || continue
          primary="$(awk '$1 == "modem.generic.primary-sim-slot" {print $3}' <<< "${info}")"
          [[ "${primary}" == "${slot}" ]] && break 2
        done < <(list_modems)
        sleep 1
      done
      if ((attempt == 30)); then
        warn "The modem has not returned on the selected slot. Re-run setup once it is ready."
        return 1
      fi
    fi
  fi
  sim="$(awk '$1 == "modem.generic.sim" {print $3}' <<< "${info}")"
  if [[ "${info}" == *"${port} (mbim)"* ]]; then
    ready="$(sudo env LC_ALL=C timeout 15 mbimcli --device="/dev/${port}" --device-open-proxy --query-subscriber-ready-status)" || return 1
    case "${ready}" in
      *"Ready state: 'initialized'"*|*"Ready state: 'device-locked'"*) ;;
      *"Ready state: 'no-esim-profile'"*)
        warn "The selected slot is an eSIM with no profile. Choose the physical SIM slot or provision an eSIM."
        return 1 ;;
      *)
        warn "The selected SIM is not ready. Insert/reseat the SIM, then re-run setup."
        printf '%s\n' "${ready}" | sed -n '/Ready state:/p'
        return 1 ;;
    esac
  elif [[ "${sim}" != /org/freedesktop/ModemManager1/SIM/* ]]; then
    warn "No SIM detected in the selected slot. Insert/reseat the SIM, then re-run setup."
    return 1
  fi
  MODEM_PORT="${port}"
}

connect_profile() {
  local choice started modem_logs
  printf '\nConnecting uses your SIM data plan.\n'
  PS3='Connection action: '
  select choice in "Finish without connecting" "Enable mobile radio and connect now"; do
    case "${REPLY}" in
      1) break ;;
      2)
        sudo nmcli radio wwan on
        prepare_sim || break
        started="$(date --iso-8601=seconds)"
        if ! sudo nmcli --ask connection up id "${PROFILE}" ifname "${MODEM_PORT}"; then
          modem_logs="$(journalctl -b -u ModemManager --since "${started}" --no-pager -n 30 2>/dev/null || true)"
          [[ -z "${modem_logs}" ]] || printf '\nRecent modem messages:\n%s\n' "${modem_logs}"
          if [[ "${modem_logs}" == *"hardware radio switch is OFF"* ]]; then
            warn "The modem refused to power on before reaching carrier authentication."
            warn "Check rfkill/BIOS WWAN settings. If unblocked, check the manufacturer's FCC unlock helper:"
            warn "https://modemmanager.org/docs/modemmanager/fcc-unlock/"
            warn "For Dell DW5825e / FM101R-GL, re-run this setup and accept the Fibocom unlock step."
          fi
          die "Connection failed; the profile is saved. Inspect mmcli -L and journalctl -b -u ModemManager for details."
        fi
        break ;;
      *) warn "Choose 1 or 2." ;;
    esac
  done
  printf '\nConnect later:\n  nmcli radio wwan on\n  nmcli --ask connection up id %q\n' "${PROFILE}"
  printf 'Disconnect:\n  nmcli connection down id %q\n' "${PROFILE}"
}

main() {
  require_arch
  [[ $EUID -eq 0 ]] && die "Run as your normal user; the script uses sudo when needed."
  if ! detect_modem; then
    log "No kernel modem ports found; skipping mobile broadband setup. Check BIOS/driver support if a modem is installed."
    return 0
  fi

  if ! pacman -Qq networkmanager modemmanager >/dev/null 2>&1; then
    log "Mobile broadband needs NetworkManager and ModemManager. An existing internet connection is needed to install them."
    prompt_step "Install missing packages and upgrade Arch (pacman -Syu)" || return 0
    sudo pacman -Syu --needed networkmanager modemmanager
  else
    log "NetworkManager and ModemManager are already installed."
  fi
  prompt_step "Enable/start NetworkManager and ModemManager now and at boot" || return 0
  sudo systemctl enable --now NetworkManager.service ModemManager.service

  setup_fibocom_unlock
  configure_profile
  log "Inspect detected modems with: mmcli -L"
  [[ -n "${PROFILE}" ]] || return 0
  connect_profile
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
