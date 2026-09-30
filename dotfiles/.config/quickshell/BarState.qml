pragma Singleton
import QtQuick
import Quickshell

QtObject {
    // launcher visibility lives here so both the bar button and IPC can toggle it
    property bool launcherOpen: false

    // calculator: keypad + paper/tape modes
    property bool calcOpen: false

    // Set by shell.qml from the island. A toast dropped below an open widget
    // notch sits under the widget's full-screen window, so the notch cards use
    // widgetMask (whole screen minus the toast) and keep the island windows in
    // their focus grab: the toast takes its own clicks and the widget stays open.
    // They ignore exclusive zones, so their coordinates are the island's.
    property var islandWindows: []
    property rect toastHole: Qt.rect(0, 0, 0, 0)
    readonly property Region widgetMask: Region {
        width: 100000   // any size past the screen; the compositor clips it
        height: 100000
        Region {
            intersection: Intersection.Subtract
            x: toastHole.x
            y: toastHole.y
            width: toastHole.width
            height: toastHole.height
        }
    }
}
