#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/dotfiles/.local/bin/sleep-drain-check"

# A 3 h sleep that cost 6% (2 %/h), 10700 s of it in deep sleep, plus a 60 s test sleep.
cat >"${tmp}/journal" <<'EOF'
1789600000.000000 host kernel: PM: suspend entry (s2idle)
1789610800.000000 host kernel: PM: suspend exit
1789620000.000000 host kernel: PM: suspend entry (s2idle)
1789620060.000000 host kernel: PM: suspend exit
EOF
cat >"${tmp}/history" <<'EOF'
([(uint32 1789599900, 80.0, uint32 2), (uint32 1789610900, 74.0, uint32 2)],)
EOF
mkdir -p "${tmp}/root/sys/power/suspend_stats"
echo 59000000 >"${tmp}/root/sys/power/suspend_stats/last_hw_sleep"
out=$(SLEEP_DRAIN_JOURNAL="${tmp}/journal" SLEEP_DRAIN_HISTORY="${tmp}/history" SLEEP_DRAIN_ROOT="${tmp}/root" \
  python3 "${script}")

grep -q -- "+2.0 %/h" <<<"${out}"          # 80% -> 74% over 3 h
grep -q "80% -> 74%" <<<"${out}"
grep -q "too short" <<<"${out}"            # the 60 s sleep gets no rate
grep -q "59s of 60s in deep sleep (98%)" <<<"${out}"

# No sleeps at all: say so instead of dividing by nothing.
: >"${tmp}/empty"
out=$(SLEEP_DRAIN_JOURNAL="${tmp}/empty" SLEEP_DRAIN_HISTORY="${tmp}/history" SLEEP_DRAIN_ROOT="${tmp}/root" \
  python3 "${script}")
grep -q "no sleeps" <<<"${out}"

printf 'sleep-drain-check tests passed\n'
