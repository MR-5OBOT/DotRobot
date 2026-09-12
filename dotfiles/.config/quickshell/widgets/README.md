# widgets/ — serpantinum's side bar

Vendored from [serpantinum](https://github.com/ilyamiro/serpantinum) v2.1.5
(commit `cab9a01`), `src/quickshell/`. AGPL-3.0: see `LICENSE.md` here.
Hosted by `../FullBar.qml`, configured by `settings.json`.

Only the side bar and what it references were copied. Changed from upstream:

- `singletons/theme/ThemeBackend.qml` — rewritten. The palette comes from the
  current wallpaper (quickshell's `ColorQuantizer`) instead of matugen, which
  also sends SIGUSR1 to every running kitty.
- `singletons/environment/Weather.qml` — rewritten. Calls open-meteo directly.
  Location is `general.location` in `settings.json`, or an IP lookup cached in
  `~/.cache/dotrobot/weather/` — never written into `settings.json`.
- `singletons/audio/Sounds.qml` — no-op stub; the sound assets aren't vendored.
- `singletons/system/Config.qml` — reads `widgets/settings.json` from this shell.
- `bar/sidemodules/SideTrayWidget.qml` — tray menus use `QsMenuAnchor`;
  serpantinum's tray popup lives in its `Main.qml`, which isn't vendored.
- `bar/sidemodules/**` — buttons that ran `scripts/qs_manager.sh` now call this
  shell's IPC targets (`launcher`, `calendar`, `wifi`,
  `powerprofile`) or apps (`pavucontrol`); the media art click plays/pauses.
- `calendar/CalendarPopup.qml` — `weatherData` falls back to an empty
  forecast; upstream's bindings throw on the frames before data arrives.
  The right-hand weather panel is hidden and the width cut to 1000.
- `network/NetworkPopup.qml` — reads its helper script from this folder
  instead of `$QS_DIR/network`.
- `wallpaper/WallpaperPicker.qml` — scripts resolve inside `widgets/scripts`, its
  `Settings` takes a file:// URL, and `masterWindow.screen` (an id from
  upstream's Main.qml) became a `hostScreen` property the host window sets.
- `singletons/theme/Matugen.qml` — no-op stub. Upstream regenerates the palette
  with matugen and SIGUSR1s every kitty; ThemeBackend derives colours itself.
- `singletons/theme/Wallpaper.qml` — vendored as-is. Its `wallpaperChanged`
  signal is bridged to WallpaperState by ../WallpaperPanel.qml; upstream's
  WallpaperEngine is not vendored (awww paints the wallpaper here).
- `scripts/` — monitors_detect.sh and the wallpaper helpers (indexer, DDG search).
- `qmldir`, `bar/qmldir`, `network/qmldir`, `wallpaper/qmldir` — trimmed to the vendored files.
- `assets/languages/en.json` — vendored so `I18n` can resolve keys;
  `singletons/system/I18n.qml` reads this folder instead of `$SERPANTINUM_DIR`.
