#!/usr/bin/env bash
# Low-battery notifier. Used to live inside quickshell's Battery.qml; split out
# so the warning keeps running across a qs restart (Super+Shift+N reloads the
# bar constantly). The island (repo island/) owns the notification server and draws
# the toast -- this decides when one is due.
#
# Runs as battery-notify.service; systemd keeps it to one copy and logs it
# (journalctl --user -u battery-notify).

set -uo pipefail

POWER_SUPPLY_DIR="${POWER_SUPPLY_DIR:-/sys/class/power_supply}"
LOW_PCT=20          # start warning at or under this
CRIT_PCT=10         # tighten the nag at or under this
NAG_SECS=300        # 5 min while 11-20%
CRIT_SECS=60        # 1 min at or under CRIT_PCT
POLL_SECS=10

pct=0 full=0 charging=0 fully_charged=0

has_battery() {
  local battery
  for battery in "${POWER_SUPPLY_DIR}"/BAT*; do
    [[ -d "${battery}" ]] && return 0
  done
  return 1
}

# rd VAR FILE [default]: read one sysfs value with no fork (polled every 10s);
# a missing file gives the default, 0 unless set.
rd() { read -r "$1" 2>/dev/null < "$2" || printf -v "$1" '%s' "${3-0}"; }

# Kernels expose one of two unit families: energy_*/power_now (uWh/uW, the
# ThinkPad) or charge_*/current_now (uAh/uA, the Dell). Scale charge units by
# voltage so both end up as energy, then sum across every BAT.
read_battery() {
  local b n=0 f=0 v now fu st batteries=0 full_batteries=0 discharging=0
  charging=0
  fully_charged=0
  for b in "${POWER_SUPPLY_DIR}"/BAT*; do
    [[ -d "${b}" ]] || continue
    batteries=$(( batteries + 1 ))
    rd v "${b}/voltage_now"
    [[ "${v}" == 0 ]] && rd v "${b}/voltage_min_design"
    rd now "${b}/energy_now"
    rd fu "${b}/energy_full"
    if [[ "${fu}" == 0 ]]; then
      rd now "${b}/charge_now"; now=$(( now * v / 1000000 ))
      rd fu "${b}/charge_full"; fu=$(( fu * v / 1000000 ))
    fi
    rd st "${b}/status" ""
    case "${st}" in
      Charging) charging=1 ;;
      Discharging) discharging=1 ;;
      Full) full_batteries=$(( full_batteries + 1 )) ;;
    esac
    n=$(( n + now )); f=$(( f + fu ))
  done
  full=${f}
  pct=$(( f > 0 ? (n * 100 + f / 2) / f : 0 ))   # round, like the old Math.round
  if (( batteries > 0 && (full_batteries == batteries || (pct >= 100 && !charging && !discharging)) )); then
    fully_charged=1
  fi
}

# notify-send -p hands back the freedesktop id and -r reuses it, so repeats
# rewrite one card instead of stacking sticky criticals (the island's toasts never
# auto-expire a critical). keep=0 means don't track the id we get back.
notif_id=0
notify() {
  local urgency=$1 summary=$2 body=$3 keep=$4 args id
  args=(-p -u "${urgency}" -i battery-caution)
  (( notif_id > 0 )) && args+=(-r "${notif_id}")
  echo "${summary}: ${pct}% — ${body}" # journalctl --user -u battery-notify
  # fails if no notification server yet (login, qs restart): caller retries
  id=$(notify-send "${args[@]}" "${summary}" "${pct}% — ${body}") || return 1
  if (( keep )); then notif_id=${id:-0}; else notif_id=0; fi
}

last_nag=0 full_notified=0
process_battery_state() {
  if (( full > 0 )); then
    if (( fully_charged )); then
      if (( !full_notified )) && notify normal "🔋 Battery full" "unplug your charger" 0; then
        full_notified=1
      fi
      notif_id=0
      last_nag=0
    elif (( charging || pct > LOW_PCT )); then
      full_notified=0
      # plugging in replaces the critical card with a note that expires on its own
      (( notif_id > 0 && charging )) && notify normal "🔌 Charging" "charger connected" 0
      notif_id=0
      last_nag=0
    else
      gap=${NAG_SECS}
      (( pct <= CRIT_PCT )) && gap=${CRIT_SECS}
      now_s=${EPOCHSECONDS}
      if (( last_nag == 0 || now_s - last_nag >= gap )); then
        title="⚠️ Low battery"
        (( pct <= CRIT_PCT )) && title="🪫 Battery critical"
        # only a shown nag restarts the gap; a failed one retries next poll
        notify critical "${title}" "plug in your charger!" 1 && last_nag=${now_s}
      fi
    fi
  fi
}

main() {
  has_battery || exit 0

  while :; do
    read_battery
    process_battery_state
    sleep "${POLL_SECS}"
  done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
