pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Current wallpaper path, persisted to a state file so qs redraws it on
// startup — replaces the awww daemon. The picker writes here; every per-screen
// Wallpaper background binds to `path`. watchChanges catches external writes
// (e.g. a random-wallpaper script) too.
Singleton {
    id: root
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/qs-wallpaper"
    readonly property string fallback: Quickshell.env("HOME") + "/Pictures/wallpapers/MR5OBOT.jpg"
    property string path: fallback

    function apply(p) {
        if (!p)
            return;
        root.path = p;      // instant on-screen swap
        file.setText(p);    // persist for next startup
    }

    FileView {
        id: file
        path: root.stateFile
        blockLoading: true
        watchChanges: true
        printErrors: false   // first run: file won't exist yet, that's fine
        onLoaded: {
            const t = text().trim();
            if (t.length > 0)
                root.path = t;
        }
        onFileChanged: reload()
    }
}
