#!/usr/bin/env bash
# __  ______   ____
# \ \/ /  _ \ / ___|
#  \  /| | | | |  _
#  /  \| |_| | |_| |
# /_/\_\____/ \____|
#
# Ensure xdg-desktop-portal runs in BOTH session types, so GTK/libadwaita apps
#
#   * uwsm session    -> graphical-session.target is active; systemd D-Bus-activates
#                        the portal on demand. This script does NOTHING.
#   * plain Hyprland  -> no graphical-session.target, so the portal would refuse to
#                        start. This script launches the backends manually (fallback).
#
# Check which branch ran:  cat ~/.cache/xdgportals.log

LOG="$HOME/.cache/xdgportals.log"
log() { echo "$(date '+%F %T') $*" >>"$LOG"; }

# Make sure systemd/D-Bus know our Wayland session (harmless under uwsm).
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null

# ---- Fix 1: uwsm / systemd-managed session ----
if systemctl --user is-active --quiet graphical-session.target; then
    log "uwsm session (graphical-session.target active) -> portal handled by systemd, nothing to do."
    exit 0
fi

# ---- Fix 2: plain Hyprland session (manual fallback) ----
log "plain Hyprland session (no graphical-session.target) -> starting portals manually."
/usr/lib/xdg-desktop-portal-hyprland &
sleep 1
/usr/lib/xdg-desktop-portal-gtk &
sleep 0.5
/usr/lib/xdg-desktop-portal &
log "manual portal backends launched."
