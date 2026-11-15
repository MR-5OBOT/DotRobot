# Obsidian GRUB theme

A centered translucent frame over DotRobot's default `mr5obot-prpl.jpg` wallpaper.
`background.jpg` is that wallpaper saved as a baseline JPEG, since GRUB can't
read progressive JPEGs; re-export it after changing the wallpaper.

From the repository root:

```sh
bash scripts/preview-grub-theme.sh
sudo bash scripts/setup-grub-theme.sh
```

The preview needs QEMU with GTK, edk2-ovmf, xorriso, mtools, and GRUB's tools.
It uses sample entries; it does not boot the installed operating systems.
The footer shows navigation, Enter to boot, C for the GRUB console, E to edit
the selected entry, and Escape to return from the console or editor.

Setup works on any GRUB install: plain kernel entries or a UKI, with or without
Windows. Its settings are tagged lines (`# obsidian-grub-theme`) at the end of
`/etc/default/grub`, and the new menu replaces the old one only after it checks
out. Rerunning updates the theme. To remove it, delete those lines and
`/boot/grub/themes/obsidian`, then run `sudo grub-mkconfig -o /boot/grub/grub.cfg`
(the script's header has the exact commands).

Only the assets under this directory are copied to `/boot`. Apply setup again
after changing them.
