#!/usr/bin/env python3
"""Exercise GRUB checks and rollback against a disposable fake filesystem."""
import os
import shlex
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parent.parent
original = (repo / 'scripts/setup-grub-theme.sh').read_text()
source_line = 'source_dir=$(cd -- "$(dirname -- "$0")/../assets/grub/obsidian" && pwd)'
assert source_line in original

with tempfile.TemporaryDirectory() as temp:
    base = Path(temp)
    bin_dir = base / 'bin'
    bin_dir.mkdir()
    for name, body in {
        'grub-mkconfig': '#!/bin/sh\nprintf "%s\\n" "$MENU_CONTENT" > "$2"\n',
        'grub-script-check': '#!/bin/sh\nexit 0\n',
    }.items():
        f = bin_dir / name
        f.write_text(body)
        f.chmod(0o755)

    checks = [
        ('missing-uki-file', None, 'Missing or empty required file:'),
        ('missing-uki-entry', 'Windows Boot Manager\n/grub/themes/obsidian/theme.txt', 'Generated menu has no UKI entry.'),
        ('missing-windows', 'uki /EFI/Linux/arch-linux.efi\n/grub/themes/obsidian/theme.txt', 'Generated menu has no Windows Boot Manager entry.'),
        ('missing-theme', 'uki /EFI/Linux/arch-linux.efi\nWindows Boot Manager', 'Generated menu does not reference the Obsidian theme.'),
        ('valid', 'uki /EFI/Linux/arch-linux.efi\nWindows Boot Manager\n/grub/themes/obsidian/theme.txt', None),
    ]
    for case, menu, error in checks:
        root = base / case
        for d in ('boot/EFI/Linux', 'boot/grub/themes/obsidian', 'etc/default', 'etc/grub.d', 'etc/pacman.d/hooks', 'root'):
            (root / d).mkdir(parents=True, exist_ok=True)
        original_files = {
            'etc/default/grub': 'GRUB_DEFAULT=old\n',
            'etc/grub.d/00_header': 'header\n',
            'etc/grub.d/10_linux': 'linux\n',
            'boot/grub/grub.cfg': 'old menu\n',
            'boot/grub/themes/obsidian/old': 'old theme\n',
            'etc/pacman.d/hooks/05-grub-uki-only.hook': 'old hook\n',
        }
        for path, content in original_files.items():
            (root / path).write_text(content)
        (root / 'etc/grub.d/10_linux').chmod(0o755)
        (root / 'etc/grub.d/15_uki').write_text('uki')
        (root / 'etc/grub.d/15_uki').chmod(0o755)
        if menu is not None:
            (root / 'boot/EFI/Linux/arch-linux.efi').write_text('kernel')
        script = original.replace('if (( EUID != 0 )); then', 'if false; then', 1)
        script = script.replace(source_line, 'source_dir=' + shlex.quote(str(repo / 'assets/grub/obsidian')), 1)
        for path in ('/boot', '/etc', '/root'):
            script = script.replace(path, str(root) + path)
        copy = base / (case + '.sh')
        copy.write_text(script)
        env = os.environ | {'PATH': str(bin_dir) + ':' + os.environ['PATH'], 'MENU_CONTENT': menu or ''}
        result = subprocess.run(['bash', str(copy)], env=env, capture_output=True, text=True)
        if error is not None:
            assert result.returncode != 0 and error in result.stderr, (case, result.returncode, result.stderr)
            for path, content in original_files.items():
                assert (root / path).read_text() == content, (case, path)
            assert (root / 'etc/grub.d/10_linux').stat().st_mode & 0o777 == 0o755, case
            print(case, 'reported and preserved the existing menu')
        else:
            assert result.returncode == 0, (result.stdout, result.stderr)
            assert (root / 'boot/grub/grub.cfg').read_text() == menu + '\n'
            assert 'GRUB_THEME=' in (root / 'etc/default/grub').read_text()
            print('valid menu installed in the test filesystem')
        assert not list((root / 'boot/grub').glob('grub.cfg.obsidian.*')), case
