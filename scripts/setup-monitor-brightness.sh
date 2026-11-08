#!/usr/bin/env bash
# setup-monitor-brightness.sh - Configure DDC/CI monitor brightness for QuickShell
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

info() { printf '\e[1;34m==>\e[0m %s\n' "$*"; }
ok()   { printf '\e[1;32m  ok\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m  !!\e[0m %s\n' "$*"; }

info "Setting up external monitor brightness support (DDC/CI)..."

# 1. Ensure ddcutil is installed
if ! command -v ddcutil >/dev/null 2>&1; then
    info "Installing ddcutil..."
    sudo pacman -S --needed --noconfirm ddcutil
    ok "Installed ddcutil"
else
    ok "ddcutil is already installed"
fi

# 2. Ensure i2c-dev module configuration exists
if [[ ! -f /etc/modules-load.d/i2c-dev.conf ]] || ! grep -q "^i2c-dev" /etc/modules-load.d/i2c-dev.conf 2>/dev/null; then
    info "Configuring /etc/modules-load.d/i2c-dev.conf..."
    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
    ok "Added i2c-dev to modules-load.d"
else
    ok "i2c-dev module load config already present"
fi

# 3. Load i2c-dev module if not currently loaded
if ! lsmod | grep -q "^i2c_dev\b"; then
    info "Loading i2c-dev module..."
    sudo modprobe i2c-dev
    ok "Loaded i2c-dev module"
else
    ok "i2c-dev module is loaded"
fi

# 4. Ensure udev rule for non-root /dev/i2c-* access
UDEV_RULE="/etc/udev/rules.d/99-i2c.rules"
if [[ ! -f "$UDEV_RULE" ]]; then
    info "Creating udev rule for non-root I2C access..."
    echo 'KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660", TAG+="uaccess"' | sudo tee "$UDEV_RULE" >/dev/null
    if ! getent group i2c >/dev/null 2>&1; then
        sudo groupadd -r i2c || true
    fi
    sudo usermod -aG i2c "$USER" || true
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=i2c-dev || true
    ok "Configured udev rules and group permissions for i2c"
else
    ok "udev rules for i2c already present"
fi

# 5. Detect displays
info "Detecting displays via ddcutil..."
ddcutil detect --brief || warn "ddcutil detect returned non-zero (may need re-login if group membership changed, but TAG+=uaccess should work immediately)"

ok "External monitor brightness setup complete."
