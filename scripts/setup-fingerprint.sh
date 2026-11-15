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

# pacman_install and log/warn/die; lib.sh turns on set -e, but this script checks each step itself.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
set +e

PAM_SUDO=/etc/pam.d/sudo
HYPRLOCK_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf"
FINGER=right-index-finger
WANT_SUDO=ask

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
log "Looking for a fingerprint reader"
READER=""
for d in /sys/bus/usb/devices/*/; do
    [[ -f "$d/idVendor" ]] || continue
    name=$(cat "$d/product" 2>/dev/null || echo "")
    if [[ "$name" == *[Ff]ingerprint* ]]; then
        READER="$(cat "$d/idVendor"):$(cat "$d/idProduct")"
        log "found $READER  ($name)"
        break
    fi
done
if [[ -z "$READER" ]]; then
    warn "no USB fingerprint reader found, skipping. If yours is not USB, check 'dmesg | grep -i finger'."
    exit 0
fi

# --------------------------------------------------------------- 2. install
log "Installing fprintd + libfprint"
pacman_install fprintd libfprint || die "install failed"
log "installed"

# ------------------------------------------------------- 3. verify support
# Ask fprintd directly rather than grepping libfprint's udev rules - those
# rules only cover SPI binding and list no USB IDs at all. If libfprint has
# no driver for the chip, fprintd reports zero devices.
log "Checking whether libfprint has a driver for $READER"
DEVLIST=$(fprintd-list "$USER" 2>&1)
if grep -qE "found [1-9][0-9]* device" <<<"$DEVLIST"; then
    DEVNAME=$(sed -n 's/.* \(for\|on\) \(.*\)\.$/\2/p' <<<"$DEVLIST" | head -1)
    log "fprintd claims it${DEVNAME:+: $DEVNAME}"
else
    warn "fprintd reports no usable device for $READER"
    warn "Your libfprint may predate support for this chip. Options:"
    warn "  - check https://fprint.freedesktop.org/supported-devices.html"
    warn "  - try libfprint-git from the AUR"
    warn "  - some older Goodix chips need the out-of-tree TOD driver"
    die "unsupported device, stopping before enrollment"
fi

# ---------------------------------------------------------------- 4. enroll
log "Checking enrollment for $USER"
if fprintd-list "$USER" 2>/dev/null | grep -q "^Fingerprints for"; then
    log "already enrolled:"
    fprintd-list "$USER" 2>/dev/null | grep '^ - #' || true
else
    log "Enrolling $FINGER - lift and re-place your finger repeatedly"
    log "Center the pad of the finger; a Match-on-Chip sensor may want 15-20 scans"
    fprintd-enroll -f "$FINGER" || die "enrollment failed"
    log "enrolled $FINGER"
fi

# ---------------------------------------------------------------- 5. verify
log "Verifying the sensor"
if fprintd-verify 2>&1 | grep -q "verify-match"; then
    log "verify-match"
else
    warn "verification did not match - re-run and try a cleaner scan"
fi

# -------------------------------------------------------------- 6. hyprlock
log "Checking hyprlock config"
if [[ -f "$HYPRLOCK_CONF" ]] && grep -q "fingerprint" "$HYPRLOCK_CONF"; then
    log "auth.fingerprint block present in $HYPRLOCK_CONF"
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
    read -rp "Use fingerprint for sudo too? [y/N] " reply
    [[ "$reply" =~ ^[Yy] ]] && WANT_SUDO=yes || WANT_SUDO=no
fi

if [[ "$WANT_SUDO" == yes ]]; then
    log "Adding pam_fprintd to $PAM_SUDO"
    if grep -q "pam_fprintd.so" "$PAM_SUDO"; then
        log "already configured"
    elif [[ ! -f /usr/lib/security/pam_fprintd.so ]]; then
        warn "pam_fprintd.so missing - skipping sudo"
    else
        sudo cp --update=none "$PAM_SUDO" "$PAM_SUDO.bak" || die "could not back up $PAM_SUDO"
        # 'sufficient' means a failed scan falls through to the password
        # prompt, so a broken sensor can never lock you out of sudo.
        sudo sed -i '1a auth       sufficient  pam_fprintd.so' "$PAM_SUDO" \
            || die "could not edit $PAM_SUDO"
        log "added (backup at $PAM_SUDO.bak, revert with: sudo cp $PAM_SUDO.bak $PAM_SUDO)"
    fi
fi

printf '\nDone. Test with:\n'
printf '  fprintd-verify        # sensor\n'
printf '  hyprlock --grace 5    # lock screen\n'
[[ "$WANT_SUDO" == yes ]] && printf '  sudo -k && sudo true  # sudo\n'
exit 0
