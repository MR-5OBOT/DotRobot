#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
export HOME="$temp_dir/home with spaces"
export XDG_CONFIG_HOME="$HOME/config" XDG_DATA_HOME="$HOME/data"
mkdir -p "$XDG_CONFIG_HOME"
kwriteconfig6 --file "$XDG_CONFIG_HOME/kdenliverc" --group misc --key existing preserved

setup="$repo/assets/presets/kdenlive-config/kdenlive-setup.sh"
"$setup"
"$setup"
[[ "$(kreadconfig6 --file "$XDG_CONFIG_HOME/kdenliverc" --group misc --key existing)" == preserved ]]
[[ "$(kreadconfig6 --file "$XDG_CONFIG_HOME/kdenliverc" --group sdl --key window_background)" == 42,42,42 ]]
[[ "$(kreadconfig6 --file "$XDG_CONFIG_HOME/kdenliverc" --group UiSettings --key ColorScheme)" == mr5obot-kdenlive-theme ]]
python3 - "$XDG_DATA_HOME/kdenlive/layouts" <<'PY'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
for suffix, vertical in [('', False), ('_vertical', True)]:
    info = json.loads((path / f'mr5obot-preset{suffix}.json').read_text())['kdenliveInfo'][0]
    assert info['displayName'] == 'mr5obot preset' and info['vertical'] is vertical
PY
printf 'existing theme\n' > "$XDG_DATA_HOME/color-schemes/mr5obot-kdenlive-theme.colors"
if "$setup"; then
  printf 'Setup unexpectedly overwrote an existing theme\n' >&2
  exit 1
fi
[[ "$(cat "$XDG_DATA_HOME/color-schemes/mr5obot-kdenlive-theme.colors")" == 'existing theme' ]]
printf 'Kdenlive setup checks passed.\n'
