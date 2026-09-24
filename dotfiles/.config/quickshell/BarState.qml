pragma Singleton
import QtQuick

QtObject {
    // launcher visibility lives here so both the bar button and IPC can toggle it
    property bool launcherOpen: false

    // calculator: keypad + paper/tape modes
    property bool calcOpen: false
}
