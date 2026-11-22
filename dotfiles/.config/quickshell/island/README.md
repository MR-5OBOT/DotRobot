# island

A dynamic-island bar for Hyprland, built with Quickshell.

One black notch hangs from the top edge of every monitor. Click it and the control centre grows out of the notch itself; every other panel opens in the same shape.

It is one part of the quickshell config in `dotfiles/.config/quickshell`: the top-level `shell.qml` loads `island/Island.qml` next to the launcher, clipboard, wallpaper picker, calculator, keymap sheet and power-profile menu, so the whole shell runs as a single `qs` process. Those widgets open from the island and are drawn in the same notch style.

## Features

- **Home** — a click on the notch opens the control centre: a header of workspace dots and every surface's button, the identity card over the live wallpaper with volume-mute, mic-mute and DND toggles, now-playing, clock/weather and live system vitals. A keybind still opens any surface directly.
- **Notch** — flush with the top edge, pure black, concave shoulders, slides out of the screen; panels and the volume/brightness popup share the shape.
- **Music wave** — while something plays, the notch's whole outline (sides, corners, bottom) ripples with the music (cava spectrum, bass mid-bottom) under an accent line; with auto-hide the bottom wave alone hangs from the screen's top edge. cava only runs while music plays and a notch shows the wave.
- **Panels** — calendar with events and reminders, mixer (volume, mic, brightness), battery with power-profile button, system monitor with a speed test, notification inbox and toasts, power menu, settings (display incl. keep-awake).
- **Notifications** — Super+N toggles the notification center on the right of the focused screen. Notifications stack by app with the app icon beside each title; hover to expand, or click the icon to keep a stack expanded. Right-click an app icon to clear its notifications. Cards retain images, actions, unread markers and critical alerts. Dismiss one card or clear the inbox; Escape or clicking outside closes it. The island still owns the notification server and its 3-second toasts (criticals stay until dismissed).
- **Weather** — Open-Meteo forecast on Home's clock card. Location (city level) comes from one HTTPS IP lookup (ipinfo.io).
- **Colours** — surfaces stay black and neutral grey; the accent follows the current wallpaper.
- **Monitors** — the focused screen owns hotkey panels and volume/brightness flashes. Widget clearance is tracked per screen. Shared Hyprland IPC state handles focus changes and display hotplug even when Quickshell's monitor model is empty.

## Requirements

- Hyprland and Quickshell 0.3+
- `upower`, `bluez`, NetworkManager (`nmcli`), `jq`, ImageMagick (`magick`), `awww`, `brightnessctl`, `cliphist` + `wl-clipboard`
- Optional: `power-profiles-daemon` (power profiles), `cava` (music wave)

## Launch

`hypr/lua_configs/autostart.lua` starts `qs` (with jemalloc decay options, so memory stays near the live working set); Super+Alt+N restarts it. Nothing in the island writes into this folder: its state lives under `~/.local/state/island`.

## IPC

Target `island`; the first argument is the monitor (`""` = focused).

```sh
qs ipc call island calendar ""
```

Handlers: `home`, `mixer`, `calendar`, `power`, `battery`, `sysmon`, `peek`, `hide`, `dropToasts`, `page` (any surface by name, for testing). The shell's widgets have their own targets: `qs ipc call launcher|clipboard|wallpicker toggle`.

`qs ipc call notifications toggle` opens the notification center; `notifications hide` closes it. Home's inbox button opens the same panel.

## State and cache

- state: `~/.local/state/island` (flags, calendar events and reminders) and `~/.local/state/island-wallpaper*`
- cache: `~/.cache/island` (palette, thumbnails, weather)
