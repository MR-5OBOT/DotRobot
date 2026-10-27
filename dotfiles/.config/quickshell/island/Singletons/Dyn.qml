pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Live wallpaper-derived accent. wallcolors.py writes a small colour JSON on
 * every wallpaper change and this singleton watches it, so the tokens update
 * the moment the wallpaper does. Theme reads these only while the dynamic or
 * manual palette is on; otherwise its curated hex wins. Defaults are a warm
 * fallback so a missing file still yields a usable accent.
 */
Singleton {
    id: root

    readonly property string primary: adapter.primary
    readonly property string primaryContainer: adapter.primary_container
    readonly property string onPrimaryContainer: adapter.on_primary_container

    FileView {
        id: file
        path: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/island/colors.json"
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string primary: "#f5bd6f"
            property string primary_container: "#633f00"
            property string on_primary_container: "#ffddb3"
        }
    }
}
