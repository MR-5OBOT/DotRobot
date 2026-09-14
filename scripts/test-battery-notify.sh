#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../dotfiles/.config/hypr/scripts/autostart/battery-notify.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
POWER_SUPPLY_DIR="$tmp/power"
mkdir -p "$POWER_SUPPLY_DIR"
! has_battery
mkdir -p "$POWER_SUPPLY_DIR/BAT0"
has_battery
printf '5000\n' >"$POWER_SUPPLY_DIR/BAT0/energy_now"
printf '5000\n' >"$POWER_SUPPLY_DIR/BAT0/energy_full"
printf 'Full\n' >"$POWER_SUPPLY_DIR/BAT0/status"
read_battery
[[ $pct == 100 && $fully_charged == 1 ]]

notifications=()
notify() { notifications+=("$2"); }

process_battery_state
process_battery_state
[[ ${#notifications[@]} == 1 && ${notifications[0]} == "🔋 Battery full" ]]

pct=99 fully_charged=0
process_battery_state
pct=100 fully_charged=1
process_battery_state
[[ ${#notifications[@]} == 2 ]]
echo "battery full notification test passed"
