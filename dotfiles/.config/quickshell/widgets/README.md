# widgets/ — serpantinum's wallpaper popup

Vendored from [serpantinum](https://github.com/ilyamiro/serpantinum) v2.1.5
(commit `cab9a01`), `src/quickshell/`. AGPL-3.0: see `LICENSE.md` here.
Hosted by `../WallpaperPanel.qml`. The network popup was dropped: Wi-Fi is
nm-applet's tray icon.

Only what that popup references is kept (the side bar is gone). Changed from upstream:

- `singletons/theme/ThemeBackend.qml` — reads island's shared palette instead
  of extracting the wallpaper a second time; font and corner radius are fixed
  here (upstream's settings store `Config.qml` and `settings.json` were dropped).
- Click sounds (`Sounds.qml`) and `Caching.qml` were dropped: the sound assets
  aren't vendored, and the picker's cache and run dirs are two fixed paths.
- `Scaler`, `I18n`, `LoaderIcon` and the language assets were dropped: nothing
  used them here; the picker's `s()` returns its input.
- `wallpaper/WallpaperPicker.qml` — scripts resolve inside `widgets/scripts`,
  and `masterWindow.screen` (an id from upstream's Main.qml) became a
  `hostScreen` property the host window sets.
- `singletons/theme/Wallpaper.qml` — only set/get remain: it reads what each
  screen shows from island's `Walls`, and its apply signal is bridged to the
  same backend by `../WallpaperPanel.qml`; awww paints the wallpaper. Upstream's
  playback, clear and IPC calls were dropped.
- `scripts/` — the local wallpaper indexer; monitor names come from `hyprctl` directly.
- `qmldir`, `wallpaper/qmldir` — trimmed to the vendored files.
