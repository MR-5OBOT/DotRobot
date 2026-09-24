#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

socket_tests=true
python3 -c 'import socket; socket.socket()' 2>/dev/null || socket_tests=false

for test in scripts/test-*; do
    if [[ "$socket_tests" == false && ( "$test" == scripts/test-tmux-float.py || "$test" == scripts/test-wallpaper-drop.py ) ]]; then
        printf 'skip %s (socket access unavailable)\n' "$test"
        continue
    fi
    case "$test" in
        *.sh) bash "$test" ;;
        *.py) python3 "$test" ;;
        *.js) node "$test" ;;
    esac
done
