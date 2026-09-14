#!/usr/bin/env bash
# Low-battery notifier. Used to live inside quickshell's Battery.qml; split out
# so the warning keeps running across a qs restart (Super+Shift+N reloads the
# bar constantly). quickshell is now only the notification daemon that draws the
# card -- this decides when one is due.
#
# Idempotent: a hyprland reload won't stack a second watcher.

set -uo pipefail

LOCK="${XDG_RUNTIME_DIR:-/tmp}/battery-notify.lock"
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
    v=$(cat "${b}/voltage_now" 2>/dev/null || echo 0)
    [[ "${v}" == 0 ]] && v=$(cat "${b}/voltage_min_design" 2>/dev/null || echo 0)
    now=$(cat "${b}/energy_now" 2>/dev/null || echo 0)
    fu=$(cat "${b}/energy_full" 2>/dev/null || echo 0)
    if [[ "${fu}" == 0 ]]; then
      now=$(( $(cat "${b}/charge_now" 2>/dev/null || echo 0) * v / 1000000 ))
      fu=$(( $(cat "${b}/charge_full" 2>/dev/null || echo 0) * v / 1000000 ))
    fi
    st=$(cat "${b}/status" 2>/dev/null || echo "")
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
# rewrite one card instead of stacking sticky criticals (the qs NotifCard never
# auto-expires a critical). keep=0 means don't track the id we get back.
notif_id=0
notify() {
  local urgency=$1 summary=$2 body=$3 keep=$4 args id
  args=(-p -u "${urgency}" -i battery-caution)
  (( notif_id > 0 )) && args+=(-r "${notif_id}")
  id=$(notify-send "${args[@]}" "${summary}" "${pct}% — ${body}" 2>/dev/null)
  if (( keep )); then notif_id=${id:-0}; else notif_id=0; fi
}

last_nag=0 full_notified=0
process_battery_state() {
  if (( full > 0 )); then
    if (( fully_charged )); then
      if (( !full_notified )); then
        notify normal "🔋 Battery full" "unplug your charger" 0
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
      now_s=$(date +%s)
      if (( last_nag == 0 || now_s - last_nag >= gap )); then
        last_nag=${now_s}
        if (( pct <= CRIT_PCT )); then
          notify critical "🪫 Battery critical" "plug in your charger!" 1
        else
          notify critical "⚠️ Low battery" "plug in your charger!" 1
        fi
      fi
    fi
  fi
}

main() {
  has_battery || exit 0
  exec 9>"${LOCK}"
  flock -n 9 || exit 0

  while :; do
    read_battery
    process_battery_state
    sleep "${POLL_SECS}"
  done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
