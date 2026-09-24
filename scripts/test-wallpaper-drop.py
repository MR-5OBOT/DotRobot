#!/usr/bin/env python3
"""Run with Python, curl, file and Node: python3 scripts/test-wallpaper-drop.py."""
import base64
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import subprocess
import sys
import tempfile
from threading import Thread


ROOT = Path(__file__).resolve().parents[1]
ISLAND = ROOT / "dotfiles/.config/quickshell/island"
SCRIPT = ISLAND / "scripts/wallpaper-drop.py"
PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5j8AAAAASUVORK5CYII="
)


class Handler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.path == "/broken.png":
            self.send_response(200)
            self.send_header("Content-Length", str(len(PNG) + 20))
            self.end_headers()
            self.wfile.write(PNG)
        else:
            super().do_GET()


with tempfile.TemporaryDirectory(prefix="wallpaper-drop-test-") as directory:
    tmp = Path(directory)
    sources = tmp / "source"
    sources.mkdir()
    walls = tmp / "walls"
    image = sources / "wall #1.PNG"
    image.write_bytes(PNG)

    def drop(source, ok=True):
        result = subprocess.run([sys.executable, str(SCRIPT), str(source), str(walls)],
                                capture_output=True, text=True, timeout=10)
        assert (result.returncode == 0) == ok, result.stderr
        assert not list(walls.glob(".wallpaper-drop-*")), "Incomplete import left behind"
        return Path(result.stdout.strip()) if ok else None

    saved = drop(image.as_uri())
    assert saved == walls / image.name and saved.read_bytes() == PNG
    assert image.read_bytes() == PNG, "Dropping must copy, not move"
    assert drop(saved.as_uri()) == saved, "Re-dropping a saved wallpaper must be harmless"
    saved.write_bytes(b"existing wallpaper")
    duplicate = drop(image)
    assert duplicate.name == "wall #1-2.PNG" and duplicate.read_bytes() == PNG
    assert saved.read_bytes() == b"existing wallpaper", "Existing wallpaper was overwritten"
    (walls / "wall #1-3.PNG").symlink_to(image)
    assert drop(image).name == "wall #1-4.PNG", "A colliding symlink was followed"

    for name, content in [("app.AppImage", PNG), ("archive.zip", PNG), ("font.ttf", PNG),
                          ("fake.png", b"#!/bin/sh\nexit 0\n"), ("page.png", b"<html>Not an image</html>")]:
        rejected = sources / name
        rejected.write_bytes(content)
        drop(rejected.as_uri(), ok=False)
        assert not (walls / name).exists()
    drop("file://remote-host/wall.png", ok=False)
    drop("ftp://example.com/wall.png", ok=False)
    drop(sources / "missing.png", ok=False)

    server = ThreadingHTTPServer(("127.0.0.1", 0), partial(Handler, directory=str(sources)))
    Thread(target=server.serve_forever, daemon=True).start()
    try:
        url = f"http://127.0.0.1:{server.server_port}"
        downloaded = drop(url + "/wall%20%231.PNG?download=1")
        assert downloaded.read_bytes() == PNG
        for name in ("broken.png", "missing.png", "page.png"):
            drop(url + "/" + name, ok=False)
            assert not (walls / name).exists(), "Failed download was published"
    finally:
        server.shutdown()
        server.server_close()

# Exercise the actual shared QML handlers without starting the desktop services.
subprocess.run(["node", "-", str(ISLAND / "Pill.qml")], check=True, input=r"""
const assert = require('node:assert/strict');
const qml = require('node:fs').readFileSync(process.argv[2], 'utf8');
const pill = {dragStage: '', wallpaperQueue: [], savedAny: false, saveFailed: false,
    get dropBusy() { return this.dragStage === 'saving' || this.dragStage === 'done'; },
    dropExt: eval(qml.match(/readonly property var dropExt: (.+)/)[1])};
const dropResetTimer = {running: false, stop() { this.running = false; }, restart() { this.running = true; }};
const wallpaperDropProc = {};
const Config = {islandPath: (...p) => p.join('/'), wallpaperDir: '/walls'};
for (const name of ['dropLabel', 'droppablePaths', 'dropEntered', 'dropExited', 'dropDropped', 'runNextWallpaper']) {
    const match = qml.match(new RegExp('    function ' + name + '\\(([^)]*)\\) \\{([\\s\\S]*?)^    }', 'm'));
    pill[name] = eval('(function(' + match[1] + ') {' + match[2] + '})');
}
const images = ['file:///tmp/wall%20%231.PNG', 'https://example.com/wall.jpg?download=1'];
assert.deepEqual(pill.droppablePaths([...images, 'file:///tmp/app.AppImage', 'file:///tmp/font.ttf',
    'file:///tmp/archive.tar.gz', 'https://example.com/page', 'ftp://example.com/wall.png']), images);
assert.equal(pill.dropLabel([images[0]]), 'wall #1.PNG');
pill.dropEntered(['file:///tmp/app.AppImage']);
assert.equal(pill.dragStage, 'bad');
assert.equal(pill.dropDropped(['file:///tmp/app.AppImage']), false);
assert.equal(wallpaperDropProc.command, undefined);
assert.equal(pill.dropDropped(images), true);
assert.equal(pill.dragStage, 'saving');
assert.equal(dropResetTimer.running, false, 'Old rejection timer must not hide the save');
assert.deepEqual(wallpaperDropProc.command, ['python3', 'scripts/wallpaper-drop.py', images[0], '/walls']);
assert.equal(pill.dropEntered(images), false);
assert.equal(pill.dropDropped(images), false, 'A second drop must not replace an active queue');
pill.dropExited();
assert.equal(pill.dragStage, 'saving');
pill.runNextWallpaper();
assert.equal(wallpaperDropProc.command[2], images[1]);
pill.savedAny = true;
pill.runNextWallpaper();
assert.equal(pill.dragStage, 'done');
assert.equal(dropResetTimer.running, true);
""", text=True)
print("Wallpaper drop checks passed")
