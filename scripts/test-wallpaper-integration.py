#!/usr/bin/env python3
"""Exercise the wallpaper backend with two monitors and a video, without a session."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "dotfiles/.config/quickshell/island/scripts/wallpaper.sh"

with tempfile.TemporaryDirectory(prefix="dotrobot-wallpaper-") as temp:
    base = Path(temp)
    home, state, config, walls, bin_dir = (base / p for p in ("home", "state", "config", "walls", "bin"))
    for path in (home, state / "island", config / "mr5obot", walls, bin_dir):
        path.mkdir(parents=True)
    still, video = walls / "still #1.png", walls / "clip.mp4"
    still.write_bytes(b"still")
    video.write_bytes(b"video")
    (state / "island/flags.json").write_text(json.dumps({
        "paletteMode": "manual", "manualHue": 155, "manualDark": False
    }))
    (config / "mr5obot/settings.json").write_text(json.dumps({"wallpaperDir": str(walls)}))
    log = base / "calls"

    def stub(name, body):
        path = bin_dir / name
        path.write_text("#!/usr/bin/env bash\n" + body + "\n")
        path.chmod(0o755)

    stub("awww", '[[ "$1" != img ]] || printf "awww %s\\n" "$*" >> "$MOCK_LOG"')
    stub("hyprctl", '''if [[ "$1" == monitors ]]; then
  printf '%s\\n' '[{"name":"DP-1","focused":true},{"name":"DP-2","focused":false}]'
fi''')
    stub("ffmpeg", 'printf frame > "${@: -1}"')
    stub("pgrep", 'exit 1')
    stub("setsid", 'shift; "$@"')
    stub("mpvpaper", 'printf "mpvpaper %s\\n" "$*" >> "$MOCK_LOG"')
    stub("python3", 'printf "palette %s\\n" "$*" >> "$MOCK_LOG"')
    stub("busctl", 'exit 0')

    env = dict(os.environ, HOME=str(home), XDG_STATE_HOME=str(state),
               XDG_CONFIG_HOME=str(config), MOCK_LOG=str(log),
               PATH=str(bin_dir) + os.pathsep + os.environ["PATH"])

    def run(*args):
        subprocess.run(["bash", str(SCRIPT), *map(str, args)], env=env,
                       check=True, capture_output=True, text=True, timeout=15)

    run("resolve")
    assert (state / "island-wallpaper-dir").read_text().strip() == str(walls)
    run("set", still, "DP-1")
    run("set", still, "DP-2")
    mapped = dict(line.split("\t", 1) for line in
                  (state / "island-wallpaper-map").read_text().splitlines())
    assert mapped == {"DP-1": str(still), "DP-2": str(still)}, mapped
    assert (state / "island-wallpaper-history").read_text().splitlines() == [str(still)]

    run("set", video, "DP-2")
    mapped = dict(line.split("\t", 1) for line in
                  (state / "island-wallpaper-map").read_text().splitlines())
    assert mapped == {"DP-1": str(still), "DP-2": str(video)}, mapped
    assert (state / "island-wallpaper").read_text().strip() == str(still)
    assert (state / "island-wallpaper-history").read_text().splitlines() == [str(video), str(still)]
    calls = log.read_text()
    assert f"mpvpaper -p -o " in calls and f" DP-2 {video}" in calls, calls
    assert "palette " in calls and "--hue 155 light" in calls, calls

    run("set", still, "all")
    assert (state / "island-wallpaper-history").read_text().splitlines() == [str(still), str(video)]

    cache = base / "custom-cache"
    subprocess.run([sys.executable, str(SCRIPT.with_name("wallcolors.py")),
                    "--hue", "155", "light"],
                   env=dict(os.environ, HOME=str(home), XDG_CACHE_HOME=str(cache)), check=True)
    palette = json.loads((cache / "island/colors.json").read_text())
    assert palette["primary"].startswith("#") and len(palette["primary"]) == 7
    assert not (cache / "island/kitty-colors").exists()

subprocess.run(["node", "-", str(ROOT / "dotfiles/.config/quickshell/WallpaperPanel.qml"),
                str(ROOT / "dotfiles/.config/quickshell/island/Singletons/Walls.qml")],
               input=r"""
const assert = require('node:assert/strict');
const fs = require('node:fs');
const panel = fs.readFileSync(process.argv[2], 'utf8');
const bridge = panel.match(/function onWallpaperChanged\(screenName, path, transition\) \{([\s\S]*?)^        \}/m);
assert(bridge);
let sent = [];
new Function('screenName', 'path', 'transition', 'Island', bridge[1])(
    'DP-2', '/walls/clip.mp4', 'fade', {Walls: {apply: (...args) => sent.push(args)}});
assert.deepEqual(sent, [['/walls/clip.mp4', 'DP-2']]);
const walls = fs.readFileSync(process.argv[3], 'utf8');
const apply = walls.match(/    function apply\(path, output\) \{([\s\S]*?)^    \}/m);
assert(apply);
const root = {queuedApplies: []};
const applyProc = {running: true};
const enqueue = new Function('path', 'output', 'root', 'applyProc', 'with (root) {' + apply[1] + '}');
enqueue('/walls/a.png', 'DP-1', root, applyProc);
enqueue('/walls/b.png', 'DP-2', root, applyProc);
assert.deepEqual(root.queuedApplies, [
    {path: '/walls/a.png', output: 'DP-1'},
    {path: '/walls/b.png', output: 'DP-2'}]);
""", text=True, check=True)

print("wallpaper integration tests passed")
