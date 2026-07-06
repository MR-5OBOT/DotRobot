# Quickshell migration TODO

Replace shell UI pieces with one `qs` config (Quickshell v0.3.0).
Style: dark #101010, muted pink accent (#862F55), no rounded corners, defined once in `Theme.qml`.
Suggested order: bar → notifications → popups → OSD → lock → wallpaper → idle.

## References (consult for hovers/popouts/patterns)
- Type docs: https://quickshell.org/docs/v0.3.0/types/
- caelestia: `quickshell-refs/shell/` (uses a C++ plugin — read patterns, don't copy wholesale)
- end-4:     `quickshell-refs/dots-hyprland/`

## Gotchas (this box)
- **Hyprland runs the lua IPC plugin.** `dispatch X` is eval'd as `hl.dispatch(X)`. Workspace switch = `Hyprland.dispatch("hl.dsp.focus({workspace=N})")`, not `"workspace N"`.
- Qt's JS engine (V4) has **no regex lookbehind** — don't use `(?<!\\)` in QML.
- Native `Quickshell.Networking` returns 0 devices here → parse `nmcli` via `Process`.
- Tray menus need `//@ pragma UseQApplication` at the top of `shell.qml`.

## Run it (waybar untouched, run side by side)
`qs -p dotfiles/.config/quickshell/shell.qml`  (or `qs` once `~/.config/quickshell` is linked)

## Bar — DONE (dotfiles/.config/quickshell/)
Auto-hiding vertical left panel, layer Top, exclusiveZone 0 (fullscreen feel): collapses to a 3px
peek strip, hovering the edge slides the full bar out; input `mask` so the collapsed strip doesn't
block windows. `BarState.qml` singleton keeps it revealed while a popup is open. Popouts are
borderless, flush to the bar, with M3 fade+overshoot anim.
Files: `Bar.qml` · `BarState.qml` · `Theme.qml` · `Popout.qml` · `Clock.qml`(+calendar icon)+`Calendar.qml`
(month grid) · `Workspaces.qml` (caelestia-style square pips: dot=empty/filled=occupied/pink=focused)
· `Media.qml` (Mpris art+controls) · `Bluetooth.qml` (bluetoothctl) · `Network.qml` (nmcli) ·
`Volume.qml` (Pipewire out+mic) · `Battery.qml` (UPower) · `Tray.qml` (filters out nm-applet/blueman).
TODO polish: rotated scrolling track title; volume drag slider; tray right-click menu.

## Full replacements

- [x] **waybar** → built in `.config/quickshell/` (see "Bar — DONE" above). Switched: waybar out of
      autostart (Super+B still toggles it back as fallback), `qs` autostarts.
- [x] **swaync + dunst** → `NotificationServer` toasts DONE (`Notifications.qml` + `NotifCard.qml`).
      Top-right stack, content-hug width, urgency timeouts (low 4s/normal 8s/critical persists), markdown
      body, actions, app-icon fallback, drag-to-dismiss, animated close button. **Exclusive D-Bus name**:
      swaync removed from `autostart.lua` (qs autostarts instead, waybar line commented out;
      Super+Shift+N restarts qs, Super+N parked until the notification center exists).
      (Top-panel calendar experiment was purged — the bar clock popout covers it, now with
      prev/next month nav.) TODO: notification center UI, DND toggle, sounds.
- [ ] **rofi powermenu** (`powermenu.rasi`, `rofi-powermenu.sh`, `empty-rightclick.sh`) → popup window + `HyprlandFocusGrab`
      — "toggle if open" pgrep/pkill dance becomes a visibility toggle.
- [x] **rofi app launcher** → `Launcher.qml` DONE: DesktopEntries + prefix/substring filter, 3 rows,
      no icons, keyboard-driven (↑↓/Tab/Enter/Esc), click-outside closes (HyprlandFocusGrab).
      Toggle: `qs -p ~/.config/quickshell/shell.qml ipc call launcher toggle` — rofi still bound to
      Super+Space until swapped in keymaps.lua.
- [ ] **whichkey.sh** → QML GridLayout popup, binds loaded via `FileView` + `JsonAdapter`
      — kills the bash string-padding column layout.
- [ ] **walls-picker.sh** → grid popup with `Image` thumbnails + `ClippingRectangle`
      — real previews instead of rofi filename list.
- [ ] **hyprpaper** → per-screen background layer (`Variants` over `Quickshell.screens` + `WlrLayershell` background + `Image`)
      — kills the daemon and the `hyprctl hyprpaper reload` IPC; fade transitions free; `ColorQuantizer` for accent colors if wanted.
- [ ] **hyprlock + gtklock** → `WlSessionLock` + `WlSessionLockSurface` + `Services.Pam.PamContext`
      — same ext-session-lock protocol, drops two packages.
- [ ] **hypridle** → `Wayland.IdleMonitor` timeouts → `Process` (dpms off / lock) + `IdleInhibitor` toggle in bar
- [ ] **volume.sh / brightness.sh** → OSD overlay layer window with a bar
      — volume reactive from `PwNodeAudio`; brightness via `Process` (brightnessctl). Stops abusing notifications as OSD.
- [ ] **BAT-check.sh** → `UPowerDevice.percentage`/`.state` binding fires notification under 10% discharging
      — no polling loop, no acpi dep.
- [ ] **nm-applet** → `Quickshell.Networking` (`WifiDevice`, `WifiNetwork`) wifi menu in bar

## Partial — QS does UI, tool stays as backend

- [ ] **screenshot.sh menu** (`screenshot.rasi`) → QS popup; grim/satty stay via `Process`
      — stretch: `ScreencopyView` freeze-frame region picker with window-box snapping (fixes the "slurp can't survive a sleep" delay-mode limitation).
- [ ] **recording** (`wf-screenRE`, `stop-recording`) → QS start/stop menu + live bar indicator via `Process.running`; wf-recorder stays
- [ ] **clipse UI** (optional) → history popup over cliphist via `Process`; skip unless theming consistency itches
- [ ] **speedtest.sh** (marginal) → result popup; CLI stays
- [ ] **hyprpolkitagent** (last) → `Services.Polkit.PolkitAgent` for 100% visual consistency

## Not replaceable

hyprland.lua configs (QS is not a compositor — but `Hyprland.GlobalShortcut` can trigger QS popups directly from keybinds), kitty, tmux, zsh, yazi, zathura, mpv, glow, fastfetch, uwsm, xdgportals.sh.

## End state

Autostart shrinks from `hyprpaper + swaync + nm-applet + hypridle + waybar + BAT-check` to `qs` (+ clipse). All `.rasi` files, dunstrc, swaync CSS, and waybar CSS collapse into one QML theme.
