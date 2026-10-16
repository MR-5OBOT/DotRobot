# DotRobot

Arch Linux desktop dotfiles for Hyprland, Quickshell, Kitty, and related tools.

Run `./install.sh` as your normal user on Arch. It offers each setup step
separately; `scripts/link-dotfiles.sh` links the tracked configuration into
your home directory. Existing link targets are replaced intentionally, so
review them before running the installer. Wallpapers live in
`~/Pictures/wallpapers` unless changed in Island's wallpaper settings.

For a machine with a cellular modem, the installer offers
`./scripts/setup-mobile-broadband.sh`, which also runs on its own. It asks
before installing packages (including an Arch upgrade), enabling services,
saving a connection, or connecting. Its carrier menu includes Maroc Telecom
(subscription/Jawal), Orange Morocco, inwi, a custom APN, and setup later.
APNs and usernames are editable; existing connections are preserved. New
connections have autoconnect and roaming off and are marked as metered.
SIM PINs and APN passwords are requested by `nmcli --ask` when connecting;
the script does not save them. An activated SIM/data plan is needed to connect.
Before connecting it offers modem/SIM-slot selection, waits for a switched modem
to reappear, and checks SIM readiness. For the DW5825e, slot 1 is the physical
SIM and slot 2 is the eSIM. An empty eSIM profile or missing SIM stops the
connection attempt before carrier authentication; insert the SIM and re-run.
It skips machines without kernel WWAN/MBIM/QMI ports; BIOS-disabled modems,
missing drivers and serial-only modems need separate detection/setup.
Failed connections show recent ModemManager logs, with guidance for radio
blocks and [vendor FCC-unlock requirements](https://modemmanager.org/docs/modemmanager/fcc-unlock/).
For the Dell DW5825e/Fibocom FM101R-GL (`413c:8213`), the script offers to
build/install the local `fibocom-fm101r-unlock` Arch package and enable its
two helpers. It uses pinned [Fibocom vendor code](https://github.com/fibocom-pc/linux_apps_opensource)
and its unlock binary, with root-only D-Bus/IPC access. It installs no
firmware images or flashing services. It installs missing build tools and
runtime dependencies, starts the helpers, runs the unlock immediately, and
reads back the hardware radio state before reporting success.
The helpers and ModemManager unlock hook persist across reboots. An existing
internet connection and sudo access are needed; no files from `/tmp` are required.
Preset references: [Orange's setup guide](https://www.orange.ma/Assistance/Mobiles-et-tablettes/Utiliser-votre-tablette),
the installed `mobile-broadband-provider-info` database for IAM plans, and
the [ASUS router carrier database](https://github.com/RMerl/asuswrt-merlin.ng/blob/main/release/src/router/rom/spn_asus.dat) for inwi.

The wallpaper picker, Island strip, random keybind, and dynamic palette use
`dotfiles/.config/quickshell/island/scripts/wallpaper.sh`. It supports stills
through `awww` and videos through `mpvpaper`.

`Super+D` opens the Quickshell workspace overview with previews for workspaces
0–10 that contain windows. Hold Super and use Tab/Shift+Tab or arrow keys to
cycle through the occupied workspaces. Release Super to switch.
Enter or a click also switches; Escape or a click outside cancels.
Workspace 0 is named `0`; Super+0 still selects workspace 10.
Run its logic checks with `node tests/workspaces.test.cjs`.

The [Obsidian GRUB theme](assets/grub/obsidian) uses the default wallpaper with
a centered translucent frame. Preview it with `bash scripts/preview-grub-theme.sh`;
apply it with `sudo bash scripts/setup-grub-theme.sh` on the UKI/Windows setup.
