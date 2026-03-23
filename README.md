# DotRobot

Arch-only dotfiles with a single interactive installer.

## Layout

- `dotfiles/`: files that get symlinked into `$HOME`
- `scripts/`: reusable setup actions
- `packages/arch/`: package groups and `pacman.conf`
- `assets/`: optional wallpapers, browser tweaks, themes, icons
- `install.sh`: main guided installer

## Usage

Run the full guided setup:

```bash
./install.sh
```

Run individual pieces:

```bash
./scripts/link-dotfiles.sh
./scripts/install-packages.sh core
./scripts/install-packages.sh desktop
./scripts/install-packages.sh aur
```

## Notes

- This repo targets Arch Linux only.
- Existing files are replaced directly when symlinks are created.
- Shell startup no longer installs plugins automatically. Use `./scripts/setup-shell-tools.sh` for that.
- A setup log is written to `${XDG_STATE_HOME:-$HOME/.local/state}/dotrobot/install.log`.
