pragma Singleton
import QtQuick

// Shared reveal state so the auto-hiding bar stays out while a popup is open
// (moving the mouse onto a popup leaves the bar's own hover region).
//
// Uses a single popup reference, not a counter: a destroyed QObject reads as
// null in QML bindings, so this can't drift/leak across hot-reloads.
QtObject {
    property bool hovered: false        // mouse over the bar
    property var activePopup: null       // the popup currently shown, if any
    readonly property bool revealed: hovered || activePopup !== null

    // true only once the bar has finished sliding fully out; popups gate on this
    // so a fast hover can't open one anchored to a half-revealed item.
    property bool settled: false

    // launcher visibility lives here so both the bar button and IPC can toggle it
    property bool launcherOpen: false
}
