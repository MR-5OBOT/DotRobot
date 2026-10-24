# island

A dynamic-island bar for Hyprland, built with Quickshell.

One black notch hangs from the top edge of every monitor. Click it and the control centre grows out of the notch itself; every other panel opens in the same shape.

It is one part of the quickshell config in `dotfiles/.config/quickshell`: the top-level `shell.qml` loads `island/Island.qml` next to the launcher, clipboard, wallpaper picker, wifi panel, calculator and power-profile menu, so the whole shell runs as a single `qs` process. Those widgets open from the island and are drawn in the same notch style.

## Features

- **Home** — a click on the notch opens the control centre: a header of workspace dots and every surface's button, the identity card over the live wallpaper with volume-mute, mic-mute and DND toggles, now-playing, clock/weather and live system vitals. A keybind still opens any surface directly.
- **Notch** — flush with the top edge, pure black, concave shoulders, slides out of the screen; panels and the volume/brightness popup share the shape.
- **Panels** — calendar with events and reminders, mixer (volume, mic, brightness), battery with power-profile button, system monitor with a speed test, notification inbox and toasts, minimized-window stash, power menu, settings (display incl. keep-awake).
- **Notifications** — Super+N toggles the notification center on the right of the focused screen. Notifications stack by app with the app icon beside each title; hover to expand, or click the icon to keep a stack expanded. Right-click an app icon to clear its notifications. Cards retain images, actions, unread markers and critical alerts. Dismiss one card or clear the inbox; Escape or clicking outside closes it. The island still owns the notification server and its 8-second toasts.
- **Weather** — Open-Meteo forecast on Home's clock card. Location comes from GeoClue (wifi networks in range) and falls back to an IP lookup.
- **Colours** — surfaces stay black and neutral grey; the accent follows the current wallpaper.
- **Monitors** — the focused screen owns hotkey panels and volume/brightness flashes. Widget clearance is tracked per screen. Shared Hyprland IPC state handles focus changes and display hotplug even when Quickshell's monitor model is empty.

## Requirements

- Hyprland and Quickshell 0.3+
- `upower`, `bluez`, NetworkManager (`nmcli`), `jq`, ImageMagick (`magick`), `awww`, `brightnessctl`, `cliphist` + `wl-clipboard`
- Optional: `power-profiles-daemon` (power profiles), `geoclue` (precise weather location)

## Launch

`hypr/lua_configs/autostart.lua` starts `qs` (with jemalloc decay options, so memory stays near the live working set); Super+Shift+N restarts it. Nothing in the island writes into this folder: its state lives under `~/.local/state/island`.

## IPC

Target `island`; the first argument is the monitor (`""` = focused).

```sh
qs ipc call island calendar ""
```

Handlers: `home`, `mixer`, `calendar`, `launcher`, `power`, `link`, `battery`, `sysmon`/`system`, `clipboard`, `wallpaper`, `peek`, `hide`, `unloadAll`, `page`, `nav`. `launcher`, `clipboard` and `wallpaper` open the shell's own widgets.

`qs ipc call notifications toggle` opens the notification center; `notifications hide` closes it. The island's `link`, `page "" link` and `nav "" link` routes open the same panel.

Run `bash tests/notifications.sh` from the repository to check grouping, stacked-card layout, expansion and clearing on an isolated D-Bus session.

## Precise location (GeoClue)

GeoClue needs an agent to authorise requests; the island starts GeoClue's demo agent itself. If the default wifi database does not know your area, point GeoClue at another one:

```sh
sudo pacman -S geoclue
printf '[wifi]\nurl=https://api.positon.xyz/v1/geolocate?key=56aba903-ae67-4f26-919b-15288b44bda9\n' | sudo tee /etc/geoclue/conf.d/90-positon.conf
```

Check with `/usr/lib/geoclue-2.0/demos/where-am-i -t 30`; an accuracy of a few dozen metres means wifi location works.

## State and cache

- state: `~/.local/state/island` (flags, calendar events and reminders, spaces) and `~/.local/state/island-wallpaper*`
- cache: `~/.cache/island` (palette, thumbnails, weather)
