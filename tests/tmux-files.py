#!/usr/bin/env python3
"""Run with TMUX_FILES_INTEGRATION=1 to also exercise a private tmux client."""

import importlib.util
import json
import os
from pathlib import Path
import pty
import select
import struct
import subprocess
import tempfile
import time
import unittest
from unittest.mock import patch
import fcntl
import termios

SCRIPT = Path(__file__).resolve().parents[1] / "dotfiles/.config/tmux/files.py"
spec = importlib.util.spec_from_file_location("tmux_files", SCRIPT)
files = importlib.util.module_from_spec(spec)
spec.loader.exec_module(files)


class FileTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="tmux-files-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def entry(self, name, text="content"):
        path = self.root / name
        path.write_text(text)
        return dict(path=str(path), identity=files.identity(path))

    def test_grid_names_quotes_and_substrings(self):
        for name in ["a", "a b", "ls", "cat猫.txt", "quote's file"]:
            self.entry(name)
        rows = files.entries_for(
            ["$ ls", "'a b'   a   ls", 'cat猫.txt  "quote\'s file"', "$ "], str(self.root), 1
        )
        self.assertEqual(
            [Path(row["path"]).name for row in rows],
            ["a b", "a", "ls", "cat猫.txt", "quote's file"],
        )
        self.assertEqual(rows[-1]["column"], 11)

    def test_long_rows_skip_metadata_and_symlink_target(self):
        for name in ["mr5obot", "target", "other-link"]:
            self.entry(name)
        (self.root / "link").symlink_to("other-link")
        (self.root / "other-link").unlink()
        (self.root / "other-link").symlink_to("target")
        rows = files.entries_for(
            [
                "Permissions Size User Date Modified Name",
                ".rw-r--r-- 0 mr5obot 27 Oct 03:00 target",
                "lrwxrwxrwx - mr5obot 27 Oct 03:00 link -> other-link",
            ],
            str(self.root),
        )
        self.assertEqual([Path(row["path"]).name for row in rows], ["target", "link"])

    def test_last_listing_and_explicit_directory(self):
        folder = self.root / "folder with spaces"
        folder.mkdir()
        start, base, command = files.listing(
            ["$ ls", "old", "$ l 'folder with spaces'", "new"], str(self.root)
        )
        self.assertEqual((start, base, command), (3, str(folder), ["l"]))
        self.entry("one")
        self.entry("two")
        rows = files.entries_for(["one", "unrelated output", "two"], str(self.root))
        self.assertEqual([Path(row["path"]).name for row in rows], ["two"])

    def test_reject_ambiguous_listing(self):
        for command in ["ls -R", "eza --tree", "ls one two", "ls $OTHER", "ls | head"]:
            with self.subTest(command=command), self.assertRaises(ValueError):
                files.listing(["$ " + command], str(self.root))

    def test_copy_move_rename_and_no_overwrite(self):
        entry = self.entry("original")
        files.perform("copy", entry, "copy")
        self.assertEqual((self.root / "copy").read_text(), "content")
        for action in ["copy", "move", "rename"]:
            with self.subTest(action=action), self.assertRaises(FileExistsError):
                files.perform(action, entry, "copy")
            self.assertTrue((self.root / "original").exists())
        files.perform("rename", entry, "renamed")
        self.assertFalse((self.root / "original").exists())
        entry = dict(
            path=str(self.root / "renamed"), identity=files.identity(self.root / "renamed")
        )
        target = self.root / "folder"
        target.mkdir()
        files.perform("move", entry, str(target))
        self.assertEqual((target / "renamed").read_text(), "content")

    def test_copy_directory_preserves_symlinks_and_refuses_self(self):
        folder = self.root / "folder"
        folder.mkdir()
        (folder / "link").symlink_to("../outside")
        entry = dict(path=str(folder), identity=files.identity(folder))
        with self.assertRaises(ValueError):
            files.perform("copy", entry, str(folder / "nested"))
        files.perform("copy", entry, "copy")
        self.assertTrue((self.root / "copy/link").is_symlink())
        self.assertEqual(os.readlink(self.root / "copy/link"), "../outside")

    def test_reject_replaced_entry_and_symlink_destination(self):
        entry = self.entry("source")
        (self.root / "existing").symlink_to("missing")
        with self.assertRaises(FileExistsError):
            files.perform("copy", entry, "existing")
        (self.root / "source").rename(self.root / "old")
        self.entry("source", "replacement")
        with self.assertRaises(ValueError):
            files.perform("trash", entry)
        self.assertEqual((self.root / "source").read_text(), "replacement")

    def test_trash_uses_isolated_trash_directory(self):
        entry = self.entry("trash me")
        data = self.root / "data"
        data.mkdir()
        with patch.dict(os.environ, {"XDG_DATA_HOME": str(data)}):
            files.perform("trash", entry)
        self.assertFalse((self.root / "trash me").exists())
        self.assertEqual((data / "Trash/files/trash me").read_text(), "content")


@unittest.skipUnless(
    os.environ.get("TMUX_FILES_INTEGRATION"),
    "set TMUX_FILES_INTEGRATION=1 for a private tmux client",
)
class TmuxTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="tmux-files-integration-")
        self.addCleanup(self.cleanup)
        self.root = Path(self.temporary.name)
        self.socket = str(self.root / "socket")
        self.folder = self.root / "listing"
        self.folder.mkdir()
        (self.folder / "a-dir").mkdir()
        (self.folder / "a-dir/inside").write_text("inside")
        for name in ["b-file", "c space", "d猫", "e-file"]:
            (self.folder / name).write_text(name)
        (self.root / "data").mkdir()
        (self.root / "bin").mkdir()
        opener = self.root / "bin/xdg-open"
        opener.write_text('#!/bin/sh\nprintf "%s" "$1" > "$OPEN_LOG"\n')
        opener.chmod(0o755)
        self.env = {
            **os.environ,
            "TERM": "xterm-256color",
            "HISTFILE": "/dev/null",
            "XDG_DATA_HOME": str(self.root / "data"),
            "OPEN_LOG": str(self.root / "opened"),
            "PATH": str(self.root / "bin") + ":" + os.environ["PATH"],
        }
        self.env.pop("TMUX", None)
        self.tmux(
            "-f",
            "/dev/null",
            "new-session",
            "-d",
            "-s",
            "files-test",
            "-c",
            str(self.folder),
            "-x",
            "110",
            "-y",
            "30",
            "bash --noprofile --norc -i",
        )
        self.tmux("set-option", "-g", "prefix", "C-Space")
        self.tmux("set-option", "-g", "mode-keys", "vi")
        self.tmux("set-option", "-g", "set-clipboard", "off")
        self.tmux("set-option", "-s", "escape-time", "0")
        self.env["TMUX"] = self.socket + ",0,0"
        result = subprocess.run(
            ["python3", str(SCRIPT), "install"], env=self.env, capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.pid, self.master = pty.fork()
        if self.pid == 0:
            os.execvpe(
                "tmux", ["tmux", "-S", self.socket, "attach-session", "-t", "files-test"], self.env
            )
        fcntl.ioctl(self.master, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 110, 0, 0))
        self.wait(lambda: self.tmux("list-clients", "-F", "#{client_name}"))
        self.client = self.tmux("list-clients", "-F", "#{client_name}")
        self.tmux(
            "send-keys",
            "-t",
            "%0",
            "-l",
            "PS1='$ '; alias l='eza -lah --icons=always --color=always'; export PS1",
        )
        self.tmux("send-keys", "-t", "%0", "Enter")
        self.wait(lambda: "$ " in self.screen())

    def cleanup(self):
        try:
            self.tmux("kill-server")
        except subprocess.CalledProcessError:
            pass
        if hasattr(self, "master"):
            os.close(self.master)
            os.waitpid(self.pid, 0)
        self.temporary.cleanup()

    def tmux(self, *args):
        return subprocess.run(
            ["tmux", "-S", self.socket, *args],
            env=self.env,
            check=True,
            capture_output=True,
            text=True,
        ).stdout.rstrip("\n")

    def drain(self):
        while select.select([self.master], [], [], 0)[0]:
            try:
                os.read(self.master, 65536)
            except OSError:
                break

    def wait(self, predicate):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if hasattr(self, "master"):
                self.drain()
            value = predicate()
            if value:
                return value
            time.sleep(0.02)
        self.fail("Timed out waiting for tmux state. Screen:\n" + self.screen())

    def screen(self, mode=False):
        return self.tmux("capture-pane", "-p", *(["-M"] if mode else []), "-t", "%0")

    def state(self):
        value = self.tmux("show-options", "-pqv", "-t", "%0", files.STATE)
        return json.loads(value) if value else None

    def keys(self, value):
        os.write(self.master, value.encode())

    def start(self, command="l", marker="e-file"):
        self.tmux("send-keys", "-t", "%0", "-l", command)
        self.tmux("send-keys", "-t", "%0", "Enter")
        self.wait(lambda: marker in self.screen() and self.screen().rstrip().endswith("$"))
        before = self.screen()
        self.keys("\x00q")
        self.wait(self.state)
        self.wait(lambda: self.tmux("display-message", "-p", "-t", "%0", "#{pane_in_mode}") == "1")
        self.assertEqual(self.screen(), before, "Do not change the shell's printed output")
        self.assertEqual(
            self.screen(True), before, "Do not rearrange the displayed copy-mode screen"
        )
        return self.state()

    def current(self):
        state = self.state()
        return Path(state["entries"][state["index"]]["path"]).name

    def test_listing_navigation_and_directory_enter(self):
        state = self.start()
        self.assertEqual(
            [Path(entry["path"]).name for entry in state["entries"]],
            ["a-dir", "b-file", "c space", "d猫", "e-file"],
        )
        self.keys("j")
        self.wait(lambda: self.current() == "b-file")
        self.keys("\r")
        self.wait(lambda: (self.root / "opened").exists())
        self.assertEqual((self.root / "opened").read_text(), str(self.folder / "b-file"))
        self.keys("k")
        self.wait(lambda: self.current() == "a-dir")
        self.keys("\r")
        self.wait(
            lambda: self.tmux("display-message", "-p", "-t", "%0", "#{pane_current_path}")
            == str(self.folder / "a-dir")
        )
        self.wait(lambda: "inside" in self.screen())
        self.assertIsNone(self.state())

    def test_literal_prompt_rename_copy_move_and_confirmed_trash(self):
        self.start()
        self.keys("j")
        self.wait(lambda: self.current() == "b-file")
        malicious = "renamed' ; run-shell 'touch INJECTED' ; #$(touch ALSO_INJECTED)"
        self.keys("r")
        self.wait(lambda: self.tmux("show-options", "-pqv", "-t", "%0", "@file-nav-pending"))
        self.keys("\x15" + malicious + "\r")
        self.wait(lambda: (self.folder / malicious).exists())
        self.assertFalse((self.folder / "INJECTED").exists())
        self.assertFalse((self.folder / "ALSO_INJECTED").exists())
        self.wait(lambda: self.current() == "c space")
        self.keys("c")
        self.wait(
            lambda: json.loads(
                self.tmux("show-options", "-pqv", "-t", "%0", "@file-nav-pending") or "{}"
            ).get("action")
            == "copy"
        )
        copied = self.folder / "copied"
        self.keys("\x15" + str(copied) + "\r")
        self.wait(copied.exists)
        self.wait(lambda: not self.tmux("show-options", "-pqv", "-t", "%0", "@file-nav-pending"))
        self.keys("m")
        self.wait(
            lambda: json.loads(
                self.tmux("show-options", "-pqv", "-t", "%0", "@file-nav-pending") or "{}"
            ).get("action")
            == "move"
        )
        moved = self.folder / "moved"
        self.keys("\x15" + str(moved) + "\r")
        self.wait(moved.exists)
        self.wait(lambda: self.current() == "d猫")
        self.tmux("send-keys", "-t", "%0", "-X", "copy-selection-no-clear")
        self.assertEqual(self.tmux("show-buffer"), "d猫")
        self.keys("d")
        self.wait(
            lambda: json.loads(
                self.tmux("show-options", "-pqv", "-t", "%0", "@file-nav-pending") or "{}"
            ).get("action")
            == "trash"
        )
        self.assertTrue((self.folder / "d猫").exists(), "Delete must wait for confirmation")
        self.keys("n")
        time.sleep(0.1)
        self.assertTrue((self.folder / "d猫").exists())
        self.keys("d")
        time.sleep(0.1)
        self.keys("y")
        self.wait(lambda: not (self.folder / "d猫").exists())
        self.assertEqual((self.root / "data/Trash/files/d猫").read_text(), "d猫")
        self.keys("q")
        self.wait(lambda: not self.state())

    def test_stock_zsh_and_grid(self):
        self.tmux("respawn-pane", "-k", "-t", "%0", "-c", str(self.folder), "zsh -f")
        self.tmux("send-keys", "-t", "%0", "-l", "PS1='$ '")
        self.tmux("send-keys", "-t", "%0", "Enter")
        self.wait(lambda: self.screen().rstrip().endswith("$"))
        self.start("ls -AC --color=always")
        self.keys("l")
        self.wait(lambda: self.state()["index"] == 1)
        self.keys("\x1b")
        self.wait(lambda: not self.state())

    def test_reload_and_regular_copy_mode_keep_original_bindings(self):
        before = json.loads(self.tmux("show-options", "-gqv", "@file-nav-bindings"))
        subprocess.run(
            ["python3", str(SCRIPT), "install"], env=self.env, check=True, capture_output=True
        )
        self.assertEqual(
            json.loads(self.tmux("show-options", "-gqv", "@file-nav-bindings")), before
        )
        self.start()
        self.tmux("send-keys", "-t", "%0", "-X", "cancel")
        self.wait(lambda: not self.state())
        self.tmux("copy-mode", "-t", "%0")
        y = int(self.tmux("display-message", "-p", "-t", "%0", "#{copy_cursor_y}"))
        self.keys("k")
        self.wait(
            lambda: int(self.tmux("display-message", "-p", "-t", "%0", "#{copy_cursor_y}")) == y - 1
        )
        self.keys("q")
        self.wait(lambda: self.tmux("display-message", "-p", "-t", "%0", "#{pane_in_mode}") == "0")

    def test_tall_listing_preserves_viewport_and_navigates_scrollback(self):
        for index in range(60):
            (self.folder / f"zz{index:03}").touch()
        self.start(marker="zz059")
        self.assertGreater(self.state()["history"], 0)
        self.assertGreaterEqual(
            self.state()["entries"][self.state()["index"]]["row"], self.state()["history"]
        )
        self.keys("g")
        self.wait(lambda: self.current() == "a-dir")
        self.tmux("send-keys", "-t", "%0", "-X", "copy-selection-no-clear")
        self.assertEqual(self.tmux("show-buffer"), "a-dir")
        self.keys("G")
        self.wait(lambda: self.current() == "zz059")
        self.tmux("send-keys", "-t", "%0", "-X", "copy-selection-no-clear")
        self.assertEqual(self.tmux("show-buffer"), "zz059")
        self.keys("\x00q")
        self.wait(lambda: not self.state())

    def test_resize_exits_before_using_outdated_coordinates(self):
        self.start()
        self.tmux("resize-window", "-t", "files-test:0", "-y", "25")
        self.keys("j")
        self.wait(lambda: not self.state())
        self.assertEqual(self.tmux("display-message", "-p", "-t", "%0", "#{pane_in_mode}"), "0")


if __name__ == "__main__":
    unittest.main(verbosity=2)
