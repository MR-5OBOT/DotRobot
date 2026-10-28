#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/cache/island/weather" "$tmp/run"
chmod 700 "$tmp/run"
cp -r "$repo/dotfiles/.config/quickshell/island" "$tmp/island"
cp "$repo/tests/weather-agent.qml" "$tmp/shell.qml"
python3 - "$tmp/island/Singletons/Weather.qml" "$tmp/bin" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
assert '/usr/lib/geoclue-2.0/demos/' in s
p.write_text(s.replace('/usr/lib/geoclue-2.0/demos/', sys.argv[2] + '/'))
PY
cat > "$tmp/bin/agent" <<'SH'
#!/bin/sh
echo started >> "$TEST_AGENT_LOG"
echo $$ > "$TEST_AGENT_PID"
trap 'echo stopped >> "$TEST_AGENT_LOG"; exit' TERM INT
while :; do sleep 0.1; done
SH
cat > "$tmp/bin/where-am-i" <<'SH'
#!/bin/sh
if [ "${TEST_SLOW:-}" = 1 ]; then
    echo $$ > "$TEST_LOCATION_PID"
    exec sleep 15
fi
printf 'Latitude: 33\nLongitude: -7\nAccuracy: 50\n'
SH
printf '#!/bin/sh\n[ "${TEST_AGENT_PRESENT:-}" = 1 ]\n' > "$tmp/bin/pgrep"
printf '#!/bin/sh\nexit 0\n' > "$tmp/bin/curl"
chmod +x "$tmp/bin/"*
env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$tmp/run" XDG_CACHE_HOME="$tmp/cache" PATH="$tmp/bin:$PATH" TEST_AGENT_LOG="$tmp/agent.log" TEST_AGENT_PID="$tmp/agent.pid" timeout 8s qs -p "$tmp" --no-color > "$tmp/log" 2>&1
if [[ "$(cat "$tmp/agent.log")" != $'started\nstopped' ]]; then
    cat "$tmp/log" "$tmp/agent.log" >&2
    exit 1
fi
printf 'Weather agent exits after the location lookup.\n'

# Quickshell may exit while where-am-i is still waiting for a fix.
rm -f "$tmp/agent.pid" "$tmp/location.pid"
env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$tmp/run" XDG_CACHE_HOME="$tmp/cache" PATH="$tmp/bin:$PATH" TEST_AGENT_LOG="$tmp/agent.log" TEST_AGENT_PID="$tmp/agent.pid" TEST_LOCATION_PID="$tmp/location.pid" TEST_SLOW=1 timeout 8s qs -p "$tmp" --no-color > "$tmp/log" 2>&1
if [[ ! -s "$tmp/agent.pid" || ! -s "$tmp/location.pid" ]]; then
    cat "$tmp/log" >&2
    exit 1
fi
agent_pid=$(cat "$tmp/agent.pid")
kill "$(cat "$tmp/location.pid")" 2>/dev/null || true
if kill -0 "$agent_pid" 2>/dev/null && [[ "$(ps -o stat= -p "$agent_pid")" != Z* ]]; then
    kill "$agent_pid" 2>/dev/null || true
    printf 'Weather agent survived Quickshell exit.\n' >&2
    exit 1
fi
printf 'Weather agent exits when Quickshell closes during lookup.\n'

# An agent managed outside Quickshell must be left alone.
rm -f "$tmp/agent.pid" "$tmp/cache/island/weather/weather-loc.json"
env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$tmp/run" XDG_CACHE_HOME="$tmp/cache" PATH="$tmp/bin:$PATH" TEST_AGENT_LOG="$tmp/agent.log" TEST_AGENT_PID="$tmp/agent.pid" TEST_AGENT_PRESENT=1 timeout 8s qs -p "$tmp" --no-color > "$tmp/log" 2>&1
[[ ! -e "$tmp/agent.pid" ]] || { printf 'Started an agent despite an existing one.\n' >&2; exit 1; }
python3 - "$tmp/cache/island/weather/weather-loc.json" <<'PYCODE'
import json, sys
with open(sys.argv[1]) as f:
    result = json.load(f)
assert result['lat'] == 33 and result['lon'] == -7, result
PYCODE
printf 'Weather reuses an existing agent.\n'

# A forced Quickshell crash must not leave its agent behind.
rm -f "$tmp/agent.pid" "$tmp/location.pid"
env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$tmp/run" XDG_CACHE_HOME="$tmp/cache" PATH="$tmp/bin:$PATH" TEST_AGENT_LOG="$tmp/agent.log" TEST_AGENT_PID="$tmp/agent.pid" TEST_LOCATION_PID="$tmp/location.pid" TEST_SLOW=1 qs -p "$tmp" --no-color > "$tmp/log" 2>&1 &
qs_pid=$!
for _ in {1..50}; do
    [[ -s "$tmp/agent.pid" && -s "$tmp/location.pid" ]] && break
    sleep 0.1
done
if [[ ! -s "$tmp/agent.pid" || ! -s "$tmp/location.pid" ]]; then
    kill "$qs_pid" 2>/dev/null || true
    cat "$tmp/log" >&2
    exit 1
fi
agent_pid=$(cat "$tmp/agent.pid")
location_pid=$(cat "$tmp/location.pid")
kill -KILL "$qs_pid" 2>/dev/null || true
wait "$qs_pid" 2>/dev/null || true
sleep 0.5
kill "$location_pid" 2>/dev/null || true
if kill -0 "$agent_pid" 2>/dev/null && [[ "$(ps -o stat= -p "$agent_pid")" != Z* ]]; then
    kill "$agent_pid" 2>/dev/null || true
    printf 'Weather agent survived a Quickshell crash.\n' >&2
    exit 1
fi
printf 'Weather agent exits when Quickshell crashes.\n'
