pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Shared session flags persisted to a small JSON file and watched for external
 * change, so every surface reads and writes the same Do-Not-Disturb, Keep-Awake
 * and appearance state. Toggling in one surface
 * updates the others on the next file event, and the state survives a restart.
 */
Singleton {
    id: root

    property alias dnd: adapter.dnd
    property alias keepAwake: adapter.keepAwake
    property alias clockSeconds: adapter.clockSeconds
    property alias uiScale: adapter.uiScale

    /**
     * First-run UI scale, never a fixed 100%. Every surface sizes off
     * `(screen height / 1080) * uiScale`, so a screen the compositor already
     * scales reports fewer logical pixels and the island comes out small:
     * 1080p at Hyprland scale 1.5 reports 720, which drew it at two thirds.
     * Default to the offered step nearest the ratio that puts it back at 1:1
     * — 150% for that screen, 100% for an unscaled 1080p — so the bar is right
     * out of the box and the Display page only has to override taste.
     */
    readonly property real autoScale: {
        const screens = Quickshell.screens;
        const h = (screens && screens.length > 0 && screens[0].height > 0) ? screens[0].height : 1080;
        const want = 1080 / h;
        const steps = [1.0, 1.15, 1.3, 1.5];   // the Display page's own steps
        let best = steps[0];
        for (let i = 1; i < steps.length; i++)
            if (Math.abs(steps[i] - want) < Math.abs(best - want))
                best = steps[i];
        return best;
    }
    property alias memorySaver: adapter.memorySaver

    FileView {
        id: file
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/island/flags.json"
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property bool dnd: false
            property bool keepAwake: false
            property bool clockSeconds: false
            property real uiScale: root.autoScale
            /** Drop closed surfaces 60 s after they close instead of holding them in RAM all session. */
            property bool memorySaver: true
        }
    }
}
