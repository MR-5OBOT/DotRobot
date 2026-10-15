# Obsidian GRUB theme

A centered translucent frame over DotRobot's default `reborn.png` wallpaper.
The background symlink reuses `assets/wallpapers/reborn.png`.

From the repository root:

```sh
bash scripts/preview-grub-theme.sh
sudo bash scripts/setup-grub-theme.sh
```

The preview needs QEMU with GTK, edk2-ovmf, xorriso, mtools, and GRUB's tools.
It uses sample entries; it does not boot the installed operating systems.
The footer shows navigation, Enter to boot, C for the GRUB console, E to edit
the selected entry, and Escape to return from the console or editor.

Setup expects the existing working `/boot/EFI/Linux/arch-linux.efi` UKI and a
Windows entry from os-prober. It backs up settings and any previous Obsidian
theme under `/root/grub-obsidian-backup.*`, validates a generated menu before
replacing it, archives Minegrub, and preserves the existing kernel images and
EFI loader. Rerunning updates the theme. A pacman hook keeps the duplicate
traditional kernel generator disabled after GRUB updates.

Only the assets under this directory are copied to `/boot`; the wallpaper
symlink becomes a regular file there. Apply setup again after changing assets.
