#!/usr/bin/env bash
set -Eeuo pipefail

if (( EUID != 0 )); then
  printf 'Run: sudo bash %q\n' "$0" >&2
  exit 1
fi
source_dir=$(cd -- "$(dirname -- "$0")/../assets/grub/obsidian" && pwd)
[[ -s /boot/EFI/Linux/arch-linux.efi ]]
[[ -x /etc/grub.d/15_uki ]]
[[ -s "$source_dir/theme.txt" && -s "$source_dir/mono.pf2" && -s "$source_dir/title.pf2" ]]
[[ -s "$source_dir/background.png" && -s "$source_dir/frame.png" ]]

backup=$(mktemp -d /root/grub-obsidian-backup.XXXXXXXX)
cp -p /etc/default/grub /etc/grub.d/00_header /etc/grub.d/10_linux /boot/grub/grub.cfg "$backup/"
if [[ -d /boot/grub/themes/obsidian ]]; then
  cp -a /boot/grub/themes/obsidian "$backup/"
fi
if [[ -f /etc/pacman.d/hooks/05-grub-uki-only.hook ]]; then
  cp -p /etc/pacman.d/hooks/05-grub-uki-only.hook "$backup/"
fi
candidate=$(mktemp /boot/grub/grub.cfg.obsidian.XXXXXXXX)
rollback() {
  trap - ERR INT TERM
  cp -p "$backup/grub" /etc/default/grub
  cp -p "$backup/00_header" /etc/grub.d/00_header
  cp -p "$backup/10_linux" /etc/grub.d/10_linux
  rm -f "$candidate" "$candidate.new" /etc/pacman.d/hooks/05-grub-uki-only.hook
  rm -rf /boot/grub/themes/obsidian
  if [[ -d "$backup/obsidian" ]]; then
    cp -a "$backup/obsidian" /boot/grub/themes/
  fi
  if [[ -f "$backup/05-grub-uki-only.hook" ]]; then
    cp -p "$backup/05-grub-uki-only.hook" /etc/pacman.d/hooks/
  fi
  printf 'Installation stopped; original settings restored. Backup: %s\n' "$backup" >&2
  exit 1
}
trap rollback ERR INT TERM

install -d /boot/grub/themes/obsidian /etc/pacman.d/hooks
install -m 644 "$source_dir/theme.txt" "$source_dir"/*.pf2 "$source_dir"/*.png /boot/grub/themes/obsidian/
install -m 644 "$source_dir/05-grub-uki-only.hook" /etc/pacman.d/hooks/05-grub-uki-only.hook
chmod a-x /etc/grub.d/10_linux
# Undo Minegrub's optional background patch to the packaged generator.
sed -i 's/fi; if \(\[ "x$GRUB_BACKGROUND"\)/elif \1/' /etc/grub.d/00_header
sed -i '/^GRUB_THEME=/d; /^GRUB_BACKGROUND=/d; /^GRUB_DISABLE_BOOTNEXT=/d; /^GRUB_TERMINAL_OUTPUT=/d; /^GRUB_GFXMODE=/d; s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
printf '\nGRUB_THEME=/boot/grub/themes/obsidian/theme.txt\nGRUB_DISABLE_BOOTNEXT=true\nGRUB_TERMINAL_OUTPUT=gfxterm\nGRUB_GFXMODE=1920x1080,1280x720,1024x768,auto\n' >> /etc/default/grub

grub-mkconfig -o "$candidate"
grub-script-check "$candidate"
grep -Eq '^[[:space:]]*uki([[:space:]]|$)' "$candidate"
grep -Fq 'Windows Boot Manager' "$candidate"
grep -Fq '/grub/themes/obsidian/theme.txt' "$candidate"
if grep -Eq 'gnulinux-simple-|gnulinux-advanced-|efi-bootnext-|/themes/minegrub/' "$candidate"; then
  printf 'Unexpected entries or old theme references; keeping the existing menu.\n' >&2
  false
fi

mv -f "$candidate" /boot/grub/grub.cfg
trap - ERR INT TERM
# Archive the old theme and stop its updater only after the new menu is installed.
if [[ -f /etc/systemd/system/minegrub-update.service ]]; then
  if systemctl disable --now minegrub-update.service; then
    mv /etc/systemd/system/minegrub-update.service "$backup/"
    systemctl daemon-reload
  else
    printf 'Could not disable the old updater; its theme files were kept.\n' >&2
    exit 1
  fi
fi
if [[ -d /boot/grub/themes/minegrub ]]; then
  mv /boot/grub/themes/minegrub "$backup/"
fi
printf 'Obsidian installed. Working Arch and Windows entries retained.\nBackup: %s\n' "$backup"
