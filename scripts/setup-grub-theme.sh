#!/usr/bin/env bash
# Obsidian GRUB theme for any GRUB install: plain kernel entries or a UKI, with or without Windows.
# Its settings are tagged lines at the end of /etc/default/grub, the file GRUB's manual documents
# (/etc/default/grub.d/ is a distro patch that an update could drop). Later lines win, so they
# override older theme settings above them. Undo:
#   sudo sed -i '/# obsidian-grub-theme$/d' /etc/default/grub
#   sudo rm -r /boot/grub/themes/obsidian && sudo grub-mkconfig -o /boot/grub/grub.cfg
# Rerun after changing the theme assets.
set -euo pipefail

if (( EUID != 0 )); then
  printf 'Run: sudo bash %q\n' "$0" >&2
  exit 1
fi
src=$(cd -- "$(dirname -- "$0")/../assets/grub/obsidian" && pwd)
theme=/boot/grub/themes/obsidian
conf=/etc/default/grub
mark='# obsidian-grub-theme'

install -d "$theme"
install -m 644 "$src/theme.txt" "$src"/*.pf2 "$src"/*.png "$src"/*.jpg "$theme/"
sed -i "/$mark\$/d" "$conf"
[[ -z $(tail -c1 "$conf") ]] || echo >>"$conf"
# GRUB_DISABLE_BOOTNEXT: firmware "boot next" entries would crowd the themed menu.
cat >>"$conf" <<EOF
GRUB_THEME=$theme/theme.txt $mark
GRUB_TERMINAL_OUTPUT=gfxterm $mark
GRUB_GFXMODE=1920x1080,1280x720,1024x768,auto $mark
GRUB_DISABLE_BOOTNEXT=true $mark
EOF

# Build the menu beside the live one and swap it in only if it is valid, boots something and loads the theme.
new=$(mktemp /boot/grub/grub.cfg.XXXXXX)
trap 'rm -f "$new"' EXIT
grub-mkconfig -o "$new"
grub-script-check "$new"
grep -Eq '^[[:space:]]*(menuentry|uki)([[:space:]]|$)' "$new" || { echo "The new menu has no boot entry; kept the old one." >&2; exit 1; }
# grub-mkconfig writes the path relative to its partition: /grub/... when /boot is its own partition
grep -Fq "${theme#/boot}/theme.txt" "$new" || { echo "The new menu doesn't load the theme; kept the old one." >&2; exit 1; }
mv -f "$new" /boot/grub/grub.cfg
echo "Obsidian installed; reboot to see it."
