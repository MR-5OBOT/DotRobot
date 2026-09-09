#!/usr/bin/env python3
"""Run with tmux installed: python3 scripts/test-tmux-float.py."""
import os
from pathlib import Path
import pty
import subprocess
import tempfile
import termios
import time


source = Path(__file__).resolve().parents[1] / 'dotfiles/.config/tmux'
with tempfile.TemporaryDirectory(prefix='tmux-float-test-') as directory:
    tmp = Path(directory)
    cwd = tmp / "working dir 'quoted' $(touch SHOULD_NOT_EXIST)"
    cwd.mkdir()
    config = tmp / 'tmux.conf'
    config.write_text(source.joinpath('tmux.conf').read_text().split('##### Plugins #####')[0]
                      .replace('$HOME/.config/tmux/float.sh', str(source / 'float.sh'))
                      + '\nset -g default-shell /bin/sh\n')
    env = dict(os.environ, TMUX='', TERM='xterm-256color', SHELL='/bin/sh')
    command = ['tmux', '-S', str(tmp / 'socket'), '-f', str(config)]
    master, slave = pty.openpty()
    termios.tcsetwinsize(slave, (36, 166))
    os.set_blocking(master, False)
    client = subprocess.Popen(command + ['new-session', '-s', 'main', '-c', str(cwd)],
                              env=env, stdin=slave, stdout=slave, stderr=slave,
                              start_new_session=True)
    output = bytearray()

    def tm(*args):
        try:
            while data := os.read(master, 65536):
                output.extend(data)
        except BlockingIOError:
            pass
        return subprocess.run(command + list(args), env=env, capture_output=True,
                              text=True, timeout=3)

    def wait_for(predicate):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(0.05)
        raise AssertionError(output.decode(errors='replace')[-4000:])

    def floating_active():
        return tm('display-message', '-p', '-t', '=floating-0:', '#{session_attached}').stdout.strip() == '1'

    def floating_exists():
        return tm('has-session', '-t', '=floating-0').returncode == 0

    def original_window():
        return tm('display-message', '-p', '-t', '=main:', '#{window_id}').stdout.strip() == '@0'

    try:
        wait_for(lambda: tm('has-session', '-t', '=main').returncode == 0)
        os.write(master, b'\0o')
        wait_for(lambda: floating_active())
        assert original_window(), 'Opening the float switched away from the current window'
        view = tm('display-message', '-p', '-t', '=main:', '#{pane_id}').stdout.strip()
        pane = tm('display-message', '-p', '-t', '=floating-0:', '#{pane_id}').stdout.strip()
        assert tm('display-message', '-p', '-t', pane, '#{pane_current_path}').stdout.strip() == str(cwd)
        assert tm('display-message', '-p', '-t', pane, '#{pane_width}x#{pane_height}').stdout.strip() == '112x28'
        assert tm('display-message', '-p', '-t', view, '#{pane_floating_flag}').stdout.strip() == '1'
        # Kitty image uploads must reach the real terminal, not a nested parser.
        graphics = b'\x1b_Ga=t,f=24,s=1,v=1,i=2147483000,q=2;AP8A\x1b\\'
        packet = b'\x1bPtmux;' + graphics.replace(b'\x1b', b'\x1b\x1b') + b'\x1b\\'
        escaped = ''.join(f'\\{byte:03o}' for byte in packet)
        os.write(master, f"printf '{escaped}'\n".encode())
        wait_for(lambda: tm('list-clients').returncode == 0 and graphics in output)
        os.write(master, b'FLOAT_CHECK=preserved; printf "ready-%s\\n" "$FLOAT_CHECK"\n')
        wait_for(lambda: 'ready-preserved' in tm('capture-pane', '-p', '-t', pane).stdout)
        tm('rename-window', '-t', '=main:', 'renamed terminal')
        os.write(master, b'\0o')
        wait_for(lambda: not floating_active())
        wait_for(lambda: tm('list-windows', '-t', '=main', '-F', '#{window_id}').stdout.count('\n') == 1)
        assert original_window()
        os.write(master, b'\0o')
        wait_for(lambda: floating_active())
        assert original_window()
        view = tm('display-message', '-p', '-t', '=main:', '#{pane_id}').stdout.strip()
        assert tm('display-message', '-p', '-t', '=floating-0:', '#{pane_id}').stdout.strip() == pane
        os.write(master, b'printf "reopened-%s\\n" "$FLOAT_CHECK"\n')
        wait_for(lambda: 'reopened-preserved' in tm('capture-pane', '-p', '-t', pane).stdout)
        # Escape and Ctrl-C belong to the terminal; prefix+[ still enters copy mode.
        os.write(master, b'\x1b\x03\0[')
        wait_for(lambda: tm('display-message', '-p', '-t', pane, '#{pane_in_mode}').stdout.strip() == '1')
        os.write(master, b'q\0x')
        wait_for(lambda: not floating_exists())
        assert tm('has-session', '-t', '=main').returncode == 0
        os.write(master, b'\0o')
        wait_for(lambda: floating_active())
        assert original_window()
        assert tm('display-message', '-p', '-t', '=floating-0:', '#{pane_id}').stdout.strip() != pane
        os.write(master, b'exit\n')
        wait_for(lambda: not floating_exists())
        assert tm('has-session', '-t', '=main').returncode == 0
        assert tm('list-windows', '-t', '=main', '-F', '#{window_id}').stdout.count('\n') == 1
        assert not (cwd / 'SHOULD_NOT_EXIST').exists()
        assert original_window()
        print('PASS: current-window overlay, image passthrough, working directory, hide/reopen, rename, shell state, copy mode, close and exit')
    finally:
        tm('kill-server')
        client.wait(timeout=5)
        os.close(master)
        os.close(slave)
