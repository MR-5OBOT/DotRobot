#!/usr/bin/env bash
set -euo pipefail

PASSWORD_FLAG="--password-store=basic"

command -v paru >/dev/null || {
    echo "✖ paru not found"
    exit 1
}

echo "Select Brave version:"
echo "  1) Stable"
echo "  2) Nightly"
read -rp "Enter choice [1-2]: " choice

case "$choice" in
    1)
        PKG="brave-bin"
        BIN="brave-browser"
        VARIANT="stable"
        DESKTOP_GREP='^brave.*browser.*\.desktop$'
        ;;
    2)
        PKG="brave-nightly-bin"
        BIN="brave-nightly"
        VARIANT="nightly"
        DESKTOP_GREP='^brave.*nightly.*\.desktop$'
        ;;
    *)
        echo "✖ Invalid selection"
        exit 1
        ;;
esac

echo "▶ Selected: Brave $VARIANT"

echo "▶ Removing any existing Brave installations..."
paru -Rns --noconfirm \
    brave-bin brave-nightly-bin brave-beta-bin 2>/dev/null || true

echo "▶ Installing $PKG..."
paru -S --needed --noconfirm "$PKG"

SYSTEM_DESKTOP="$(ls /usr/share/applications | grep -E "$DESKTOP_GREP" | head -n1)"
[ -n "$SYSTEM_DESKTOP" ] || {
    echo "✖ Could not find Brave desktop file"
    exit 1
}

SYSTEM_DESKTOP="/usr/share/applications/$SYSTEM_DESKTOP"
USER_DESKTOP="$HOME/.local/share/applications/$(basename "$SYSTEM_DESKTOP")"

echo "▶ Overriding desktop entry (disabling KDE Wallet)..."
mkdir -p "$(dirname "$USER_DESKTOP")"
cp "$SYSTEM_DESKTOP" "$USER_DESKTOP"

sed -i \
  "s|^Exec=.*|Exec=$BIN $PASSWORD_FLAG %U|" \
  "$USER_DESKTOP"

update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

echo "✔ Brave $VARIANT installed cleanly"
echo "✔ KDE Wallet permanently bypassed"
