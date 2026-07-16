import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Time + calendar centered on the screen. Invisible strips at the top-left
// and top-right corners are the hover triggers; the card fades in at screen
// center. Leaving both the strip and the card closes it after a short grace
// (long enough to travel from corner to card). No keyboard focus, so a hover
// can't steal the keyboard.
PanelWindow {
    id: win

    readonly property bool open: BarState.calendarOpen
    property int peekH: 8    // invisible hover-trigger strip height at the top edge
    property int corner: 80  // width of each corner trigger strip

    visible: true
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-calendar"

    SystemClock { id: sysClock; precision: SystemClock.Seconds }

    // input region: a strip in each top corner, plus the card itself while
    // it's on-screen (off-screen when closed -> only the strips are interactive).
    // Everything else stays click-through.
    mask: Region {
        x: 0
        y: 0
        width: win.corner
        height: win.peekH
        Region {
            x: win.width - win.corner
            y: 0
            width: win.corner
            height: win.peekH
        }
        Region {
            x: card.x
            y: card.y
            width: card.visible ? card.width : 0   // no dead zone mid-screen when closed
            height: card.height
        }
    }

    // hover spans the window but input is limited by the mask: entering a
    // corner strip opens (after a small dwell); leaving strip and card closes
    // after a grace long enough to reach the centered card.
    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                dwell.restart();
                closeGrace.stop();
            } else {
                dwell.stop();
                closeGrace.restart();
            }
        }
    }
    Timer { id: dwell; interval: 180; onTriggered: BarState.calendarOpen = true }
    Timer { id: closeGrace; interval: 500; onTriggered: BarState.calendarOpen = false }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: content.implicitWidth + 28
        height: content.implicitHeight + 28
        color: Theme.bg
        // keep it out of the input mask while closed
        visible: opacity > 0.01

        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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
