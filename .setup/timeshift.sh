#!/bin/bash

# ==============================================================================
# Automated Setup Script for Timeshift on Wayland Environments
# Supports various Linux distributions.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display messages
echo_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

echo_warn() {
    echo -e "\e[33m[WARN]\e[0m $1"
}

echo_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

# Function to detect package manager
detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v emerge &> /dev/null; then
        echo "emerge"
    else
        echo "unknown"
    fi
}

# Function to install packages
install_package() {
    PACKAGE_MANAGER=$(detect_package_manager)
    PACKAGE=$1

    case $PACKAGE_MANAGER in
        pacman)
            sudo pacman -Sy --noconfirm "$PACKAGE"
            ;;
        apt)
            sudo apt-get update
            sudo apt-get install -y "$PACKAGE"
            ;;
        dnf)
            sudo dnf install -y "$PACKAGE"
            ;;
        zypper)
            sudo zypper install -y "$PACKAGE"
            ;;
        yum)
            sudo yum install -y "$PACKAGE"
            ;;
        emerge)
            sudo emerge "$PACKAGE"
            ;;
        *)
            echo_error "Unsupported package manager. Please install $PACKAGE manually."
            exit 1
            ;;
    esac
}

# Check if running on Wayland
if [ -z "$WAYLAND_DISPLAY" ]; then
    echo_warn "WAYLAND_DISPLAY not detected. This script is intended for Wayland environments."
    read -p "Do you want to continue? (y/N): " choice
    case "$choice" in
        y|Y ) ;;
        * ) echo_info "Exiting."; exit 1;;
    esac
fi

# Ensure polkit is installed
if ! command -v pkexec &> /dev/null; then
    echo_info "Polkit not found. Installing polkit..."
    install_package "polkit"
else
    echo_info "Polkit is already installed."
fi

# Ensure timeshift is installed
if ! command -v timeshift &> /dev/null; then
    echo_info "Timeshift not found. Installing timeshift..."
    install_package "timeshift"
else
    echo_info "Timeshift is already installed."
fi

# Create Polkit Policy for Timeshift
POLKIT_POLICY_FILE="/usr/share/polkit-1/actions/org.timeshift.timeshift-gtk.policy"

if [ ! -f "$POLKIT_POLICY_FILE" ]; then
    echo_info "Creating Polkit policy for Timeshift..."
    sudo tee "$POLKIT_POLICY_FILE" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
"http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
<policyconfig>
  <action id="org.timeshift.timeshift-gtk">
    <description>Run Timeshift GTK Interface</description>
    <message>Authentication is required to run Timeshift</message>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
  </action>
</policyconfig>
EOF
    echo_info "Polkit policy for Timeshift created at $POLKIT_POLICY_FILE."
else
    echo_info "Polkit policy for Timeshift already exists at $POLKIT_POLICY_FILE."
fi

# Determine the location of the Timeshift.desktop file
DESKTOP_FILES=(
    "/usr/share/applications/timeshift-gtk.desktop"
    "$HOME/.local/share/applications/timeshift-gtk.desktop"
)

DESKTOP_FILE=""
for file in "${DESKTOP_FILES[@]}"; do
    if [ -f "$file" ]; then
        DESKTOP_FILE="$file"
        break
    fi
done

if [ -z "$DESKTOP_FILE" ]; then
    echo_info "No existing Timeshift.desktop file found. Creating one in /usr/share/applications/."
    DESKTOP_FILE="/usr/share/applications/timeshift.desktop"
    sudo tee "$DESKTOP_FILE" > /dev/null <<EOF
[Desktop Entry]
Name=Timeshift
Exec=pkexec timeshift-gtk
Type=Application
GenericName=System Restore Utility
GenericName[ca]=Utilitat de restauració del sistema
GenericName[cs]=Nástroj pro obnovení systému
GenericName[da]=Værktøj til systemgendannelse
GenericName[fr]=Utilitaire de restauration système
GenericName[hr]=Alat obnove sustava
GenericName[ja]=システムの復元ユーティリティ
GenericName[ko]=시스템 복원 유틸리티
GenericName[lt]=Sistemos atkūrimo paslaugų programa
GenericName[nl]=Hulpmiddel voor systeemherstel
GenericName[ru]=Программа для восстановления системы
Terminal=false
Icon=timeshift
Comment=System Restore Utility
Comment[ca]=Utilitat de restauració del sistema
Comment[cs]=Nástroj pro obnovení systému
Comment[da]=Værktøj til systemgendannelse
Comment[fr]=Utilitaire de restauration système
Comment[hr]=Alat obnove sustava
Comment[ja]=システムの復元ユーティリティ
Comment[ko]=시스템 복원 유틸리티
Comment[lt]=Sistemos atkūrimo paslaugų programa
Comment[nl]=Hulpmiddel voor systeemherstel
Comment[ru]=Программа для восстановления системы
X-KDE-StartupNotify=false
Categories=System;
X-GNOME-UsesNotifications=true
Keywords=backup;btrfs;rsync;
EOF
    echo_info "Created Timeshift.desktop at $DESKTOP_FILE."
else
    echo_info "Found Timeshift.desktop at $DESKTOP_FILE."
fi

# Backup existing Timeshift.desktop
BACKUP_FILE="${DESKTOP_FILE}.bak.$(date +%s)"
echo_info "Backing up existing Timeshift.desktop to $BACKUP_FILE."
sudo cp "$DESKTOP_FILE" "$BACKUP_FILE"

# Modify the Exec line to use pkexec
echo_info "Modifying Exec line in Timeshift.desktop to use pkexec..."

# Use sudo tee and sed to modify the Exec line
sudo sed -i 's|^Exec=.*|Exec=pkexec timeshift-gtk|' "$DESKTOP_FILE"

# Ensure Terminal is false
sudo sed -i 's/^Terminal=.*/Terminal=false/' "$DESKTOP_FILE"

echo_info "Timeshift.desktop has been updated to use pkexec."

# Optional: Create a Wrapper Script (if preferred over pkexec)
# Uncomment the following block if you want to use a wrapper script instead of pkexec.

: '
# Create Wrapper Script
WRAPPER_SCRIPT_DIR="$HOME/bin"
WRAPPER_SCRIPT="$WRAPPER_SCRIPT_DIR/timeshift-launcher.sh"

echo_info "Creating wrapper script at $WRAPPER_SCRIPT..."
mkdir -p "$WRAPPER_SCRIPT_DIR"
cat <<'EOF' > "$WRAPPER_SCRIPT"
#!/bin/bash
# Wrapper script to launch timeshift-gtk with necessary environment variables

# Export WAYLAND_DISPLAY and DBUS_SESSION_BUS_ADDRESS for the elevated process
export WAYLAND_DISPLAY=\$WAYLAND_DISPLAY
export DBUS_SESSION_BUS_ADDRESS=\$DBUS_SESSION_BUS_ADDRESS

# Launch timeshift-gtk with sudo, preserving the environment
sudo -E timeshift-gtk
EOF

# Make the script executable
chmod +x "$WRAPPER_SCRIPT"

# Modify the Exec line to use the wrapper script
echo_info "Modifying Exec line in Timeshift.desktop to use the wrapper script..."
sudo sed -i "s|^Exec=.*|Exec=$WRAPPER_SCRIPT|" "$DESKTOP_FILE"

# Set Terminal=true
sudo sed -i 's/^Terminal=.*/Terminal=true/' "$DESKTOP_FILE"

echo_info "Timeshift.desktop has been updated to use the wrapper script."
'

# Refresh Desktop Database (if applicable)
echo_info "Refreshing desktop database..."
if command -v update-desktop-database &> /dev/null; then
    sudo update-desktop-database
    echo_info "Desktop database refreshed."
else
    echo_warn "update-desktop-database command not found. You may need to refresh your desktop environment manually."
fi

echo_info "Setup complete! You can now launch Timeshift from your application launcher with elevated privileges."

echo_info "If you encounter any issues, please refer to the backup file at $BACKUP_FILE or consult the documentation."

# End of Script

