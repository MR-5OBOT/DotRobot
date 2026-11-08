# Practical keyboard workflow — session report

Checked November 7, 2026. Use keyboard shortcuts and terminal tools where they
save effort; use the mouse when that is easier. Installed status was checked on
this machine. It does not mean every feature of every tool was tested.

## Your requests and outcomes

1. **Inspect the actual system:** checked Arch, Hyprland 0.57.1, your mappings,
   installed commands, Superfile, Brovim and the Super+F collector. The shell
   already has Vim editing, fzf history and zoxide integration.
2. **Avoid slow keyboard mouse movement:** prefer direct app actions, native
   shortcuts and suitable terminal tools. Mouse use remains fine.
3. **Add Brovim selection:** `/phrase` → Enter → `v` → movements → `y` copies
   and immediately clears the highlight. `c` positions the caret, `V` selects
   lines. `o` was removed at your request; `c` remains. Enter and Y also copy and clear the selection.
   Escape cancels selection, including existing search selections and pending
   movement prefixes. Reload Brovim once at `chrome://extensions` to load it.
4. **Explain Super+F:** it asks the focused app for accessible controls and
   gives their rectangles to wl-kbptr. It does not use image detection. Details
   and the correction about OpenCV are below.
5. **Compare Neru:** Linux is currently Beta; it offers accessible hints, OCR
   and grid features. It was not installed or benchmarked here, so there is no
   measured replacement verdict. Skip the migration under your simpler plan.
   [Neru project](https://github.com/y3owk1n/neru).
6. **Make accessibility setup reversible, then narrow the scope:** removed the
   unactivated setup manager and its new environment/keymap hooks after your
   latest instruction. Your pre-existing Super+F setup remains. No new packages,
   services or session accessibility settings were applied by this work.
7. **Explain terminal file dialogs:** termfilechooser can make supported app
   upload/open/save dialogs use Superfile instead of a GUI picker. It requires
   portal setup and does not cover every app dialog. Skip it for now. In many
   ordinary file dialogs, Ctrl+L accepts a path; Superfile's Ctrl+P copies the
   selected path for pasting there.
   [termfilechooser project](https://github.com/hunkyburrito/xdg-desktop-portal-termfilechooser).
8. **Add Caps+gg/Caps+G, then purge them:** removed the new keyd, Kitty and
   tmux configuration at your request. Your original Caps+u/d and Caps+hjkl
   mappings remain. The installed keyd config was restored and the daemon
   restarted successfully; the purge is active in this session.
9. **Give one practical report:** use the installed choices below. Optional
   additions are possibilities, not an installation plan.

## Use what is already installed

| Task / usual GUI | Practical choice on your machine |
| --- | --- |
| Files / Dolphin | **Superfile: `spf`**, with your existing Vim navigation. |
| Code, configuration, notes and plain text | `nvim`; Markdown for notes. |
| Find files / search contents | `fd`, `fzf`, `rg`; `rga` adds document/archive formats through available adapters. |
| Directory jumps / command history | zoxide's `z`; shell Ctrl+R via fzf. |
| Git / graphical Git client | `lazygit`; `gh` for GitHub tasks. |
| Processes, CPU and RAM / task manager | `btop`. |
| Network settings and Wi-Fi | `nmtui`, `nmcli`. `impala` is also installed, but use it only with an iwd setup. |
| Bluetooth settings | `bluetoothctl`; keep the GUI if its pairing prompts are easier. |
| Audio mixer | `wiremix`; existing media keys for daily volume. |
| PDFs | `zathura`: a graphical reader with keyboard navigation. |
| Images | `imv` for a graphical viewer; `chafa` for terminal previews. |
| Music and video | `mpv`, with built-in keyboard controls. |
| Media conversion / simple trimming | `ffmpeg`; Kdenlive for timeline editing. |
| Downloads | `aria2c`, `curl`, `wget`; `yt-dlp` for supported media sites. |
| Archives | Superfile, `bsdtar`, `tar`, `zip`, `unzip`. |
| CSV, TSV and tabular data | `vd` (VisiData); keep a spreadsheet app for complex workbook layouts and formulas. |
| SQLite databases | `sqlite3`; optional lazysql for an interactive database browser. |
| Calculator | `qalc`, or the existing Super+= calculator. |
| Read text and Markdown | `bat`, `glow`. |
| Typeset documents | `typst`; keep a GUI office app for collaborative or layout-heavy office files. |
| Disk space and mounts | `df -h`, `du -h`, `lsblk`, `findmnt`; partitioning can stay graphical. |
| Package management | `pacman`, `flatpak`. |
| Services and logs | `systemctl`, `journalctl`. |
| Containers | `docker` CLI; optional lazydocker dashboard. |
| OCR | `tesseract`. |
| Image resizing and conversion | `magick`; Krita for painting and interactive editing. |
| Multiple terminal sessions | Your existing Kitty and `tmux`. |
| Trash from commands | `trash-put`. |
| Screenshots | Existing Shift+Print captures a whole output; `grim` saves a screenshot from the terminal. |
| Clipboard | Existing Super+V history; `wl-copy` and `wl-paste` for terminal text. |
| Remote terminals and file transfer | `ssh`, `scp`, `sftp`. |
| Passwords | Keep your Bitwarden browser extension and its autofill workflow. |
| Web browsing | **Brovim in Helium**, including hints, search, selection, tab grid and dark mode. |
| Telegram | **Keep Telegram Desktop and learn its native shortcuts.** |
| Drawing, video timelines, custom controls, awkward dialogs | Keep the GUI; use the mouse whenever it is faster. |

## Shortcuts worth learning first

Your **Superfile** config already has `hjkl` navigation, `/` search, `v`
selection, Ctrl+C/X/V copy/cut/paste, Ctrl+R rename, Ctrl+P copy path, `n` new
panel, Tab next panel, `f` preview and `?` help. These were read from your own
configuration. [Upstream reference](https://superfile.dev/list/hotkey-list/).

For **Telegram Desktop**, start with Ctrl+F search, Alt+Up/Down or
Ctrl+PageUp/PageDown previous/next chat, and Ctrl+0 Saved Messages. These are
upstream defaults; custom mappings can take precedence.
[Telegram shortcut definitions](https://github.com/telegramdesktop/tdesktop/blob/dev/Telegram/SourceFiles/core/shortcuts.cpp).

For **Hyprland**, keep Super+hjkl focus, Super+Shift+hjkl movement,
Super+Ctrl+hjkl resizing, workspace shortcuts, Super+Space launcher,
Super+V clipboard and Super+/ keymap help.

Your **shell** already uses Vim editing. Escape then `v` opens the current
command in your configured editor; Ctrl+R searches command history.

## Caps scrolling purge status

The added Caps+gg/Caps+G mappings have been removed from the repository. Kitty
has reloaded its original configuration. The loaded tmux User0/User1 bindings
and both custom key sequences have been removed. Your original Caps+u/d,
Caps+hjkl, word movements and Home/End mappings remain.

The later correction changes End to **Caps+Shift+4 (`$`)**, matching Vim.
Caps+0 remains Home; Caps+4 no longer means End. Both cheatsheet rows match.
The installed keyd config matches the repository and the service is active.

The installed `/etc/keyd/default.conf` was restored to the original repository
version, and keyd was restarted successfully after desktop authentication.
The repository, installed config and active Kitty/tmux settings are now back
to their previous mappings. No setup command is needed for this purge.

The subsequent Shift+4 correction is already applied; Caps+gg/G stay purged.

## Later browser requests

- **Alt+E:** a centered browser-page search palette, with its input focused on opening. Enter always
  opens a new tab. Search settings, extensions, performance, downloads, history and other browser
  pages. Automatic detects the exposed browser identity; a manual selector exposes Helium/Brave
  specific pages when identity is hidden.
- **Protected pages:** Alt+E and Alt+Q use a temporary extension tab when an overlay cannot work.
  Alt+Q always shows its grid on browser pages, even with two tabs and normal browser-page access
  disabled. No new setting. Enter selects and closes the temporary grid; Escape cancels it.
- **Shortcut conflicts:** Alt+E is removed from Helium's native menu backup. In another browser,
  assign Brovim's command manually in its extension-shortcuts page if needed. The Helium backup is
  not a shared Brave settings format.
- **Selection:** keep `c`, remove visual `o`; y/Y/Enter copy and immediately clear highlights.
  Escape also clears highlights. Fixed the Extensions-page find/selection helper ReferenceError.
- **Default:** Keep focus on the page is true for new settings. Existing saved choices are
  respected. Automatic focus recovery handles editors that try to refocus themselves.

## Optional additions, only when you need the task

None of these are installed. Email, sync and backups also need account or
storage configuration. There is no need to install the whole list.

| Task | Optional terminal tool |
| --- | --- |
| Browse disk usage | [gdu](https://github.com/dundee/gdu) |
| Bluetooth TUI | [bluetui](https://github.com/pythops/bluetui) |
| Docker dashboard | [lazydocker](https://github.com/jesseduffield/lazydocker) |
| Database browser | [lazysql](https://github.com/jorgerojas26/lazysql) |
| Email with Vim-style keys | [aerc](https://aerc-mail.org/) |
| Calendar and tasks | [calcurse](https://calcurse.org/) |
| RSS feeds | [Newsboat](https://newsboat.org/) |
| Cloud files and sync | [rclone](https://rclone.org/) |
| Versioned backups | [restic](https://restic.net/) |

Superfile is your chosen file manager; skip redundant Yazi/lf/Vifm installs.

## Super+F's limits, in plain language

It asks the focused application which controls it exposes through AT-SPI, then
labels their rectangles. One live sample returned 154 Helium targets in about
60 ms, one Kitty/tmux target and no Telegram targets. Telegram was not registered
on AT-SPI in that sample. The bus also reported IsEnabled=false while the
accessibility toolkit preference was true.

The collector scans one app window, so Quickshell panels on another layer are
outside that lookup. It accepts selected control roles, so custom clickable
items can be missed. Its fallback tree walk stops after 4,000 nodes; this is
not a universal 4,000-button limit. An exception can discard targets already
found and produce an empty result.

Correction to the earlier claim: the installed wl-kbptr **does include OpenCV**.
Your Super+F supplies accessibility targets itself, so it does not invoke that
visual detection. The collector was inspected, not rewritten. Missing labels
can simply mean using a native shortcut or the mouse under your revised plan.

## Brovim verification

Selection was connected to the manifest, command registry, default mappings and
normal mode. It handles open shadow roots, shares find-mode scrolling and uses
the existing clipboard HUD. Escape removes all selection ranges, including
caret and line highlights. Copying with y/Enter/Y now clears the highlight
immediately and leaves no selection range. Editor typing keeps its normal
behavior.

Formatting/lint, 334 unit tests, 102 DOM tests and 101 installed-browser checks
passed in Helium/Chromium. Thirteen internal-page checks also passed, including
immediate copy cleanup, clipboard contents and Escape cleanup on
chrome://extensions with shadow DOM. Eight browser-navigation checks and 11
real-shortcut checks passed in isolated Helium profiles. All three distribution ZIPs were rebuilt.
Firefox runtime tests were not run. Reload Brovim once to activate the source
changes.

## Recheck against every session request

| Request | Current evidence and outcome |
| --- | --- |
| Inspect your own system | Live Hyprland version/config, installed commands and real dotfiles inspected; no Hyprland config errors. |
| Prefer easy keyboard workflows; mouse is fine | Native shortcuts and existing terminal tools retained; universal accessibility work dropped. |
| Superfile for files; Telegram native shortcuts | Your Superfile bindings verified from its config; both choices are in this report. |
| List terminal alternatives across tasks | Installed commands checked again; optional tools checked separately and not installed automatically. |
| Explain/add Brovim selection | Manifest, command registry, default v/V mappings, normal mode and selection module present; browser tests cover the documented controls. |
| Escape must clear highlights | Tests cover existing/search/caret/line selections, pending prefixes, native selections and the actual Extensions page. |
| y must clear immediately after copy | Shared yank action now removes all ranges; checks cover y, Enter and Y, and verify clipboard contents before requiring any Escape. |
| Explain Super+F and the OpenCV correction | Collector inspected unchanged: one window, role filter, 4,000-node fallback cap and error handling; installed binary reports OpenCV. |
| Compare Neru | Official project checked again; Linux Beta and additional hint/OCR/grid features confirmed. No measured replacement claim or installation. |
| Reversible accessibility setup | Superseded by your simpler scope; manager, state and added environment/keymap hooks are absent. |
| Explain termfilechooser | Official Superfile support and app-dependent portal limits checked; explanation retained, integration skipped. |
| Caps+gg/G, followed by purge | Caps additions removed from all three repo configs; installed keyd restored, daemon restarted, live tmux custom keys removed and Kitty reloaded. Existing Caps navigation remains. |
| Report and implementation details | This report and Brovim's README/REPORT reflect the final behavior, including the two later corrections above. |

The Caps purge requires no further action. Reload Brovim once at
`chrome://extensions` to activate the new copy cleanup in your running browser.
