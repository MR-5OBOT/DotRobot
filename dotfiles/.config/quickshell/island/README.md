# island

A dynamic-island bar for Hyprland, built with Quickshell.

One black notch hangs from the top edge of every monitor. Hover it and it expands in place into a control row — workspace dots, clock, media, weather and status icons — and each panel grows out of the notch itself.

It is one part of the quickshell config in `dotfiles/.config/quickshell`: the top-level `shell.qml` loads `island/Island.qml` next to the launcher, clipboard, wallpaper picker, wifi/bluetooth panel, calculator and power-profile menu, so the whole shell runs as a single `qs` process. Those widgets open from the island and are drawn in the same notch style.

## Features

- **Notch** — flush with the top edge, pure black, concave shoulders, slides out of the screen; panels and the volume/brightness popup share the shape.
- **Panels** — calendar with events and reminders, weather, media player, mixer (volume, mic, brightness, DND, keep-awake, night light), battery with power-profile button, system monitor with a speed test, notification inbox and toasts, minimized-window stash, power menu, settings (display, font, interface).
- **Notifications** — the island owns the notification server: toasts stay 8 seconds, the inbox shows each notification's title, body and icon.
- **Weather** — Open-Meteo forecast in a wide panel. Location comes from GeoClue (wifi networks in range), falls back to an IP lookup, and can be overridden by typing a town or exact `lat,lon`.
- **Colours** — surfaces stay black and neutral grey; the accent follows the current wallpaper.

## Requirements

- Hyprland and Quickshell 0.3+
- `upower`, `bluez`, NetworkManager (`nmcli`), `jq`, ImageMagick (`magick`), `awww`, `brightnessctl`, `cliphist` + `wl-clipboard`
- Optional: `cava` (music bars), `hyprsunset` (night light), `power-profiles-daemon` (power profiles), `geoclue` (precise weather location)

## Launch

`hypr/lua_configs/autostart.lua` starts `qs` (with jemalloc decay options, so memory stays near the live working set); Super+Shift+N restarts it. Nothing in the island writes into this folder: its state lives under `~/.local/state/island`.

## IPC

Target `island`; the first argument is the monitor (`""` = focused).

```sh
qs ipc call island calendar ""
qs ipc call island page "" weather
```

Handlers: `mixer`, `calendar`, `launcher`, `power`, `link`, `battery`, `sysmon`/`system`, `clipboard`, `wallpaper`, `media`, `peek`, `hide`, `unloadAll`, `page`, `minimizeWindow`, `restoreWindow`. `launcher`, `clipboard` and `wallpaper` open the shell's own widgets.

## Precise location (GeoClue)

GeoClue needs an agent to authorise requests; the island starts GeoClue's demo agent itself. If the default wifi database does not know your area, point GeoClue at another one:

```sh
sudo pacman -S geoclue
printf '[wifi]\nurl=https://api.positon.xyz/v1/geolocate?key=56aba903-ae67-4f26-919b-15288b44bda9\n' | sudo tee /etc/geoclue/conf.d/90-positon.conf
```

Check with `/usr/lib/geoclue-2.0/demos/where-am-i -t 30`; an accuracy of a few dozen metres means wifi location works.

## State and cache

- state: `~/.local/state/island` (flags, calendar events and reminders, spaces, night light) and `~/.local/state/island-wallpaper*`
- cache: `~/.cache/island` (palette, thumbnails, weather)
