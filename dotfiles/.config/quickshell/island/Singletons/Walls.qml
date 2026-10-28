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
    property string activePath: ""

    function apply(path, output) {
        var out = output === undefined ? "" : output;
        if (applyProc.running) {
            queuedApplies = queuedApplies.concat([{path: path, output: out}]);
            return;
        }
        run(path, out);
    }

    function run(path, out) {
        root.activePath = path;
        applyProc.command = out.length > 0
            ? ["bash", root.setScript, "set", path, out]
            : ["bash", root.setScript, "set", path];
        applyProc.running = true;
    }

    /** [output, path] pairs from wallpaper.sh's map, re-read whenever a set rewrites it. */
    property var shown: []

    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/island-wallpaper-map"
        watchChanges: true
        printErrors: false
        onLoaded: root.shown = text().split("\n").filter(l => l.indexOf("\t") > 0).map(l => l.split("\t"))
        onFileChanged: reload()
    }

    /**
     * awww decodes a still once at set time, so a file overwritten in place (an
     * editor exporting over the same name) kept its old pixels on screen. Every
     * shown still is watched and re-applied to the outputs showing it; one save
     * fires several change events (truncate, write), so they settle first.
     * Videos are skipped: wallpaper.sh never restarts mpvpaper on the same path.
     */
    Instantiator {
        model: [...new Set(root.shown.map(e => e[1]))].filter(p => !/\.(mp4|webm|mkv|mov)$/i.test(p))
        delegate: FileView {
            required property string modelData
            path: modelData
            preload: false
            watchChanges: true
            printErrors: false
            onFileChanged: settle.restart()
            property Timer settle: Timer { interval: 500; onTriggered: root.reapply(modelData) }
        }
    }

    function reapply(path) {
        var outs = root.shown.filter(e => e[1] === path).map(e => e[0]);
        if (outs.length === root.shown.length)
            apply(path);
        else
            outs.forEach(o => apply(path, o));
    }

    Process {
        id: applyProc
        onExited: function(code) {
            if (code === 69) {
                root.queuedApplies = root.queuedApplies.filter(function(item) { return item.path !== root.activePath; });
                Quickshell.execDetached(["notify-send", "-a", "Wallpaper", "Video wallpaper unavailable", "Video playback is not installed."]);
            }
            if (root.queuedApplies.length) {
                var next = root.queuedApplies[0];
                root.queuedApplies = root.queuedApplies.slice(1);
                root.run(next.path, next.output);
            }
        }
    }
}
