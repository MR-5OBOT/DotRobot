#!/usr/bin/env python3
"""prefix+s: save this session's windows (names, splits as percentages, pane folders) to
template.conf as plain tmux commands; prefix+t sources it. Panes come back as plain shells."""
import json
import os
import subprocess
import sys

OUT = os.path.expanduser("~/.config/tmux/template.conf")


def tmux(*args):
    return subprocess.run(["tmux", *args], capture_output=True, text=True, check=True).stdout


def q(s):
    # tmux config double quotes: \ " $ need a backslash; ## stops format expansion eating #
    for a, b in (("\\", "\\\\"), ('"', '\\"'), ("$", "\\$"), ("#", "##")):
        s = s.replace(a, b)
    return f'"{s}"'


def kids(node):
    return [c for c in node["c"] if "z" not in c]  # "z" marks floating panes (the float)


def leaves(node):
    return [node] if node["t"] == "p" else [leaf for c in kids(node) for leaf in leaves(c)]


def span(nodes, key):  # cells covered by adjacent siblings, borders included
    return sum(n[key] for n in nodes) + len(nodes) - 1


def build(node, dirs, base, first, out):
    """node's region is pane index base+first; carve it with splits like the saved one.
    Splits insert the new pane right after the split one, so panes stay in leaf order."""
    if node["t"] == "p":
        return
    flag, key = ("-h", "w") if node["t"] == "h" else ("-v", "h")
    cs = kids(node)
    out.append(f"select-pane -t :.{base + first}")
    for i in range(1, len(cs)):
        pct = min(99, max(1, round(100 * span(cs[i:], key) / span(cs[i - 1:], key))))
        out.append(f"split-window {flag} -l {pct}% -c {q(dirs[leaves(cs[i])[0]['I']])}")
    for c in cs:
        build(c, dirs, base, first, out)
        first += len(leaves(c))


def main():
    pane = sys.argv[1]
    dirs = dict(line.split("\t", 1) for line in
                tmux("list-panes", "-s", "-t", pane, "-F", "#{pane_id}\t#{pane_current_path}").splitlines())
    base = int(tmux("show", "-gwv", "pane-base-index"))
    out = []
    # Linked windows are skipped: the float's backing window is linked in while it is shown.
    for line in tmux("list-windows", "-t", pane, "-f", "#{!:#{window_linked}}",
                     "-F", "#{window_layout}\t#{window_name}").splitlines():
        layout, name = line.split("\t", 1)
        root = json.loads(layout)["L"]
        out.append(f"new-window -n {q(name)} -c {q(dirs[leaves(root)[0]['I']])}")
        build(root, dirs, base, 0, out)
    with open(OUT + ".tmp", "w") as f:
        f.write("\n".join(out) + "\n")
    os.replace(OUT + ".tmp", OUT)
    tmux("display-message", f"Template saved: {sum(o.startswith('new-window') for o in out)} windows")


if __name__ == "__main__":
    main()
