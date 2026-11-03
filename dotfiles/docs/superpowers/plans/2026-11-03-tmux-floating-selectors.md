# Tmux Floating Windows & Sessions Selectors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provide sleek, distraction-free floating popups for tmux windows (`prefix + w`) and sessions (`prefix + s`) with a pure black background and rounded border in `#BE4277`, replacing the full-screen `choose-tree` preview interface.

**Architecture:** A standalone Python script `nav-list.py` uses `curses` to render an interactive list with `j`/`k`, `Enter`, and number jumps, launched via `tmux display-popup -E` with custom styling and frame borders.

**Tech Stack:** Python 3 (curses, subprocess), tmux 3.8

**Spec:** `docs/superpowers/specs/2026-11-03-tmux-floating-selectors-design.md`

## Global Constraints

- No external Python dependencies (standard library only).
- Background must be true black (`#000000`), border frame `#BE4277`.
- No preview pane and no `fzf` prompt.
- Retain existing prefix `C-Space`.

## Review Focus

1. **Popup dismiss:** Pressing `Esc` or `q` must cleanly exit without lingering processes or changing tmux selection.
2. **Current item indicator:** The currently active window or attached session must be visibly indicated (e.g. `●`).
3. **Number key jumping:** Pressing a digit should immediately jump to that item or window index and close the popup.
4. **Window/Session name truncation:** Long window names or paths must not crash curses or wrap awkwardly off-screen.
5. **No active selection / Single item:** Running when only 1 window/session exists should display cleanly and allow switching or closing without crashing.

---

### Task 1: Create the Python Selector Script (`nav-list.py`)

**Files:**
- Create: `.config/tmux/nav-list.py` (executable)

**Interfaces:**
- Produces: CLI script accepting `windows` or `sessions` as first argument.
- Invokes tmux commands: `tmux select-window -t <target>` or `tmux switch-client -t <target>`.

- [ ] **Step 1: Write test script to verify tmux data parsing and curses UI logic**
- [ ] **Step 2: Implement `.config/tmux/nav-list.py`**
  - Implement query helper running `tmux list-windows` or `tmux list-sessions` with format strings.
  - Implement curses main loop with vi navigation (`j`/`k`, arrows, `g`/`G`, `q`, `Esc`, `Enter`, `1-9`).
  - Style with true black background (`#000000`), `#BE4277` accent bar on selected row, active indicators.
  - On Enter / number press, execute corresponding `tmux select-window` or `switch-client` and exit.
- [ ] **Step 3: Make `.config/tmux/nav-list.py` executable (`chmod +x`)**
- [ ] **Step 4: Test running `python3 .config/tmux/nav-list.py windows` and `sessions` directly**

---

### Task 2: Configure Tmux Bindings in `tmux.conf`

**Files:**
- Modify: `.config/tmux/tmux.conf`

**Interfaces:**
- Consumes: `.config/tmux/nav-list.py`
- Produces: tmux keybindings `prefix + w` and `prefix + s` bound to `display-popup`.

- [ ] **Step 1: Update `.config/tmux/tmux.conf`**
  - Replace `bind s choose-tree -Zs` with `display-popup` calling `nav-list.py sessions`.
  - Add `bind w` calling `display-popup` with `nav-list.py windows`.
  - Configure popup options: `-w 50% -h 40% -b rounded -s "bg=#000000,fg=#e0e0e0" -S "fg=#BE4277"`.
- [ ] **Step 2: Reload tmux configuration via `tmux source-file ~/.config/tmux/tmux.conf`**
- [ ] **Step 3: Verify bindings in active tmux server**
