#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"

for command in kreadconfig6 kwriteconfig6 pgrep; do
  command -v "$command" >/dev/null || { printf 'Missing required command: %s\n' "$command" >&2; exit 1; }
done
if pgrep -u "$(id -u)" -x kdenlive >/dev/null; then
  printf 'Close Kdenlive before running this setup.\n' >&2
  exit 1
fi

theme="$dir/mr5obot-kdenlive-theme.colors"
color="$(kreadconfig6 --file "$theme" --group sdl --key window_background)"
channel='(0|[1-9][0-9]?|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
[[ "$color" =~ ^${channel},${channel},${channel}$ ]] || { printf 'Invalid monitor color in %s\n' "$theme" >&2; exit 1; }

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
for suffix in '' _vertical; do
  sed 's/"displayName": "mr5obot"/"displayName": "mr5obot preset"/' \
    "$dir/kdenlive-layout${suffix}.json" > "$temp_dir/mr5obot-preset${suffix}.json"
done

sources=("$theme" "$dir/org.kde.kdenlive.desktop" "$temp_dir/mr5obot-preset.json" "$temp_dir/mr5obot-preset_vertical.json")
targets=("$data_dir/color-schemes/mr5obot-kdenlive-theme.colors" "$data_dir/applications/org.kde.kdenlive.desktop" \
  "$data_dir/kdenlive/layouts/mr5obot-preset.json" "$data_dir/kdenlive/layouts/mr5obot-preset_vertical.json")
for i in "${!targets[@]}"; do
  if [[ -e "${targets[i]}" || -L "${targets[i]}" ]] && ! cmp -s "${sources[i]}" "${targets[i]}"; then
    printf 'Refusing to overwrite existing file: %s\n' "${targets[i]}" >&2
    exit 1
  fi
done
for i in "${!targets[@]}"; do
  if [[ ! -e "${targets[i]}" ]]; then
    mkdir -p "$(dirname "${targets[i]}")"
    install -m 644 "${sources[i]}" "${targets[i]}"
  fi
done
mkdir -p "$config_dir"
kwriteconfig6 --file "$config_dir/kdenliverc" --group UiSettings --key ColorScheme mr5obot-kdenlive-theme
kwriteconfig6 --file "$config_dir/kdenliverc" --group sdl --key window_background "$color"
printf 'Kdenlive appearance and layouts installed. Open Kdenlive to use them.\n'
