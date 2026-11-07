#!/usr/bin/env python3
import sys
import os
import subprocess
import tty
import termios
import select

def shorten_path(path):
    if not path:
        return ""
    home = os.path.expanduser("~")
    if path == home:
        return "~"
    if path.startswith(home + "/"):
        return "~" + path[len(home):]
    return path

def fit_path(path, max_len):
    if not path or max_len <= 3 or len(path) <= max_len:
        return path
    return "..." + path[-(max_len - 3):]

def calc_scroll(selected, offset, rows):
    if rows <= 0:
        return 0
    if selected < offset:
        return selected
    if selected >= offset + rows:
        return selected - rows + 1
    return offset

def parse_windows(raw_output):
    items = []
    for line in raw_output.strip().splitlines():
        if not line:
            continue
        parts = line.split("|")
        if len(parts) >= 5:
            items.append({
                "index": parts[0],
                "name": parts[1],
                "active": parts[2] == "1",
                "panes": parts[3],
                "path": shorten_path(parts[4]),
                "flags": parts[5] if len(parts) > 5 else ""
            })
    return items

def parse_sessions(raw_output):
    items = []
    for line in raw_output.strip().splitlines():
        if not line:
            continue
        parts = line.split("|")
        if len(parts) >= 3:
            items.append({
                "name": parts[0],
                "active": parts[1] == "1",
                "windows": parts[2],
                "path": shorten_path(parts[3]) if len(parts) > 3 else ""
            })
    return items

def get_windows():
    cmd = ["tmux", "list-windows", "-F", "#{window_index}|#{window_name}|#{window_active}|#{window_panes}|#{pane_current_path}|#{window_flags}"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return parse_windows(res.stdout)

def get_sessions():
    cmd = ["tmux", "list-sessions", "-F", "#{session_name}|#{session_attached}|#{session_windows}|#{session_path}"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return parse_sessions(res.stdout)

# Color definitions (True color 24-bit ANSI)
C_RESET = "\033[0m"
C_BOLD = "\033[1m"
C_DIM = "\033[2m"

# Colors matching the user's palette
C_BG_BLACK = "\033[48;2;0;0;0m"           # #000000 pure black
C_BG_SELECTED = "\033[48;2;22;22;22m"     # #161616 subtle dark selection bar
C_FG_ACCENT = "\033[38;2;91;42;105m"      # #5B2A69 darker Hyprland purple accent
C_FG_WHITE = "\033[38;2;230;230;230m"     # clean bright white
C_FG_GRAY = "\033[38;2;112;112;112m"      # #707070 medium gray
C_FG_DARK_GRAY = "\033[38;2;70;70;70m"    # #464646 dark gray

def get_key():
    ch = sys.stdin.read(1)
    if ch == '\x1b':
        r, _, _ = select.select([sys.stdin], [], [], 0.05)
        if r:
            ch2 = sys.stdin.read(1)
            if ch2 == '[':
                ch3 = sys.stdin.read(1)
                if ch3 == 'A': return 'up'
                if ch3 == 'B': return 'down'
                if ch3 == 'C': return 'right'
                if ch3 == 'D': return 'left'
                if ch3 == 'H': return 'home'
                if ch3 == 'F': return 'end'
                return 'esc'
            return 'esc'
        return 'esc'
    if ch in ('\r', '\n'):
        return 'enter'
    return ch

def render(items, selected_idx, scroll_offset, mode):
    try:
        cols, rows = os.get_terminal_size()
    except OSError:
        cols, rows = 80, 24

    buf = []
    # Cursor home
    buf.append("\033[H")

    max_path_len = max(8, cols - 30)

    for r in range(rows):
        item_idx = scroll_offset + r
        if item_idx < len(items):
            it = items[item_idx]
            is_selected = (item_idx == selected_idx)
            is_active = it.get("active", False)

            bg = C_BG_SELECTED if is_selected else C_BG_BLACK

            # Rail icon
            if is_selected:
                rail = f"{C_FG_ACCENT}{C_BOLD}▌{C_RESET}{bg} "
            else:
                rail = "  "

            # Active status marker
            if is_active:
                marker = f"{C_FG_ACCENT}●{C_RESET}{bg} "
            else:
                marker = f"{C_FG_DARK_GRAY}○{C_RESET}{bg} "

            fitted_path = fit_path(it["path"], max_path_len)

            # Number / Index
            if mode == "windows":
                num_str = f"{C_FG_ACCENT if is_selected else C_FG_GRAY}{it['index']:>2}{C_RESET}{bg} "
                name_str = f"{C_BOLD}{C_FG_WHITE}{it['name']:<14}{C_RESET}{bg} "
                panes_num = int(it['panes']) if it['panes'].isdigit() else 1
                pane_str = f"{C_FG_GRAY}{panes_num}p{C_RESET}{bg} " if panes_num > 1 else f"{C_FG_DARK_GRAY}1p{C_RESET}{bg} "
                extra_str = f"{C_FG_GRAY}{fitted_path}{C_RESET}{bg}"
            else:
                num_str = f"{C_FG_ACCENT if is_selected else C_FG_GRAY}{item_idx + 1:>2}{C_RESET}{bg} "
                name_str = f"{C_BOLD}{C_FG_WHITE}{it['name']:<14}{C_RESET}{bg} "
                wins_num = int(it['windows']) if it['windows'].isdigit() else 1
                pane_str = f"{C_FG_GRAY}{wins_num}w{C_RESET}{bg} "
                extra_str = f"{C_FG_GRAY}{fitted_path}{C_RESET}{bg}"

            line_content = f"{bg}{rail}{marker}{num_str}{name_str}{pane_str}{extra_str}"
            buf.append(f"{line_content}\033[K{C_RESET}\r\n")
        else:
            buf.append(f"{C_BG_BLACK}\033[K{C_RESET}\r\n")

    sys.stdout.write("".join(buf))
    sys.stdout.flush()

def run_interactive(mode):
    items = get_windows() if mode == "windows" else get_sessions()
    if not items:
        return

    # Start selection on active item
    selected_idx = 0
    for i, it in enumerate(items):
        if it.get("active"):
            selected_idx = i
            break

    scroll_offset = 0

    # Check for client & session passed from tmux
    client = os.environ.get("TMUX_CLIENT")
    target_session = os.environ.get("TMUX_SESSION")

    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        sys.stdout.write("\033[?25l")
        sys.stdout.flush()

        while True:
            try:
                _, rows = os.get_terminal_size()
            except OSError:
                rows = 24
            scroll_offset = calc_scroll(selected_idx, scroll_offset, rows)

            render(items, selected_idx, scroll_offset, mode)
            key = get_key()

            if key in ('q', 'esc', '\x03'):  # 'q', Esc, Ctrl+C
                break
            elif key in ('up', 'k'):
                selected_idx = (selected_idx - 1) % len(items)
            elif key in ('down', 'j'):
                selected_idx = (selected_idx + 1) % len(items)
            elif key == 'g':
                selected_idx = 0
            elif key == 'G':
                selected_idx = len(items) - 1
            elif key in ('enter', ' '):
                chosen = items[selected_idx]
                if mode == "windows":
                    target = f"{target_session}:{chosen['index']}" if target_session else f":{chosen['index']}"
                    subprocess.run(["tmux", "select-window", "-t", target])
                else:
                    cmd = ["tmux", "switch-client", "-t", chosen["name"]]
                    if client:
                        cmd = ["tmux", "switch-client", "-c", client, "-t", chosen["name"]]
                    subprocess.run(cmd)
                break
            elif key.isdigit():
                target_digit = key
                target_idx = None
                if mode == "windows":
                    for i, it in enumerate(items):
                        if it["index"] == target_digit:
                            target_idx = i
                            break
                else:
                    digit_val = int(target_digit)
                    if 1 <= digit_val <= len(items):
                        target_idx = digit_val - 1

                if target_idx is not None:
                    chosen = items[target_idx]
                    if mode == "windows":
                        target = f"{target_session}:{chosen['index']}" if target_session else f":{chosen['index']}"
                        subprocess.run(["tmux", "select-window", "-t", target])
                    else:
                        cmd = ["tmux", "switch-client", "-t", chosen["name"]]
                        if client:
                            cmd = ["tmux", "switch-client", "-c", client, "-t", chosen["name"]]
                        subprocess.run(cmd)
                    break
    finally:
        # Restore cursor and terminal settings
        sys.stdout.write("\033[?25h\033[0m")
        sys.stdout.flush()
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

def main():
    mode = "windows"
    if len(sys.argv) > 1 and sys.argv[1] in ("windows", "sessions"):
        mode = sys.argv[1]

    if not sys.stdin.isatty():
        # Non-interactive invocation (e.g. tests or diagnostics)
        items = get_windows() if mode == "windows" else get_sessions()
        for it in items:
            print(it)
        return

    run_interactive(mode)

if __name__ == "__main__":
    main()
