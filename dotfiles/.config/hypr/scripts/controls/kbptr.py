#!/usr/bin/env python3
"""Keyboard clicking, Vimium-style, in the focused window (SUPER+F; wl-kbptr draws the labels).

  kbptr.py        type a label = press that thing
  kbptr.py test   self-check of the layout math

Hard rule: only things that can be pressed get a label, and if there are none
nothing opens. Same key again (or Esc) while it's open closes it.
  browsers    toolbar + page links/buttons (needs ACCESSIBILITY_ENABLED=1, browser flags)
  kitty+tmux  other tmux tabs, other panes, links (switch / focus / open link)
  other apps  buttons, tabs, menus, links, list rows... as the app reports them
              over AT-SPI (GTK works; Qt/Electron only with accessibility on)
"""
import json
import math
import re
import subprocess as sp
import sys
import unicodedata

KITTY_MARGIN = 5  # window_margin_width in kitty.conf
URL = re.compile(r"(?:https?|ftps?|sftp|file|ssh|git)://[^\s<>\"'`│]+")


def out(*cmd):
    return sp.run(cmd, capture_output=True, text=True).stdout.rstrip("\n")  # keep spaces: tmux widths


def width(s):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 0 if unicodedata.combining(c) else 1 for c in s)


def plain(fmt):  # expanded tmux format -> visible text
    return re.sub(r"#\[[^\]]*\]", "", fmt).replace("##", "#")


def tab_spans(cols, left_w, right_w, tab_ws, sep_w, justify):
    """Start column of each window tab in the status line (tmux format_draw logic)."""
    list_w = sum(tab_ws) + sep_w * (len(tab_ws) - 1)
    if justify == "left":
        x = left_w
    elif justify == "right":
        x = cols - right_w - list_w
    elif justify == "absolute-centre":
        x = (cols - list_w) // 2
    else:  # centre: middle of the space between left and right
        x = left_w + (cols - right_w - left_w) // 2 - list_w // 2
    # ponytail: no handling of a list too wide for the bar (tmux scrolls it with < >)
    spans = []
    for w in tab_ws:
        spans.append((x, w))
        x += w + sep_w
    return spans


def link_cells(lines, pw):
    """(row, col, ncells, url) per link; lines are tmux-joined, so a wrapped link stays whole."""
    res, row = [], 0
    for line in lines:
        for m in URL.finditer(line):
            u = m.group().rstrip(".,;:!?)]}'\"")
            start = width(line[: m.start()])
            col = start % pw  # label sits where the link starts on screen
            res.append((row + start // pw, col, min(width(u), pw - col), u))
        row += max(1, math.ceil(width(line) / pw))
    return res


# --- kitty + tmux -----------------------------------------------------------

def tmux_targets(win):
    ttys = set(out("ps", "-o", "tty=", "--ppid", str(win["pid"])).split())
    clients = [c.split() for c in out("tmux", "list-clients", "-F", "#{client_activity} #{client_tty}").splitlines()]
    clients = [c for c in clients if c[1].removeprefix("/dev/") in ttys]
    if not clients:
        return []  # kitty without tmux: can't read the screen, so nothing to offer
    client = max(clients, key=lambda c: int(c[0]))[1]  # the tab used last

    def fmt(f, t=None):
        return out("tmux", "display", "-p", "-c", client, *(["-t", t] if t else []), f)

    g = fmt("#{client_cell_width} #{client_cell_height} #{client_width} #{client_height} "
            "#{status} #{status-position} #{status-justify} #{status-left-length} #{status-right-length} "
            "#{session_id} #{window_id}").split()
    cw, ch, cols, rows = map(int, g[:4])
    status = int(g[4]) if g[4].isdigit() else int(g[4] == "on")  # on / off / 2..5 lines
    top, justify, left_max, right_max, session, cur_win = g[5] == "top", g[6], int(g[7]), int(g[8]), g[9], g[10]

    x0 = win["at"][0] + KITTY_MARGIN + (win["size"][0] - 2 * KITTY_MARGIN - cols * cw) // 2
    y0 = win["at"][1] + KITTY_MARGIN

    def cell_rect(col, row, ncols):
        return (x0 + col * cw, y0 + row * ch, ncols * cw, ch)

    targets = []
    if status:
        row = 0 if top else rows - status
        wins = [w.split() for w in out("tmux", "list-windows", "-t", session, "-F",
                                       "#{window_id} #{window_active}").splitlines()]
        tab_ws = [width(plain(fmt("#{E:window-status-current-format}" if a == "1" else "#{E:window-status-format}", w)))
                  for w, a in wins]
        left_w = min(width(plain(fmt("#{T:status-left}"))), left_max)
        right_w = min(width(plain(fmt("#{T:status-right}"))), right_max)
        sep_w = width(plain(fmt("#{E:window-status-separator}")))
        for (w, active), (col, n) in zip(wins, tab_spans(cols, left_w, right_w, tab_ws, sep_w, justify)):
            if active != "1":
                targets.append((cell_rect(col, row, n), ["tmux", "select-window", "-t", w]))

    off = status if top else 0
    panes = [p.split() for p in out("tmux", "list-panes", "-t", cur_win, "-F",
                                    "#{pane_id} #{pane_left} #{pane_top} #{pane_width} #{pane_height} "
                                    "#{pane_active}").splitlines()]
    for pid, left, ptop, pw, ph, active in panes:
        left, ptop, pw, ph = int(left), int(ptop), int(pw), int(ph)
        if len(panes) > 1 and active != "1":
            targets.append((cell_rect(left, off + ptop, min(3, pw)), ["tmux", "select-pane", "-t", pid]))
        lines = out("tmux", "capture-pane", "-p", "-J", "-t", pid).split("\n")
        for r, col, n, u in link_cells(lines, pw):
            if r < ph:
                targets.append((cell_rect(left + col, off + ptop + r, n), ["xdg-open", u]))
    return targets


# --- other apps (AT-SPI) ------------------------------------------------------

def atspi_targets(win):
    try:
        import gi
        gi.require_version("Atspi", "2.0")
        from gi.repository import Atspi
    except (ImportError, ValueError):
        return []
    R, S = Atspi.Role, Atspi.StateType
    pressable = {R.PUSH_BUTTON, R.TOGGLE_BUTTON, R.CHECK_BOX, R.RADIO_BUTTON, R.MENU_ITEM, R.CHECK_MENU_ITEM,
                 R.RADIO_MENU_ITEM, R.MENU, R.LINK, R.PAGE_TAB, R.COMBO_BOX, R.ENTRY, R.PASSWORD_TEXT,
                 R.SPIN_BUTTON, R.SLIDER, R.LIST_ITEM, R.TABLE_CELL, R.TREE_ITEM, R.ICON, R.PUSH_BUTTON_MENU,
                 getattr(R, "SWITCH", R.TOGGLE_BUTTON), R.PAGE_TAB_LIST}  # tab lists: group headers only, see below
    Atspi.set_timeout(800, 800)  # a hung app must not hang the key
    try:
        desk = Atspi.get_desktop(0)
        apps = [desk.get_child_at_index(i) for i in range(desk.get_child_count())]
        app = next((a for a in apps if a and a.get_process_id() == win["pid"]), None)
        if not app:
            return []
        frames = [f for f in (app.get_child_at_index(i) for i in range(app.get_child_count())) if f]
        frame = (next((f for f in frames if f.get_name() == win.get("title")), None)
                 or next((f for f in frames if f.get_state_set().contains(S.ACTIVE)), None)
                 or (frames[0] if frames else None))
        if not frame:
            return []

        found = []
        coll = frame.get_collection_iface()
        if coll:  # GTK3 etc: one call
            rule = Atspi.MatchRule.new(Atspi.StateSet.new([S.SHOWING, S.VISIBLE, S.SENSITIVE]),
                                       Atspi.CollectionMatchType.ALL, {}, Atspi.CollectionMatchType.NONE,
                                       list(pressable), Atspi.CollectionMatchType.ANY, [],
                                       Atspi.CollectionMatchType.NONE, False)
            found = coll.get_matches(rule, Atspi.CollectionSortOrder.CANONICAL, 0, True)
        else:  # GTK4 has no Collection: walk the visible tree
            stack, seen = [frame], 0
            while stack and seen < 4000:  # ponytail: node cap keeps huge lists fast, rows past it get no label
                o = stack.pop()
                seen += 1
                st = o.get_state_set()
                if o is not frame and not (st.contains(S.SHOWING) and st.contains(S.VISIBLE)):
                    continue
                if o.get_role() in pressable and st.contains(S.SENSITIVE):
                    found.append(o)
                stack.extend(c for c in (o.get_child_at_index(i) for i in range(o.get_child_count() - 1, -1, -1)) if c)

        wx, wy = win["at"]
        ww, wh = win["size"]
        targets, rows = [], set()
        for o in found:
            if o.get_role() == R.PAGE_TAB_LIST and not o.get_state_set().contains(S.EXPANDABLE):
                continue  # a whole tab strip; only collapsible ones (Chromium tab group headers) get a label
            e = o.get_extents(Atspi.CoordType.WINDOW)  # window-relative on Wayland
            x, y, w, h = e.x, e.y, e.width, e.height
            x2, y2 = min(x + w, ww), min(y + h, wh)
            x, y = max(x, 0), max(y, 0)
            if x2 - x < 4 or y2 - y < 4:
                continue  # hidden, scrolled away or outside the window
            if o.get_role() == R.TABLE_CELL:  # one label per row, not per column
                if (y, y2) in rows:
                    continue
                rows.add((y, y2))
            targets.append(((wx + x, wy + y, x2 - x, y2 - y), None))
        return targets
    except Exception:  # dead/hung app over D-Bus
        return []


# --- main ---------------------------------------------------------------------

def main():
    if sp.run(["pkill", "-x", "wl-kbptr"]).returncode == 0:
        return  # it was open: this press closes it
    win = json.loads(out("hyprctl", "-j", "activewindow") or "{}")
    cls = win.get("class") or ""
    if not cls:
        return
    targets = tmux_targets(win) if cls == "kitty" else atspi_targets(win)

    mon = next(m for m in json.loads(out("hyprctl", "-j", "monitors")) if m["id"] == win["monitor"])
    mw, mh = mon["width"] / mon["scale"], mon["height"] / mon["scale"]
    by_area = {}
    for (x, y, w, h), action in targets:
        x, y = int(x - mon["x"]), int(y - mon["y"])
        if 0 <= x < mw and 0 <= y < mh:  # wl-kbptr covers one screen
            by_area.setdefault(f"{w}x{h}+{x}+{y}", action)
    if not by_area:
        return  # nothing to press: don't open

    cmd = ["wl-kbptr", "-O", mon["name"], "-o", "mode_floating.source=stdin"]
    if not any(by_area.values()):  # apps: wl-kbptr clicks the picked spot
        sp.run(cmd + ["-o", "modes=floating,click"], input="\n".join(by_area), text=True)
        return
    # tmux: wl-kbptr only reports the pick (exactly the area we gave), we run its action
    picked = sp.run(cmd + ["-p", "-o", "modes=floating"], input="\n".join(by_area),
                    capture_output=True, text=True).stdout.split()
    action = by_area.get(picked[0]) if picked else None
    if action:
        sp.Popen(action, start_new_session=True, stdout=sp.DEVNULL, stderr=sp.DEVNULL)


def test():
    # your bar: " " left, 39-col right, tabs "1:codex-" + "2:l3omal*", centred, 237 cols -> col 90
    assert tab_spans(237, 1, 39, [8, 9], 1, "centre") == [(90, 8), (99, 9)]
    assert tab_spans(80, 10, 5, [3, 3], 1, "left") == [(10, 3), (14, 3)]
    assert tab_spans(80, 0, 5, [3], 0, "right") == [(72, 3)]
    assert link_cells(["see https://a.b/c, ok"], 80) == [(0, 4, 13, "https://a.b/c")]
    assert link_cells(["中 http://x.y"], 80) == [(0, 3, 10, "http://x.y")]  # wide char counts 2
    # 10-col pane: line 1 wraps onto 2 rows, the link on line 2 starts in row 3 col 2,
    # and the link that starts at col 12 of line 3 sits on its second row
    assert link_cells(["a" * 15, "x http://q.r", "b" * 12 + "http://s.t"], 10) == [
        (2, 2, 8, "http://q.r"), (5, 2, 8, "http://s.t")]
    assert plain("#[fg=red]1:a##b#[default]") == "1:a#b"
    print("ok")


if __name__ == "__main__":
    test() if sys.argv[1:] == ["test"] else main()
