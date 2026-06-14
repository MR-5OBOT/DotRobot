#!/usr/bin/env bash
# restore-screenshare-fix.sh
# ----------------------------------------------------------------------------
# Re-applies the Wayland/Hyprland screen-share fix if it ever gets deleted.
#
# Root cause it fixes: xdg-desktop-portal has `Requisite=graphical-session.target`
# but nothing in this Hyprland setup activates that target, so the portal never
# starts and screen sharing fails everywhere. This restores:
#   1) ~/.config/systemd/user/hyprland-session.target   (wrapper that pulls in
#      graphical-session.target, which refuses manual start)
#   2) the autostart.lua line that starts it at every login
#
# Safe to run multiple times — it only adds what is missing.
# ----------------------------------------------------------------------------
set -euo pipefail

UNIT="$HOME/.config/systemd/user/hyprland-session.target"
AUTOSTART="$HOME/.config/hypr/lua_configs/autostart.lua"

# 1) (re)create the wrapper target -------------------------------------------
mkdir -p "$(dirname "$UNIT")"
cat > "$UNIT" <<'EOF'
[Unit]
Description=Hyprland compositor session
Documentation=man:systemd.special(7)
BindsTo=graphical-session.target
Before=graphical-session.target
EOF
echo "[ok] wrote $UNIT"

# 2) ensure autostart starts the target (idempotent) -------------------------
if [ -f "$AUTOSTART" ]; then
  if grep -q 'hyprland-session.target' "$AUTOSTART"; then
    echo "[skip] autostart.lua already starts the target"
  else
    perl -0pi -e 's{(dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP)(")}{$1 HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprland-session.target$2}' "$AUTOSTART"
    if grep -q 'hyprland-session.target' "$AUTOSTART"; then
      echo "[ok] patched $AUTOSTART"
    else
      echo "[warn] could not auto-patch $AUTOSTART — add this inside hyprland.start:"
      echo '       hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE && systemctl --user start hyprland-session.target")'
    fi
  fi
else
  echo "[warn] $AUTOSTART not found — skipping autostart patch"
fi

# 3) apply now ----------------------------------------------------------------
systemctl --user daemon-reload
systemctl --user start hyprland-session.target
echo "[done] portal chain:"
systemctl --user is-active hyprland-session.target graphical-session.target xdg-desktop-portal-hyprland
