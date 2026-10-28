#!/usr/bin/env bash
set -euo pipefail
repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/cache/island/weather" "$tmp/run"
chmod 700 "$tmp/run"
cp -r "$repo/dotfiles/.config/quickshell/island" "$tmp/island"
# Accelerate the rollover timer so this test does not need to wait a minute.
python3 - "$tmp/island/Singletons/Weather.qml" <<'PYCODE'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
assert s.count('interval: 60000') == 1
p.write_text(s.replace('interval: 60000', 'interval: 40'))
PYCODE
cp "$repo/tests/weather-cache.qml" "$tmp/shell.qml"
python3 - "$tmp/cache/island/weather/weather-cache.json" <<'PYCODE'
import datetime, json, sys
today = datetime.date.today()
def day(offset, temp):
    return {"date": (today + datetime.timedelta(days=offset)).isoformat(), "day": "test", "code": 1, "temp": temp}
with open(sys.argv[1], "w") as f:
    json.dump({"tempNow": 18, "codeNow": 1, "isDay": True, "daily": [day(-1, 17), day(0, 18), day(1, 19)]}, f)
PYCODE
env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$tmp/run" XDG_CACHE_HOME="$tmp/cache" timeout 10s qs -p "$tmp" --no-color > "$tmp/log" 2>&1
cat "$tmp/log"
grep -qF 'Weather cache read, rollover and write passed.' "$tmp/log"
python3 - "$tmp/cache/island/weather/weather-cache.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
import datetime
assert data['daily'] == [{'date': datetime.date.today().isoformat(), 'day': 'Wed', 'code': 3, 'temp': 21}], data
PY

# Old caches had no dates; infer their dates and keep only the future outlook.
python3 - "$tmp/cache/island/weather/weather-cache.json" <<'PYCODE'
import datetime, json, sys
previous = datetime.datetime.now() - datetime.timedelta(days=1)
with open(sys.argv[1], "w") as f:
    json.dump({"tempNow": 18, "codeNow": 1, "ts": previous.timestamp() * 1000,
               "daily": [{"day": "old", "code": 1, "temp": 17},
                         {"day": "today", "code": 1, "temp": 18},
                         {"day": "tomorrow", "code": 1, "temp": 19}]}, f)
PYCODE
env -u WAYLAND_DISPLAY -u DBUS_SESSION_BUS_ADDRESS QT_QPA_PLATFORM=offscreen XDG_RUNTIME_DIR="$tmp/run" XDG_CACHE_HOME="$tmp/cache" TEST_LEGACY=1 timeout 10s qs -p "$tmp" --no-color > "$tmp/log" 2>&1
grep -qF 'Weather cache read, rollover and write passed.' "$tmp/log"
printf 'Legacy forecasts keep current and future days.\n'
