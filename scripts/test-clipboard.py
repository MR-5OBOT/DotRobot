#!/usr/bin/env python3
"""Run on Wayland: python scripts/test-clipboard.py (uses a temporary history)."""
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import time
import zlib


def png_chunk(kind, data):
    return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data))


source = Path(__file__).resolve().parents[1] / 'dotfiles/.config/quickshell'
with tempfile.TemporaryDirectory(prefix='clipboard-test-') as directory:
    tmp = Path(directory)
    runtime = tmp / 'runtime'
    runtime.mkdir(mode=0o700)
    display = os.environ['WAYLAND_DISPLAY']
    if not display.startswith('/'):
        display = str(Path(os.environ['XDG_RUNTIME_DIR']) / display)
    env = dict(os.environ, XDG_RUNTIME_DIR=str(runtime), WAYLAND_DISPLAY=display,
               CLIPHIST_DB_PATH=str(tmp / 'db'), PATH=str(tmp) + ':' + os.environ['PATH'])
    for name in ('Clipboard.qml', 'Theme.qml', 'Icon.qml'):
        shutil.copyfile(source / name, tmp / name)
    (tmp / 'wl-copy').write_text('#!/bin/sh\ncat > "' + str(tmp / 'copied') + '"\n')
    (tmp / 'wl-copy').chmod(0o700)
    png = (b'\x89PNG\r\n\x1a\n'
           + png_chunk(b'IHDR', struct.pack('!2I5B', 320, 180, 8, 2, 0, 0, 0))
           + png_chunk(b'IDAT', zlib.compress((b'\0' + b'\x86\x2f\x55' * 320) * 180))
           + png_chunk(b'IEND', b''))
    message = '<b>Plain text</b>\n' + 'Full clipboard preview. ' * 50
    for data in (message.encode(), b'Second text entry', png):
        subprocess.run(['cliphist', 'store'], input=data, env=env, check=True)
    (tmp / 'shell.qml').write_text('''
import QtQuick
import Quickshell
import Quickshell.Io
ShellRoot {
    id: root
    Clipboard { id: clipboard }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = find(child, name);
            if (found) return found;
        }
        return null;
    }
    IpcHandler {
        target: "test"
        function state(): string {
            const image = root.find(clipboard.contentItem, "clipboardPreviewImage");
            const text = root.find(clipboard.contentItem, "clipboardPreviewText");
            return JSON.stringify({open: clipboard.open, count: clipboard.matches.length, sel: clipboard.sel,
                ready: image.status === Image.Ready, source: String(image.source),
                text: text.text, textFormat: text.textFormat,
                paintedWidth: image.paintedWidth, paintedHeight: image.paintedHeight});
        }
        function select(index: int): void { clipboard.sel = index; }
        function search(query: string): void { clipboard.query = query; }
        function copy(): void { clipboard.copy(); }
        function remove(): void { clipboard.remove(); }
    }
}
''')
    with (tmp / 'log').open('w+') as log:
        process = subprocess.Popen(['qs', '-p', str(tmp)], env=env, stdout=log, stderr=log)
        try:
            def call(target, method, *args):
                return subprocess.run(['qs', 'ipc', '-p', str(tmp), 'call', target, method,
                                       *map(str, args)], env=env, capture_output=True,
                                      text=True, timeout=3)

            def wait_for(predicate):
                deadline = time.monotonic() + 8
                while time.monotonic() < deadline:
                    result = call('test', 'state')
                    if result.returncode == 0:
                        state = json.loads(result.stdout)
                        if predicate(state):
                            return state
                    time.sleep(0.05)
                raise AssertionError('Unexpected preview state: ' + result.stdout + result.stderr)

            wait_for(lambda s: s['count'] == 0)
            assert call('clipboard', 'toggle').returncode == 0
            state = wait_for(lambda s: s['count'] == 3 and s['ready'])
            assert state['paintedWidth'] > 300
            assert abs(state['paintedWidth'] / state['paintedHeight'] - 320 / 180) < 0.01
            call('test', 'select', 2)
            wait_for(lambda s: s['text'] == message and s['textFormat'] == 0 and not s['source'])
            for index in (0, 2, 1, 0, 1):
                call('test', 'select', index)
            wait_for(lambda s: s['text'] == 'Second text entry' and not s['source'])
            call('test', 'select', 0)
            call('test', 'search', 'png')
            wait_for(lambda s: s['count'] == 1 and s['ready'])
            call('test', 'search', 'no-such-clipboard-entry')
            wait_for(lambda s: s['count'] == 0 and not s['source'] and not s['text'])
            call('test', 'search', '')
            wait_for(lambda s: s['count'] == 3 and s['ready'])
            call('test', 'copy')
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline and not (tmp / 'copied').exists():
                time.sleep(0.05)
            assert (tmp / 'copied').read_bytes() == png
            wait_for(lambda s: not s['open'])
            time.sleep(0.25)  # Let the close animation and Wayland focus release finish.
            call('clipboard', 'toggle')
            wait_for(lambda s: s['open'] and s['count'] == 3 and s['ready'])
            call('test', 'remove')
            wait_for(lambda s: s['count'] == 2 and s['text'] == 'Second text entry')
            print('PASS: image preview, full plain text, navigation, search, copy and delete')
        except Exception:
            log.seek(0)
            print(log.read())
            raise
        finally:
            process.terminate()
            process.wait(timeout=5)
