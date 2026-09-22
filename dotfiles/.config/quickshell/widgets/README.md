# widgets/ — serpantinum's network and wallpaper popups

Vendored from [serpantinum](https://github.com/ilyamiro/serpantinum) v2.1.5
(commit `cab9a01`), `src/quickshell/`. AGPL-3.0: see `LICENSE.md` here.
Hosted by `../NetworkPanel.qml` and `../WallpaperPanel.qml`; `settings.json`
seeds the writable user settings.

Only what those two popups reference is kept (the side bar is gone). Changed from upstream:

- `singletons/theme/ThemeBackend.qml` — rewritten. The palette comes from the
  current wallpaper (quickshell's `ColorQuantizer`) instead of matugen, which
  also sends SIGUSR1 to every running kitty.
- `singletons/audio/Sounds.qml` — no-op stub; the sound assets aren't vendored.
- `singletons/system/Config.qml` — reads `~/.config/mr5obot/settings.json`.
- `network/NetworkPopup.qml` — reads its helper script from this folder
  instead of `$QS_DIR/network`.
- `wallpaper/WallpaperPicker.qml` — scripts resolve inside `widgets/scripts`,
  and `masterWindow.screen` (an id from upstream's Main.qml) became a
  `hostScreen` property the host window sets.
- `singletons/theme/Matugen.qml` — no-op stub. Upstream regenerates the palette
  with matugen and SIGUSR1s every kitty; ThemeBackend derives colours itself.
- `singletons/theme/Wallpaper.qml` — vendored as-is. Its `wallpaperChanged`
  signal is bridged to WallpaperState by ../WallpaperPanel.qml; upstream's
  WallpaperEngine is not vendored (awww paints the wallpaper here).
- `scripts/` — monitors_detect.sh and the local wallpaper indexer.
- `qmldir`, `network/qmldir`, `wallpaper/qmldir` — trimmed to the vendored files.
- `assets/languages/en.json` — vendored so `I18n` can resolve keys;
  `singletons/system/I18n.qml` reads this folder instead of `$SERPANTINUM_DIR`.
