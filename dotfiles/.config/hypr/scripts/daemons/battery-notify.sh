#!/usr/bin/env bash
# Low-battery notifier. Used to live inside quickshell's Battery.qml; split out
# so the warning keeps running across a qs restart (Super+Alt+N reloads the
# bar constantly). The island (repo island/) owns the notification server and draws
# the toast -- this decides when one is due.
#
# Runs as battery-notify.service; systemd keeps it to one copy and logs it
# (journalctl --user -u battery-notify).

set -uo pipefail

LOW_PCT=20          # start warning at or under this
CRIT_PCT=10         # tighten the nag at or under this
NAG_SECS=300        # 5 min while 11-20%
CRIT_SECS=60        # 1 min at or under CRIT_PCT
POLL_SECS=10

pct=0 present=0 charging=0 fully_charged=0

has_battery() {
  compgen -G "/sys/class/power_supply/BAT*" >/dev/null
}

# Same source as the bar: UPower's display device, which already combines every
# battery and both kernel unit families. One upower call per poll.
read_battery() {
  local state
  read -r present state pct < <(LC_ALL=C upower -i /org/freedesktop/UPower/devices/DisplayDevice 2>/dev/null | awk '
    $1 == "present:" { present = ($2 == "yes") }
    $1 == "state:" { state = $2 }
    $1 == "percentage:" { pct = int($2 + 0.5) }
    END { printf "%d %s %d\n", present, (state == "" ? "unknown" : state), pct }')
  charging=0 fully_charged=0
  [[ ${state} == charging ]] && charging=1
  # Full: UPower says so, or 100% while neither charging nor discharging.
  if [[ ${state} == fully-charged ]] || { (( pct >= 100 )) && [[ ${state} != charging && ${state} != discharging ]]; }; then
    fully_charged=1
  fi
  return 0
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
  if (( present )); then
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

main "$@"
