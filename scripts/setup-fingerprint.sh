#!/usr/bin/env bash
# setup-fingerprint.sh - fingerprint auth from zero on Arch + Hyprland.
#
# Detects the reader, installs fprintd/libfprint, confirms the device is
# actually supported, enrolls a finger, and optionally wires up sudo.
#
# hyprlock needs no PAM changes - it talks to fprintd over D-Bus. The
# relevant config already lives in dotfiles/.config/hypr/hyprlock.conf
# (auth.fingerprint block); this script only verifies it is present.
#
#   ./setup-fingerprint.sh              # interactive
#   ./setup-fingerprint.sh --sudo       # also add the sudo PAM rule
#   ./setup-fingerprint.sh --no-sudo    # skip sudo entirely
#   ./setup-fingerprint.sh --finger left-index-finger

set -uo pipefail

PAM_SUDO=/etc/pam.d/sudo
HYPRLOCK_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf"
FINGER=right-index-finger
WANT_SUDO=ask

if [[ -t 1 ]]; then
    R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; B=$'\e[1;34m'; Z=$'\e[0m'
else
    R=''; G=''; Y=''; B=''; Z=''
fi
info() { printf '%s==>%s %s\n' "$B" "$Z" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$G" "$Z" "$*"; }
warn() { printf '%s  !!%s %s\n' "$Y" "$Z" "$*"; }
die()  { printf '%s ERR%s %s\n' "$R" "$Z" "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sudo)    WANT_SUDO=yes ;;
        --no-sudo) WANT_SUDO=no ;;
        --finger)  FINGER="${2:?--finger needs a value}"; shift ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)         die "unknown argument: $1" ;;
    esac
    shift
done

command -v pacman >/dev/null || die "this script targets Arch (pacman not found)"
[[ $EUID -eq 0 ]] && die "run as your normal user, not root - enrollment is per-user"

# ---------------------------------------------------------------- 1. detect
info "Looking for a fingerprint reader"
READER=""
for d in /sys/bus/usb/devices/*/; do
    [[ -f "$d/idVendor" ]] || continue
    name=$(cat "$d/product" 2>/dev/null || echo "")
    if [[ "$name" == *[Ff]ingerprint* ]]; then
        READER="$(cat "$d/idVendor"):$(cat "$d/idProduct")"
        ok "found $READER  ($name)"
        break
    fi
done
[[ -n "$READER" ]] || die "no USB fingerprint reader found. If yours is not USB, check 'dmesg | grep -i finger'."

# --------------------------------------------------------------- 2. install
info "Installing fprintd + libfprint"
if pacman -Qq fprintd &>/dev/null && pacman -Qq libfprint &>/dev/null; then
    ok "already installed"
else
    sudo pacman -S --needed --noconfirm fprintd libfprint || die "install failed"
    ok "installed"
fi

# ------------------------------------------------------- 3. verify support
# Ask fprintd directly rather than grepping libfprint's udev rules - those
# rules only cover SPI binding and list no USB IDs at all. If libfprint has
# no driver for the chip, fprintd reports zero devices.
info "Checking whether libfprint has a driver for $READER"
DEVLIST=$(fprintd-list "$USER" 2>&1)
if grep -qE "found [1-9][0-9]* device" <<<"$DEVLIST"; then
    DEVNAME=$(sed -n 's/.* \(for\|on\) \(.*\)\.$/\2/p' <<<"$DEVLIST" | head -1)
    ok "fprintd claims it${DEVNAME:+: $DEVNAME}"
else
    warn "fprintd reports no usable device for $READER"
    warn "Your libfprint may predate support for this chip. Options:"
    warn "  - check https://fprint.freedesktop.org/supported-devices.html"
    warn "  - try libfprint-git from the AUR"
    warn "  - some older Goodix chips need the out-of-tree TOD driver"
    die "unsupported device, stopping before enrollment"
fi

# ---------------------------------------------------------------- 4. enroll
info "Checking enrollment for $USER"
if fprintd-list "$USER" 2>/dev/null | grep -q "^Fingerprints for"; then
    ok "already enrolled:"
    fprintd-list "$USER" 2>/dev/null | grep '^ - #' || true
else
    info "Enrolling $FINGER - lift and re-place your finger repeatedly"
    info "Center the pad of the finger; a Match-on-Chip sensor may want 15-20 scans"
    fprintd-enroll -f "$FINGER" || die "enrollment failed"
    ok "enrolled $FINGER"
fi

# ---------------------------------------------------------------- 5. verify
info "Verifying the sensor"
if fprintd-verify 2>&1 | grep -q "verify-match"; then
    ok "verify-match"
else
    warn "verification did not match - re-run and try a cleaner scan"
fi

# -------------------------------------------------------------- 6. hyprlock
info "Checking hyprlock config"
if [[ -f "$HYPRLOCK_CONF" ]] && grep -q "fingerprint" "$HYPRLOCK_CONF"; then
    ok "auth.fingerprint block present in $HYPRLOCK_CONF"
else
    warn "no fingerprint block in $HYPRLOCK_CONF - add:"
    cat <<'EOF'

    auth {
        fingerprint {
            enabled = true
            ready_message = (or scan)
            present_message = (scanning)
        }
    }
EOF
fi

# ------------------------------------------------------------------ 7. sudo
if [[ "$WANT_SUDO" == ask ]]; then
    read -rp "$(printf '%s==>%s Use fingerprint for sudo too? [y/N] ' "$B" "$Z")" reply
    [[ "$reply" =~ ^[Yy] ]] && WANT_SUDO=yes || WANT_SUDO=no
fi

if [[ "$WANT_SUDO" == yes ]]; then
    info "Adding pam_fprintd to $PAM_SUDO"
    if grep -q "pam_fprintd.so" "$PAM_SUDO"; then
        ok "already configured"
    elif [[ ! -f /usr/lib/security/pam_fprintd.so ]]; then
        warn "pam_fprintd.so missing - skipping sudo"
    else
        sudo cp "$PAM_SUDO" "$PAM_SUDO.bak" || die "could not back up $PAM_SUDO"
        # 'sufficient' means a failed scan falls through to the password
        # prompt, so a broken sensor can never lock you out of sudo.
        sudo sed -i '1a auth       sufficient  pam_fprintd.so' "$PAM_SUDO" \
            || die "could not edit $PAM_SUDO"
        ok "added (backup at $PAM_SUDO.bak, revert with: sudo mv $PAM_SUDO.bak $PAM_SUDO)"
    fi
fi

printf '\n%sDone.%s Test with:\n' "$G" "$Z"
printf '  fprintd-verify        # sensor\n'
printf '  hyprlock --grace 5    # lock screen\n'
[[ "$WANT_SUDO" == yes ]] && printf '  sudo -k && sudo true  # sudo\n'
exit 0
