pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Live wallpaper-derived palette. matugen writes a small colour JSON on every
 * wallpaper change (via wallcolors.py) and this singleton watches it, so the
 * tokens update the moment the wallpaper does. Theme reads these only while the
 * dynamic-palette flag is on; otherwise the curated washi hex wins. Defaults are
 * a warm fallback so a missing file still yields a usable scheme. Surfaces and
 * the accent ramp come from here; text stays locked in Theme for contrast.
 */
Singleton {
    id: root

    /**
     * Follow the main shell's wallpaper picker. It persists the current path to
     * qs-wallpaper, so every change re-runs wallcolors.py and the colors.json
     * watch below picks up the new palette.
     */
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/qs-wallpaper"
        watchChanges: true
        printErrors: false
        onLoaded: {
            const p = text().trim();
            if (p.length > 0)
                Quickshell.execDetached(["python3", Config.islandPath("scripts", "wallcolors.py"), p]);
        }
        onFileChanged: reload()
    }

    readonly property string surface: adapter.surface
    readonly property string primary: adapter.primary
    readonly property string primaryContainer: adapter.primary_container
    readonly property string onPrimaryContainer: adapter.on_primary_container
    readonly property string outline: adapter.outline
    readonly property string cream: adapter.cream
    readonly property string bright: adapter.bright
    readonly property string subtle: adapter.subtle
    readonly property string dim: adapter.dim
    readonly property string faint: adapter.faint
    readonly property string iconDim: adapter.icon_dim
    readonly property string tickRest: adapter.tick_rest

    FileView {
        id: file
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/island/colors.json"
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string surface: "#18120b"
            property string primary: "#f5bd6f"
            property string primary_container: "#633f00"
            property string on_primary_container: "#ffddb3"
            property string outline: "#9c8f80"
            property string cream: "#e6d6cb"
            property string bright: "#fff6f0"
            property string subtle: "#b9a99e"
            property string dim: "#8a7d74"
            property string faint: "#6f635b"
            property string icon_dim: "#cdbfb4"
            property string tick_rest: "#cbb6a3"
        }
    }
}
