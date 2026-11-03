# Short Design: Tmux Floating Window & Session Selectors

## Intent & Why
Provide clean, distraction-free floating selectors for tmux windows and sessions to replace the cluttered full-screen `choose-tree` preview interface and avoid heavy search tools like `fzf`.

## Goals
- Floating popup for windows bound to `prefix + w`.
- Floating popup for sessions bound to `prefix + s`.
- Pure black background (`#000000`) with rounded frame styled to match the theme accent (`#BE4277`).
- Fast keyboard navigation: `j`/`k`, Up/Down, `Enter` to switch, `1-9` quick jump, `q`/`Esc` to dismiss.
- Visual clarity: clean indicators (`●` active, `○` inactive), window indices/names, session names, and window counts.

## Non-Goals & Anti-Goals
- No preview pane (no pane contents rendered).
- No fuzzy search prompt (`fzf` is explicitly excluded).
- No external Python library dependencies (standard library only).

## Constraints
- Compatible with tmux 3.8 and existing configuration in `~/repos/DotRobot/dotfiles/.config/tmux/tmux.conf`.
- Must work smoothly in terminal environments without screen tearing or cursor artifacts.

## Approaches Considered
1. **Python (`curses` / ANSI) Script (Selected):** Standalone script (`~/.config/tmux/nav-list.py`) launched via `tmux display-popup`. Reliable key handling, native UTF-8 symbols, smooth colors, zero extra dependencies.
2. **Pure Bash / ANSI Script:** Zero dependencies, but more brittle key parsing and terminal state management.

## Implementation Details
- **Script:** `/home/mr5obot/repos/DotRobot/dotfiles/.config/tmux/nav-list.py` (accessible via symlink at `~/.config/tmux/nav-list.py`).
  - Mode switch: `nav-list.py windows` vs `nav-list.py sessions`.
  - Queries tmux via `tmux list-windows` or `tmux list-sessions` with format strings.
  - Interactive loop: captures keystrokes, highlights current selection, triggers `tmux select-window -t ...` or `tmux switch-client -t ...` upon selection.
- **Tmux Config (`tmux.conf`):**
  - Bind `w`: `display-popup -E -w 45% -h 35% -b rounded -s 'bg=#000000,fg=#ffffff' -S 'fg=#BE4277' 'python3 ~/.config/tmux/nav-list.py windows'`
  - Bind `s`: `display-popup -E -w 45% -h 35% -b rounded -s 'bg=#000000,fg=#ffffff' -S 'fg=#BE4277' 'python3 ~/.config/tmux/nav-list.py sessions'`
  - Unbind default `choose-tree` bindings as appropriate.

## Left to Builder
- Sizing defaults (width/height percentage) to ensure comfortable padding without being too large.
- Fallback handling when only 1 session or window exists.
