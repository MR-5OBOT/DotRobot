import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Time + calendar as a top-center drop-in overlay. An invisible strip at the
// top-center screen edge is the hover trigger (like the bar's peek strip);
// leaving the card closes it. No keyboard focus, so a hover can't steal the keyboard.
PanelWindow {
    id: win

    readonly property bool open: BarState.calendarOpen
    property int peekH: 8   // invisible hover-trigger strip height at the top edge

    visible: true
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-calendar"

    SystemClock { id: sysClock; precision: SystemClock.Seconds }

    // input region: card-wide strip at the top edge, plus the card itself while
    // it's on-screen (off-screen when closed -> only the strip is interactive).
    // Everything else stays click-through.
    mask: Region {
        x: card.x
        y: 0
        width: card.width
        height: win.peekH
        Region {
            x: card.x
            y: card.y
            width: card.width
            height: card.height
        }
    }

    // hover spans the window but input is limited by the mask: entering the
    // strip opens (after a small dwell), leaving the card closes.
    HoverHandler {
        onHoveredChanged: {
            if (hovered)
                dwell.restart();
            else {
                dwell.stop();
                BarState.calendarOpen = false;
            }
        }
    }
    Timer { id: dwell; interval: 180; onTriggered: BarState.calendarOpen = true }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // drops in flush with the strip so the pointer never leaves the mask
        anchors.topMargin: win.open ? win.peekH : -height
        width: content.implicitWidth + 28
        height: content.implicitHeight + 28
        color: Theme.bg

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: content
            anchors.centerIn: parent
            spacing: 10

            RowLayout {  // time header: HH:mm big, seconds small
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Text {
                    text: Qt.formatDateTime(sysClock.date, "HH:mm")
                    font.family: Theme.font
                    font.pixelSize: 26
                    font.bold: true
                    color: Theme.text
                }
                Text {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 4
                    text: Qt.formatDateTime(sysClock.date, "ss")
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.pink
                }
            }

            Rectangle {  // hairline between time and month grid
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            Calendar {
                now: sysClock.date
            }
        }
    }
}
