# DotRobot

Arch Linux desktop dotfiles for Hyprland, Quickshell, Kitty, and related tools.

Run `./install.sh` as your normal user on Arch. It offers each setup step
separately; `scripts/link-dotfiles.sh` links the tracked configuration into
your home directory. Existing link targets are replaced intentionally, so
review them before running the installer. Wallpapers live in
`~/Pictures/wallpapers` unless changed in Island's wallpaper settings.

The wallpaper picker, Island strip, random keybind, and dynamic palette use
`dotfiles/.config/quickshell/island/scripts/wallpaper.sh`. It supports stills
through `awww` and videos through `mpvpaper`. Night light uses `hyprsunset` and
the user service configured by `scripts/setup-night-light.sh`.

Run all repository checks with `./scripts/test.sh` (requires Bash, Python 3,
Node.js, jq, and the utilities named by individual test scripts). Individual
checks are `scripts/test-*.sh`, `scripts/test-*.py`, and `scripts/test-*.js`.
