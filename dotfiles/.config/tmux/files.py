#!/usr/bin/env python3
"""Navigate an existing ls/eza listing using tmux's unchanged copy-mode screen."""

import json
import os
from pathlib import Path
import re
import shlex
import stat
import subprocess
import sys
import unicodedata


SCRIPT = os.path.abspath(__file__)
STATE = "@file-nav"
COMMAND = re.compile(r"[$#%>❯➜➤→λ]\s+((?:command\s+)?(?:l|ll|la|ls|eza|exa)(?:\s+.*)?)$")
LONG = re.compile(r"^[bcdlps?.-][rwxstST?-]{9}[+@.]?\s")
HELP = "files: j/k up/down · h/l columns · Enter open/cd · c copy · m move · r rename · d Trash · q/Esc exit"


def tmux(*args):
    return subprocess.run(
        ["tmux", *map(str, args)], check=True, capture_output=True, text=True,
        errors="surrogateescape",
    ).stdout.rstrip("\n")


def quote(value):
    # Quote tmux configuration, whose parser also expands dollar variables.
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$").replace("\n", "\\n") + '"'


def label(value):
    return "".join(c if c.isprintable() else "?" for c in str(value)).replace("#", "##")


def width(text):
    return sum(0 if unicodedata.combining(c) else 2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in text)


def glyphs(text):
    return sum(unicodedata.category(c) not in {"Mn", "Me", "Cf"} for c in text)


def identity(path):
    info = os.lstat(path)
    return [info.st_dev, info.st_ino, stat.S_IFMT(info.st_mode)]


def listing(lines, cwd):
    """Recover only literal, single-directory commands; never evaluate shell text."""
    for row in range(len(lines) - 1, -1, -1):
        match = COMMAND.search(lines[row])
        if not match or LONG.match(lines[row]):
            continue
        words = shlex.split(match[1])
        if words[0] == "command":
            words.pop(0)
        flags, operands = [], []
        value_options = {"-I", "-w", "--ignore", "--width", "--sort", "--time-style", "--time"}
        index = 1
        literal = False
        while index < len(words):
            word = words[index]
            if word in {"|", "||", "&&", ";", "&", ">", "<"}:
                raise ValueError("Use a plain, single-directory ls/eza listing.")
            if not literal and word == "--":
                literal = True
            elif not literal and word.startswith("-"):
                if word in {"--recursive", "--recurse", "--tree", "--directory"} or (not word.startswith("--") and any(c in word for c in "RTd")):
                    raise ValueError("Recursive/tree listings are ambiguous; use l or ls for one directory.")
                flags.append(word)
                if word in value_options:
                    index += 1
                    flags.append(words[index])
            else:
                operands.append(word)
            index += 1
        if len(operands) > 1 or any(c in "".join(operands) for c in "$*?`"):
            raise ValueError("Use one literal directory path per listing.")
        base = os.path.abspath(os.path.join(cwd, os.path.expanduser(operands[0] if operands else ".")))
        if not os.path.isdir(base):
            raise ValueError("This listing does not identify a directory to navigate.")
        return row + 1, base, [words[0], *flags]
    # shortcut: unmarked custom prompts use the current directory; add prompt metadata for other directories.
    return 0, cwd, ["ls"]


def entries_for(lines, base, start=0):
    variants = []
    with os.scandir(base) as directory:
        for item in directory:
            if not all(c.isprintable() for c in item.name):
                continue
            spellings = {item.name, shlex.quote(item.name), json.dumps(item.name, ensure_ascii=False)}
            for spelling in spellings:
                variants.append((spelling, item.path, item.is_symlink()))
    rows = []
    for row in range(start, len(lines)):
        line = lines[row].rstrip()
        if not line or COMMAND.search(line) or line.startswith(("Permissions ", "total ")):
            continue
        long = bool(LONG.match(line))
        symlink = long and line.startswith("l")
        matches = []
        for spelling, path, is_link in variants:
            if symlink and not is_link:
                continue
            for found in re.finditer(re.escape(spelling), line):
                left, right = found.span()
                if left and not line[left - 1].isspace():
                    continue
                tail = line[right:]
                if long:
                    if tail not in {"", "/", "@", "*", "|", "="} and not (is_link and tail.startswith(" -> ")):
                        continue
                elif tail and not tail[0].isspace() and tail[0] not in "/@*|=":
                    continue
                matches.append((left, right, path))
        # Longest names win over substrings; symlink targets must never become entries.
        chosen = []
        matches.sort(key=lambda m: (m[0], -(m[1] - m[0])) if symlink else (-(m[1] - m[0]), m[0]))
        for left, right, path in matches:
            if any(left < other[1] and right > other[0] for other in chosen):
                continue
            if symlink and chosen:
                continue
            chosen.append((left, right, path))
        for left, right, path in sorted(chosen):
            try:
                rows.append(dict(row=row, column=width(line[:left]), offset=glyphs(line[:left]), length=glyphs(line[left:right]), path=path, identity=identity(path)))
            except FileNotFoundError:
                pass
    if not rows:
        raise ValueError("No verified files in the printed listing. Run l or ls first.")
    # Only the last contiguous listing, never unrelated matches in older output.
    split = max((i for i in range(1, len(rows)) if rows[i]["row"] > rows[i - 1]["row"] + 1), default=0)
    return rows[split:]


def perform(action, entry, destination=None):
    source = entry["path"]
    if identity(source) != entry["identity"]:
        raise ValueError("That entry changed since selection. Exit and run a fresh listing.")
    if action == "trash":
        command = ["trash-put", "--", source]
    else:
        if not destination:
            raise ValueError("A destination is required.")
        if action == "rename" and (destination in {".", ".."} or "/" in destination):
            raise ValueError("Rename takes a name; use m to move to another directory.")
        destination = os.path.abspath(os.path.join(os.path.dirname(source), os.path.expanduser(destination)))
        if action != "rename" and os.path.isdir(destination):
            destination = os.path.join(destination, os.path.basename(source))
        if os.path.lexists(destination):
            raise FileExistsError("Destination exists; nothing was overwritten.")
        if not os.path.isdir(os.path.dirname(destination)):
            raise ValueError("The destination's parent directory does not exist.")
        if os.path.isdir(source) and not os.path.islink(source) and os.path.commonpath([os.path.realpath(source), os.path.realpath(destination)]) == os.path.realpath(source):
            raise ValueError("Cannot copy or move a directory inside itself.")
        command = ["cp", "-aT"] if action == "copy" else ["mv", "-T"]
        command += ["--update=none-fail", "--", source, destination]
    result = subprocess.run(command, capture_output=True, text=True, errors="replace")
    if result.returncode:
        raise ValueError(result.stderr.strip() or "The file operation failed.")
    return destination


class Navigator:
    def __init__(self, pane, client):
        if not re.fullmatch(r"%\d+", pane):
            raise ValueError("Invalid tmux pane.")
        self.pane, self.client = pane, client

    def option(self, name, value=None):
        if value is None:
            return tmux("show-options", "-pqv", "-t", self.pane, name)
        tmux("set-option", "-p", "-t", self.pane, name, value)

    def save(self, state):
        self.option(STATE, json.dumps(state, separators=(",", ":")))

    def message(self, text):
        tmux("display-message", "-c", self.client, "-d", "3500", "--", label(text))

    def command(self, action):
        return shlex.join([sys.executable, SCRIPT, action, self.pane, self.client])

    def copy_command(self, *args):
        return ["send-keys", "-t", self.pane, "-X", *map(str, args)]

    def focus(self, state):
        if not state["entries"]:
            self.quit()
            return
        entry = state["entries"][state["index"]]
        position = tmux("display-message", "-p", "-t", self.pane, "#{copy_cursor_y} #{scroll_position}")
        y, scroll = map(int, position.split())
        delta = entry["row"] - (state["history"] + y - scroll)
        commands = [self.copy_command("clear-selection")]
        if delta:
            commands.append(self.copy_command("-N", abs(delta), "cursor-down" if delta > 0 else "cursor-up"))
        commands.append(self.copy_command("start-of-line"))
        if entry["offset"]:
            commands.append(self.copy_command("-N", entry["offset"], "cursor-right"))
        commands.append(self.copy_command("begin-selection"))
        if entry["length"] > 1:
            commands.append(self.copy_command("-N", entry["length"] - 1, "cursor-right"))
        args = []
        for command in commands:
            if args:
                args.append(";")
            args.extend(command)
        tmux(*args)
        self.save(state)

    def start(self):
        if self.option(STATE) and tmux("display-message", "-p", "-t", self.pane, "#{pane_in_mode}") == "1":
            self.quit()
            return
        values = tmux("display-message", "-p", "-t", self.pane, "#{pane_current_path}\n#{history_size}\n#{cursor_y}\n#{pane_width}").splitlines()
        cwd, history, cursor, columns = values[0], *map(int, values[1:])
        lines = tmux("capture-pane", "-p", "-t", self.pane, "-S", "-", "-E", "-").splitlines()
        lines = lines[:history + cursor]
        start, base, listing_command = listing(lines, cwd)
        entries = entries_for(lines, base, start)
        index = next((i for i, entry in enumerate(entries) if entry["row"] >= history), len(entries) - 1)
        state = dict(entries=entries, index=index, history=history, columns=columns, base=base, command=listing_command)
        tmux("copy-mode", "-H", "-t", self.pane)
        self.focus(state)
        self.message(HELP)

    def quit(self):
        tmux("send-keys", "-X", "-t", self.pane, "cancel")
        self.option(STATE, "")
        self.option("@file-nav-pending", "")

    def prompt(self, action, state):
        entry = state["entries"][state["index"]]
        if identity(entry["path"]) != entry["identity"]:
            raise ValueError("The selected entry changed. Run a fresh listing.")
        self.option("@file-nav-pending", json.dumps(dict(action=action, entry=entry)))
        if action == "trash":
            tmux("confirm-before", "-b", "-t", self.client, "-p", label(f"Move {os.path.basename(entry['path'])} to Trash? (y/n)"), "run-shell " + quote(self.command("apply")))
        else:
            prompt = f"{action.capitalize()} {os.path.basename(entry['path'])} {'to name' if action == 'rename' else 'to path'}:"
            initial = os.path.basename(entry["path"]) if action == "rename" else state["base"] + "/"
            # Parsed braces substitute prompt input as data, never as shell/config code.
            config = f"command-prompt -b -l -t {quote(self.client)} -p {quote(label(prompt))} -I {quote(initial)} {{ set-option -p -t {self.pane} @file-nav-input \"%1\" ; run-shell {quote(self.command('apply'))} }}"
            subprocess.run(["tmux", "source-file", "-"], input=config, text=True, check=True, capture_output=True)

    def apply(self, state):
        pending = json.loads(self.option("@file-nav-pending"))
        action, entry = pending["action"], pending["entry"]
        destination = self.option("@file-nav-input") if action != "trash" else None
        result = perform(action, entry, destination)
        if action != "copy":
            state["entries"] = [item for item in state["entries"] if item["path"] != entry["path"]]
            state["index"] = min(state["index"], len(state["entries"]) - 1)
        self.option("@file-nav-pending", "")
        self.focus(state)
        self.message(f"{'Trashed' if action == 'trash' else action.capitalize() + ' complete'}: {result or entry['path']} · printed listing kept; rerun l/ls to refresh")

    def open(self, state):
        entry = state["entries"][state["index"]]
        if identity(entry["path"]) != entry["identity"]:
            raise ValueError("The selected entry changed. Run a fresh listing.")
        if not os.path.isdir(entry["path"]):
            subprocess.Popen(["xdg-open", entry["path"]], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
            self.message(f"Opened {entry['path']}")
            return
        shell, pid = tmux("display-message", "-p", "-t", self.pane, "#{pane_current_command} #{pane_pid}").split()
        if shell not in {"bash", "zsh", "sh", "dash", "ksh", "mksh", "ash"}:
            raise ValueError("Directory cd supports Bash/Zsh/POSIX shells; file actions still work here.")
        process = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
        if process[2] != process[5]:
            raise ValueError("Return to an idle shell prompt before entering a directory.")
        self.quit()
        command = f" cd -- {shlex.quote(entry['path'])} && {shlex.join(state['command'])}"
        tmux("send-keys", "-t", self.pane, "C-c")
        tmux("send-keys", "-t", self.pane, "-l", "--", command)
        tmux("send-keys", "-t", self.pane, "Enter")

    def run(self, action):
        if action == "start":
            self.start()
            return
        if action == "quit":
            self.quit()
            return
        raw = self.option(STATE)
        if not raw:
            return
        state = json.loads(raw)
        if tmux("display-message", "-p", "-t", self.pane, "#{pane_width}") != str(state["columns"]):
            self.quit()
            raise ValueError("Terminal resized; run a fresh listing and press prefix+q again.")
        entries, index = state["entries"], state["index"]
        if action in {"down", "up"}:
            row = entries[index]["row"]
            candidates = [i for i, item in enumerate(entries) if (item["row"] > row if action == "down" else item["row"] < row)]
            if candidates:
                next_row = min(entries[i]["row"] for i in candidates) if action == "down" else max(entries[i]["row"] for i in candidates)
                state["index"] = min((i for i in candidates if entries[i]["row"] == next_row), key=lambda i: abs(entries[i]["column"] - entries[index]["column"]))
        elif action in {"left", "right"}:
            neighbor = index + (1 if action == "right" else -1)
            if 0 <= neighbor < len(entries):
                state["index"] = neighbor
        elif action in {"first", "last"}:
            state["index"] = 0 if action == "first" else len(entries) - 1
        elif action in {"copy", "move", "rename", "trash"}:
            self.prompt(action, state)
            return
        elif action == "apply":
            self.apply(state)
            return
        elif action == "open":
            self.open(state)
            return
        elif action == "help":
            self.message(HELP)
        self.focus(state)


def install():
    bindings = {"j": "down", "Down": "down", "k": "up", "Up": "up", "h": "left", "Left": "left", "l": "right", "Right": "right", "g": "first", "G": "last", "Enter": "open", "c": "copy", "m": "move", "r": "rename", "d": "trash", "q": "quit", "Escape": "quit", "C-c": "quit", "?": "help"}
    originals = json.loads(tmux("show-options", "-gqv", "@file-nav-bindings") or "{}")
    current = {}
    for table in ["copy-mode-vi", "copy-mode"]:
        for line in tmux("list-keys", "-T", table).splitlines():
            match = re.match(r"bind-key\s+(?:-r\s+)?-T\s+\S+\s+(\S+)\s+(.*)", line)
            if match:
                current[table + "/" + match[1]] = match[2]
    for table, key, action in [("prefix", "q", "start"), *((table, key, action) for table in ["copy-mode-vi", "copy-mode"] for key, action in bindings.items())]:
        command = shlex.join([sys.executable, SCRIPT, action]) + " #{pane_id} #{q:client_name}"
        if table == "prefix":
            tmux("bind-key", "-T", table, key, "run-shell", command)
            continue
        name = table + "/" + key
        previous = current.get(name, "")
        if "@file-nav" not in previous:
            originals[name] = previous
        tmux("bind-key", "-T", table, key, "if-shell", "-F", "#{@file-nav}", "run-shell " + quote(command), originals.get(name, ""))
    tmux("set-option", "-g", "@file-nav-bindings", json.dumps(originals))


def main():
    if sys.argv[1:] == ["install"]:
        install()
        return
    action, pane, client = sys.argv[1:]
    nav = Navigator(pane, client)
    try:
        nav.run(action)
    except (OSError, ValueError, IndexError, subprocess.CalledProcessError) as error:
        nav.message(str(error))


if __name__ == "__main__":
    main()
