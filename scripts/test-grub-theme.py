#!/usr/bin/env python3
"""Check installer rollback and updates without touching the real boot files."""
from pathlib import Path
import os
import shlex
import shutil
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]
SOURCE = (REPO / "scripts/setup-grub-theme.sh").read_text()

for case in ("success", "update", "generation_failure", "syntax_failure",
             "missing_windows", "missing_uki", "duplicate", "old_theme"):
    with tempfile.TemporaryDirectory(prefix="test-grub-theme-") as directory:
        root = Path(directory)
        for folder in ("etc/default", "etc/grub.d", "etc/systemd/system",
                       "etc/pacman.d/hooks", "boot/EFI/Linux",
                       "boot/grub/themes/minegrub", "root", "bin", "repo/scripts"):
            (root / folder).mkdir(parents=True, exist_ok=True)
        assets = root / "repo/assets/grub/obsidian"
        shutil.copytree(REPO / "assets/grub/obsidian", assets)
        defaults = root / "etc/default/grub"
        config = root / "boot/grub/grub.cfg"
        generator = root / "etc/grub.d/10_linux"
        header = root / "etc/grub.d/00_header"
        hook = root / "etc/pacman.d/hooks/05-grub-uki-only.hook"
        theme = root / "boot/grub/themes/obsidian"
        original = "GRUB_DEFAULT=0\nGRUB_DISABLE_OS_PROBER=false\nGRUB_THEME=/old/theme.txt\n"
        defaults.write_text(original)
        config.write_text("original menu\n")
        generator.write_text("#!/bin/sh\n")
        generator.chmod(0o755)
        header_original = 'if true; then\n :\nfi; if [ "x$GRUB_BACKGROUND" != x ]; then\n :\nfi\n'
        header.write_text(header_original)
        discovery = root / "etc/grub.d/15_uki"
        discovery.write_text("#!/bin/sh\n")
        discovery.chmod(0o755)
        kernel = root / "boot/EFI/Linux/arch-linux.efi"
        kernel.write_bytes(b"unchanged UKI")
        (root / "boot/grub/themes/minegrub/theme.txt").write_text("original Minegrub")
        (root / "etc/systemd/system/minegrub-update.service").write_text("original updater")
        # All error cases also exercise restoration of an already-installed theme.
        existing = case != "success"
        if existing:
            theme.mkdir()
            (theme / "theme.txt").write_text("previous Obsidian")
            hook.write_text("previous hook")

        script = SOURCE.replace("if (( EUID != 0 )); then", "if false; then")
        assert script != SOURCE
        for prefix in ("/etc/", "/boot/", "/root/"):
            script = script.replace(prefix, str(root / prefix.strip("/")) + "/")
        target = root / "repo/scripts/setup-grub-theme.sh"
        target.write_text(script)
        stub = root / "bin/grub-mkconfig"
        stub.write_text("""#!/usr/bin/env bash
set -euo pipefail
source """ + shlex.quote(str(defaults)) + """
[[ "$GRUB_DISABLE_BOOTNEXT" == true && "$GRUB_TERMINAL_OUTPUT" == gfxterm ]]
[[ "$GRUB_GFXMODE" == 1920x1080,1280x720,1024x768,auto ]]
[[ ! -x """ + shlex.quote(str(generator)) + """ ]]
bash -n """ + shlex.quote(str(header)) + """
case "$CASE" in
  generation_failure) echo partial > "$2.new"; exit 13 ;;
  syntax_failure) printf "menuentry 'unterminated\\n" > "$2"; exit 0 ;;
esac
printf 'set theme=/grub/themes/obsidian/theme.txt\\n' > "$2"
if [[ "$CASE" != missing_uki ]]; then printf 'uki\\n' >> "$2"; fi
if [[ "$CASE" != missing_windows ]]; then printf "menuentry 'Windows Boot Manager' { true; }\\n" >> "$2"; fi
if [[ "$CASE" == duplicate ]]; then printf "menuentry 'extra' --id efi-bootnext-0001 { true; }\\n" >> "$2"; fi
if [[ "$CASE" == old_theme ]]; then printf 'set theme=/themes/minegrub/theme.txt\\n' >> "$2"; fi
""")
        stub.chmod(0o755)
        systemctl = root / "bin/systemctl"
        systemctl.write_text("#!/bin/sh\nexit 0\n")
        systemctl.chmod(0o755)
        result = subprocess.run(["bash", str(target)], capture_output=True, text=True,
                                env={**os.environ, "PATH": str(root / "bin") + ":" + os.environ["PATH"], "CASE": case})
        if case in ("success", "update"):
            assert result.returncode == 0, result.stderr
            assert "Windows Boot Manager" in config.read_text()
            assert (theme / "background.png").is_file()
            assert not (theme / "background.png").is_symlink()
            assert "[Trigger]" in hook.read_text()
            assert not generator.stat().st_mode & 0o111
            assert "fi; if" not in header.read_text()
            backup = next((root / "root").iterdir())
            assert (backup / "grub.cfg").read_text() == "original menu\n"
            assert (backup / "minegrub/theme.txt").read_text() == "original Minegrub"
        else:
            assert result.returncode != 0, case
            assert config.read_text() == "original menu\n", case
            assert defaults.read_text() == original, case
            assert header.read_text() == header_original, case
            assert generator.stat().st_mode & 0o111 == 0o111, case
            assert (theme / "theme.txt").read_text() == "previous Obsidian", case
            assert hook.read_text() == "previous hook", case
        assert kernel.read_bytes() == b"unchanged UKI", case
        assert not list((root / "boot/grub").glob("grub.cfg.obsidian.*")), case
        print(case + ": passed")
