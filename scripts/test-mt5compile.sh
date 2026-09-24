#!/usr/bin/env bash
set -euo pipefail

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/mt5/MQL5/Experts"
src="$tmp/home/sample.mq5"
printf '#property version "1.0"\n' > "$src"
printf 'old build' > "${src%.mq5}.ex5"
touch -d "@$(date +%s)" "${src%.mq5}.ex5"
touch "$tmp/mt5/MetaEditor64.exe"

printf '#!/bin/sh\nprintf "%%s\\n" "$MT5_SOURCE"\n' > "$tmp/bin/fd"
printf '#!/bin/sh\nhead -n1\n' > "$tmp/bin/fzf"
printf '#!/bin/sh\nprintf "%%s\\n" "$2"\n' > "$tmp/bin/winepath"
printf '#!/bin/sh\nprintf "new build" > "${MT5_SOURCE%%.mq5}.ex5"\n' > "$tmp/bin/wine"
chmod +x "$tmp/bin/"*

export HOME="$tmp/home" MT5_ROOT="$tmp/mt5" MT5_SOURCE="$src"
export PATH="$tmp/bin:$PATH"
bash "$(dirname "$0")/../dotfiles/.local/bin/mt5compile" >/dev/null
[[ $(cat "$tmp/mt5/MQL5/Experts/sample.ex5") == 'new build' ]]
echo 'mt5compile same-second rebuild check passed'
