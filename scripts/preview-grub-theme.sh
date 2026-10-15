#!/usr/bin/env bash
set -euo pipefail

theme=$(cd -- "$(dirname -- "$0")/../assets/grub/obsidian" && pwd)
[[ -s "$theme/background.png" && -s "$theme/frame.png" ]]
preview=$(mktemp -d /tmp/obsidian-preview.XXXXXXXX)
trap 'rm -rf "$preview"' EXIT
mkdir -p "$preview/iso/boot/grub/themes"
cp -RL "$theme" "$preview/iso/boot/grub/themes/obsidian"
cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$preview/vars.fd"

cat > "$preview/iso/boot/grub/grub.cfg" <<'EOF'
set default=0
set timeout=-1
insmod all_video
insmod gfxterm
insmod gfxmenu
insmod png
set gfxmode=1920x1080,1280x720,1024x768,auto
loadfont /boot/grub/themes/obsidian/mono.pf2
loadfont /boot/grub/themes/obsidian/title.pf2
terminal_output gfxterm
set theme=/boot/grub/themes/obsidian/theme.txt
export theme
menuentry 'Arch Linux' { true; }
menuentry 'Windows Boot Manager (on /dev/nvme0n1p1)' { true; }
menuentry 'UEFI Firmware Settings' { true; }
EOF
grub-mkrescue -o "$preview/preview.iso" "$preview/iso" > "$preview/build.log" 2>&1 || {
  cat "$preview/build.log" >&2
  exit 1
}

# Preview entries only; the VM never attaches host disks.
qemu-system-x86_64 \
  -name 'Obsidian GRUB preview' \
  -machine q35,accel=tcg -m 256 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive "if=pflash,format=raw,file=$preview/vars.fd" \
  -cdrom "$preview/preview.iso" -boot d \
  -display gtk -net none -no-reboot
