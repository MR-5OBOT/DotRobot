#!/usr/bin/env bash
set -euo pipefail

command -v hyprsunset >/dev/null 2>&1 || {
    echo 'hyprsunset is not installed; skipping night light' >&2
    exit 0
}

repo="$(cd "$(dirname "$0")/.." && pwd)"
override="$HOME/.config/systemd/user/hyprsunset.service.d/override.conf"
mkdir -p "$(dirname "$override")"
if ! cmp -s "$repo/assets/systemd/hyprsunset-override.conf" "$override"; then
    cp --backup=numbered "$repo/assets/systemd/hyprsunset-override.conf" "$override"
fi

conf="$HOME/.local/state/island/hyprsunset.conf"
mkdir -p "$(dirname "$conf")"
if [[ ! -e "$conf" ]]; then
    cat > "$conf" <<'EOF'
max-gamma = 150

profile {
    time = 0:00
    identity = true
}
EOF
fi

systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable hyprsunset.service
if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    systemctl --user restart hyprsunset.service ||
        echo 'hyprsunset will start on the next graphical login' >&2
fi
