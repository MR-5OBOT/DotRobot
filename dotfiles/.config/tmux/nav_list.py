#!/usr/bin/env python3
import sys
import os
import shlex
import subprocess
import tty
import termios

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

def parse_windows(raw_output, current_session):
    """Each session as a row (index None), followed by its windows."""
    items = []
    for line in raw_output.strip().splitlines():
        parts = line.split("|")
        if len(parts) < 7:
            continue
        session = parts[0]
        if not items or items[-1]["session"] != session:
            items.append({"session": session, "index": None, "name": session,
                          "windows": parts[1], "active": session == current_session})
        items.append({
            "session": session,
            "index": parts[2],
            "name": parts[3],
            "active": parts[4] == "1",
            "panes": parts[5],
            "path": shorten_path(parts[6]),
        })
    return items

def get_windows(current_session):
    cmd = ["tmux", "list-windows", "-a", "-F",
           "#{session_name}|#{session_windows}|#{window_index}|#{window_name}|#{window_active}|#{window_panes}|#{pane_current_path}"]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return parse_windows(res.stdout, current_session)

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
C_FG_SESSION = "\033[38;2;155;89;182m"    # #9B59B6 brighter purple for session names
C_FG_RULE = "\033[38;2;40;40;40m"        # #282828 faint header rule

KEYS = {"\x1b[A": "up", "\x1bOA": "up", "\x1b[Z": "up",  # Up, Shift+Tab
        "\x1b[B": "down", "\x1bOB": "down", "\t": "down",  # Down, Tab
        "\r": "enter", "\n": "enter", "\x1b": "esc"}

def get_key():
    # One os.read gets a whole key sequence: sys.stdin's buffer hid the rest of it from
    # select(), so arrows read as Esc and closed the picker.
    # shortcut: several keys in one read (a paste) count as the first, fine for typing.
    data = os.read(sys.stdin.fileno(), 32).decode(errors="ignore")
    return KEYS.get(data, "" if data.startswith("\x1b") else data[:1])

# Row layout, in columns: rail 2 + marker 2, then for windows indent 2 + index 3 + name 15
# + panes 3 + path; for sessions name + rule + count. 1 spare column on the right.
ROW_START = 4
WIN_FIXED = 2 + 3 + 15 + 3
NAME_W = 14

def session_count(it):
    n = int(it["windows"]) if it["windows"].isdigit() else 0
    return f"{n} window" + ("" if n == 1 else "s")

def natural_width(it):
    if it["index"] is None:
        return ROW_START + len(it["name"]) + 1 + 3 + 1 + len(session_count(it)) + 1
    return ROW_START + WIN_FIXED + len(it["path"]) + 1

def render(items, selected_idx, scroll_offset):
    try:
        cols, rows = os.get_terminal_size()
    except OSError:
        cols, rows = 80, 24

    lines = []
    max_path_len = max(8, cols - ROW_START - WIN_FIXED - 1)

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

            if it["index"] is None:  # session header: name ──── N windows
                count = session_count(it)
                name = it["name"][:max(1, cols - ROW_START - len(count) - 6)]
                rule = "─" * max(1, cols - ROW_START - len(name) - len(count) - 3)
                body = (f"{C_BOLD}{C_FG_SESSION}{name}{C_RESET}{bg} "
                        f"{C_FG_RULE}{rule}{C_RESET}{bg} {C_FG_GRAY}{count}{C_RESET}{bg}")
            else:
                fitted_path = fit_path(it["path"], max_path_len)
                num_str = f"{C_FG_ACCENT if is_selected else C_FG_GRAY}{it['index']:>2}{C_RESET}{bg} "
                name_str = f"{C_BOLD}{C_FG_WHITE}{it['name'][:NAME_W]:<{NAME_W}}{C_RESET}{bg} "
                panes_num = int(it['panes']) if it['panes'].isdigit() else 1
                pane_str = f"{C_FG_GRAY}{panes_num}p{C_RESET}{bg} " if panes_num > 1 else f"{C_FG_DARK_GRAY}1p{C_RESET}{bg} "
                extra_str = f"{C_FG_GRAY}{fitted_path}{C_RESET}{bg}"
                body = f"  {num_str}{name_str}{pane_str}{extra_str}"

            line_content = f"{bg}{rail}{marker}{body}"
            lines.append(f"{line_content}\033[K{C_RESET}")
        else:
            lines.append(f"{C_BG_BLACK}\033[K{C_RESET}")

    # Cursor home, then rows joined (not ended) by newlines: a newline after the last row
    # scrolled the popup a line every frame, hiding the top row and flickering.
    sys.stdout.write("\033[H" + "\r\n".join(lines))
    sys.stdout.flush()

def switch_to(item, client):
    target = f"={item['session']}" if item["index"] is None else f"={item['session']}:{item['index']}"
    subprocess.run(["tmux", "switch-client", *(["-c", client] if client else []), "-t", target])

def client_info(client):
    """(session, width, height) of a client; the current one if client is None."""
    if client is None:
        cmd = ["tmux", "display-message", "-p", "#{client_name}"]
        client = subprocess.run(cmd, capture_output=True, text=True).stdout.strip()
    res = subprocess.run(["tmux", "list-clients", "-F",
                          "#{client_name}\t#{client_session}\t#{client_width}\t#{client_height}"],
                         capture_output=True, text=True)
    for line in res.stdout.splitlines():
        name, session, w, h = line.split("\t")
        if name == client:
            return client, session, int(w), int(h)
    return client, "", 80, 24

def open_popup(client):
    """prefix+w runs this: size the popup to the list, then run the picker inside it."""
    client, session, cw, ch = client_info(client)
    items = get_windows(session)
    if not items:
        return
    w = max(30, min(72, cw - 2, max(natural_width(it) for it in items)))
    h = max(1, min(len(items), ch - 2))
    cmd = f"python3 {shlex.quote(os.path.abspath(__file__))} {shlex.quote(client)}"
    subprocess.run(["tmux", "display-popup", "-c", client, "-E", "-B", "-w", str(w), "-h", str(h),
                    "-s", "bg=#000000,fg=#ffffff", cmd])

def run_interactive(client):
    client, current_session, _, _ = client_info(client)

    items = get_windows(current_session)
    if not items:
        return

    # Start selection on the current window
    selected_idx = 0
    for i, it in enumerate(items):
        if it["session"] == current_session and it["index"] is not None and it["active"]:
            selected_idx = i
            break

    scroll_offset = 0

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

            render(items, selected_idx, scroll_offset)
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
                switch_to(items[selected_idx], client)
                break
            elif key.isdigit():  # window number in the current session
                chosen = next((it for it in items
                               if it["session"] == current_session and it["index"] == key), None)
                if chosen:
                    switch_to(chosen, client)
                    break
    finally:
        # Restore cursor and terminal settings
        sys.stdout.write("\033[?25h\033[0m")
        sys.stdout.flush()
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

def main():
    # nav_list.py popup CLIENT  (prefix+w)  |  nav_list.py [CLIENT]  (the picker itself)
    args = sys.argv[1:]
    if args[:1] == ["popup"]:
        open_popup(args[1] if len(args) > 1 else None)
        return
    client = args[0] if args else None

    if not sys.stdin.isatty():
        # Non-interactive invocation (e.g. tests or diagnostics)
        for it in get_windows(client_info(client)[1]):
            print(it)
        return

    run_interactive(client)

if __name__ == "__main__":
    main()
