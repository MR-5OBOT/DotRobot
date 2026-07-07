import QtQuick
import Quickshell
import Quickshell.Wayland

// Calendar as a top-center drop-in overlay (like the launcher/clipboard).
// Hovering the bar's clock/calendar icon opens it (BarState.calendarOpen); a
// click outside closes it. No keyboard focus, so a hover can't steal the keyboard.
PanelWindow {
    id: win

    readonly property bool open: BarState.calendarOpen

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-calendar"

    SystemClock { id: sysClock; precision: SystemClock.Minutes }

    MouseArea {  // click-outside catcher
        anchors.fill: parent
        onClicked: BarState.calendarOpen = false
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: win.open ? 8 : -height   // drops in from the top edge
        width: cal.implicitWidth + 28
        height: cal.implicitHeight + 28
        color: Theme.bg

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // swallow clicks on the card

        Calendar {
            id: cal
            anchors.centerIn: parent
            now: sysClock.date
        }
    }
}
