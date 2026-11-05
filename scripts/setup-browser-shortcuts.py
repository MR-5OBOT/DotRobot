#!/usr/bin/env python3
"""Apply the saved Brovim browser shortcuts to a closed Helium profile.

Only helium.browser.custom_accelerators is replaced. Extension shortcuts and
all other preferences stay intact. Requires Python 3, with no extra packages.
"""

import argparse
import json
import os
from pathlib import Path
import stat
import shlex
import sys
import tempfile


PRESET = (Path(__file__).resolve().parent.parent / "assets" / "presets"
          / "browser-flags" / "helium-brovim-shortcuts.json")
KEY = "custom_accelerators"


def load_object(path):
    value = json.loads(path.read_text())
    if not isinstance(value, dict):
        raise ValueError(f"Expected a JSON object in {path}")
    return value


def validate_shortcuts(value):
    # null in a backup means the preference did not exist before applying.
    if value is None:
        return
    if not isinstance(value, dict):
        raise ValueError("custom_accelerators must be an object or null")
    for command, changes in value.items():
        if not command.isdecimal() or not isinstance(changes, dict):
            raise ValueError(f"Invalid browser command: {command}")
        for kind, shortcuts in changes.items():
            if kind not in {"added", "removed"} or not isinstance(shortcuts, list):
                raise ValueError(f"Invalid shortcut changes for command {command}")
            if not all(isinstance(key, str) and key for key in shortcuts):
                raise ValueError(f"Invalid shortcuts for command {command}")


def require_closed(user_data):
    # Chromium holds this lock across profiles. Its symlink is deliberately dangling.
    if os.path.lexists(user_data / "SingletonLock"):
        raise ValueError(f"Close Helium completely first ({user_data}/SingletonLock).")


def apply(profile, shortcuts, dry_run):
    prefs = profile / "Preferences"
    if not prefs.is_file():
        raise ValueError(f"Profile not found: {prefs}. Open Helium once first.")
    original = prefs.read_bytes()
    data = json.loads(original)
    if not isinstance(data, dict):
        raise ValueError(f"Expected a JSON object in {prefs}")
    helium = data.get("helium", {})
    if not isinstance(helium, dict) or not isinstance(helium.get("browser", {}), dict):
        raise ValueError("Invalid Helium browser preferences")
    previous = helium.get("browser", {}).get(KEY)
    validate_shortcuts(previous)
    if previous == shortcuts:
        print(f"Already configured: {profile}")
        return
    if dry_run:
        print(f"Would replace browser shortcuts in {prefs}")
        print("Brovim and other extension shortcut assignments are preserved.")
        return

    require_closed(profile.parent)
    browser = data.setdefault("helium", {}).setdefault("browser", {})
    if shortcuts is None:
        browser.pop(KEY, None)
    else:
        browser[KEY] = shortcuts

    with tempfile.NamedTemporaryFile(
        mode="w", prefix="Brovim-shortcuts-backup-", suffix=".json",
        dir=profile, delete=False,
    ) as backup:
        json.dump({"format": 1, KEY: previous}, backup, indent=2)
        backup.write("\n")
    print(f"Shortcut backup: {backup.name}")

    # Replace atomically in the same directory, retaining the preference file's mode.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=profile, delete=False) as out:
            temporary = Path(out.name)
            os.fchmod(out.fileno(), stat.S_IMODE(prefs.stat().st_mode))
            json.dump(data, out, ensure_ascii=False, separators=(",", ":"))
            out.write("\n")
            out.flush()
            os.fsync(out.fileno())
        require_closed(profile.parent)
        if prefs.read_bytes() != original:
            raise ValueError("Preferences changed during setup; no changes applied. Close Helium and retry.")
        temporary.replace(prefs)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    print(f"Applied browser shortcuts: {profile}")
    print("Undo: " + shlex.join([sys.argv[0], "--profile-dir", str(profile),
                                "--preset", backup.name]))


def main():
    config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--profile-dir", type=Path,
        default=config / "net.imput.helium" / "Default",
        help="Helium profile directory containing Preferences (default: %(default)s)",
    )
    parser.add_argument(
        "--preset", type=Path, default=PRESET,
        help="shortcut preset or a backup printed by a previous run",
    )
    parser.add_argument("--dry-run", action="store_true", help="preview without writing files")
    args = parser.parse_args()
    try:
        preset = load_object(args.preset.expanduser())
        if preset.get("format") != 1 or KEY not in preset:
            raise ValueError("Unrecognized shortcut preset; expected format 1")
        shortcuts = preset[KEY]
        validate_shortcuts(shortcuts)
        apply(args.profile_dir.expanduser().resolve(), shortcuts, args.dry_run)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Error: {error}\n")


if __name__ == "__main__":
    main()
