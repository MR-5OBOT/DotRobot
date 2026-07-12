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

    // the bar's visible content rectangle; popouts clamp into its vertical band
    // ponytail: single-screen assumption (last bar wins), same as activePopup
    property Item barContent: null

    // launcher visibility lives here so both the bar button and IPC can toggle it
    property bool launcherOpen: false

    // calendar overlay: opened by hovering the top-center screen edge, closed on hover-out
    property bool calendarOpen: false

    // network menu (nm-applet-style): toggled by clicking the wifi icon
    property bool networkOpen: false

    // calculator: keypad + paper/tape modes
    property bool calcOpen: false
}
