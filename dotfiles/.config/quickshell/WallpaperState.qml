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

    // awww (a daemon) paints the wallpaper, so it survives quickshell restarts
    // — no flash on reload — and gives the fade. `path` stays the source of
    // truth for the picker, DesktopClock and the bar's wallpaper-derived theme.
    function push(p, transition) {
        Quickshell.execDetached(["awww", "img", p, "--transition-type", transition,
                                 "--transition-duration", "1", "--transition-fps", "60"]);
    }

    function apply(p) {
        if (!p)
            return;
        root.path = p;      // pickers and the theme read this
        file.setText(p);    // persist for next startup
        root.push(p, "fade");
    }

    FileView {
        id: file
        path: root.stateFile
        blockLoading: true
        watchChanges: true
        printErrors: false   // first run: file won't exist yet, that's fine
        onLoaded: {
            const t = text().trim();
            if (t.length > 0) {
                root.path = t;
                root.push(t, "none");   // repaint after a reboot, without a fade
            }
        }
        onFileChanged: reload()
    }
}
