#!/usr/bin/env bash
# Wayland clipboard history for the quickshell clipboard popup (Super+V).
# Idempotent: a hyprland reload won't stack duplicate watchers.

for t in text image; do
  pgrep -f "wl-paste --type $t --watch cliphist store" >/dev/null \
    || wl-paste --type "$t" --watch cliphist store &
done
