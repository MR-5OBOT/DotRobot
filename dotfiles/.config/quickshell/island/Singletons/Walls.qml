pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Wallpaper bridge: applying routes through wallpaper.sh so the picker shares
 * the exact transition, palette and state path. wallpaper.sh blocks through the
 * whole transition (awww wave, palette), easily 1-2s; a pick landing in that
 * window used to be silently swallowed, so requests are queued in order and
 * choosing several monitors applies the wallpaper to every selected output.
 *
 * Config.wallpaperDir is shared with the picker and the shell backend.
 */
Singleton {
    id: root

    readonly property string wpDir: Config.wallpaperDir
    readonly property string setScript: Config.islandPath("scripts", "wallpaper.sh")

    property var queuedApplies: []

    function apply(path, output) {
        var out = output === undefined ? "" : output;
        if (applyProc.running) {
            queuedApplies = queuedApplies.concat([{path: path, output: out}]);
            return;
        }
        run(path, out);
    }

    function run(path, out) {
        applyProc.command = out.length > 0
            ? ["bash", root.setScript, "set", path, out]
            : ["bash", root.setScript, "set", path];
        applyProc.running = true;
    }

    Process {
        id: applyProc
        onExited: {
            if (root.queuedApplies.length) {
                var next = root.queuedApplies[0];
                root.queuedApplies = root.queuedApplies.slice(1);
                root.run(next.path, next.output);
            }
        }
    }
}
