#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

if (( EUID != 0 )); then
  printf 'Run this script with sudo.\n' >&2
  exit 1
fi

for required in nmcli ufw ip python3; do
  command -v "$required" >/dev/null || { printf 'Missing command: %s\n' "$required" >&2; exit 1; }
done

wifi_device=wlan0
profile_uuid=f8cbfb5b-5667-4ca0-9c60-d1247c5f8298

if [[ $(nmcli -g 802-11-wireless.mode connection show uuid "$profile_uuid") != ap ||
      $(nmcli -g ipv4.method connection show uuid "$profile_uuid") != shared ]]; then
  printf 'The saved Hotspot profile is not configured for shared access-point mode. Stopping.\n' >&2
  exit 1
fi

nmcli radio wifi on
nmcli --wait 30 connection up uuid "$profile_uuid" ifname "$wifi_device"

hotspot_cidr=$(nmcli -g IP4.ADDRESS device show "$wifi_device" | awk 'NF { print; exit }')
network_details=$(python3 - "$hotspot_cidr" <<'PY'
import ipaddress
import sys
address = ipaddress.IPv4Interface(sys.argv[1])
if not address.ip.is_private:
    raise SystemExit("The hotspot does not have a private IPv4 address. Stopping.")
print(address.ip, address.network)
PY
)
read -r hotspot_address hotspot_network <<< "$network_details"

uplink=$(ip -4 route get 1.1.1.1 | awk '{ for (i=1; i<NF; i++) if ($i == "dev") { print $(i+1); exit } }')
if [[ -z "$uplink" || "$uplink" == "$wifi_device" ]]; then
  printf 'No separate internet uplink was found. Stopping before changing firewall rules.\n' >&2
  exit 1
fi

firewall_status=$(ufw status)
if [[ "$firewall_status" != *'Status: active'* ]]; then
  printf 'UFW is not active. No firewall rules were changed.\n' >&2
  exit 1
fi

backup_dir=$(mktemp -d /var/tmp/mr5obot-hotspot-ufw.XXXXXX)
cp -a /etc/ufw/user.rules /etc/ufw/user6.rules "$backup_dir/"
printf 'Firewall backup: %s\n' "$backup_dir"

# Allow initial DHCP requests, including clients that do not have an address yet.
ufw allow in on "$wifi_device" to 0.0.0.0/0 port 67 proto udp comment 'mr5obot hotspot DHCP'
# Limit DNS access to clients on the hotspot subnet.
ufw allow in on "$wifi_device" from "$hotspot_network" to "$hotspot_address" port 53 proto udp comment 'mr5obot hotspot DNS UDP'
ufw allow in on "$wifi_device" from "$hotspot_network" to "$hotspot_address" port 53 proto tcp comment 'mr5obot hotspot DNS TCP'
# Permit hotspot clients to use the current internet uplink.
ufw route allow in on "$wifi_device" out on "$uplink" from "$hotspot_network" to any comment 'mr5obot hotspot internet'

printf '\nHotspot: %s (%s), internet uplink: %s\n' "$hotspot_address" "$hotspot_network" "$uplink"
nmcli -f GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS device show "$wifi_device"
ufw status
printf '\nRules applied. On your phone, forget mr5obot-desktop and reconnect with the existing password.\n'
