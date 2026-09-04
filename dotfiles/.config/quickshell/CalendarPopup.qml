import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A normal floating window, opened by Super+T or by dwelling in either top
// corner. Because it is an xdg-toplevel, Hyprland owns moving and resizing it.
Scope {
    id: root

    readonly property bool open: BarState.calendarOpen
    property bool keyOpened: false
    property int peekH: 8
    property int corner: 80

    function close() {
        dwell.stop();
        closeGrace.stop();
        keyOpened = false;
        BarState.calendarOpen = false;
    }

    function hoverChanged(hovered) {
        if (hovered) {
            closeGrace.stop();
            if (!root.open)
                dwell.restart();
        } else {
            dwell.stop();
            if (!root.keyOpened)
                closeGrace.restart();
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void {
            if (root.open)
                root.close();
            else {
                root.keyOpened = true;
                BarState.calendarOpen = true;
            }
        }
    }

    Timer {
        id: dwell
        interval: 180
        onTriggered: {
            root.keyOpened = false;
            BarState.calendarOpen = true;
        }
    }
    Timer { id: closeGrace; interval: 500; onTriggered: root.close() }
    SystemClock { id: sysClock; precision: SystemClock.Seconds }

    // Always-on, click-through screen surface whose only input is the two
    // invisible corner strips.
    PanelWindow {
        id: edge

        visible: true
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-calendar-edge"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            x: 0
            y: 0
            width: root.corner
            height: root.peekH
            Region {
                x: edge.width - root.corner
                y: 0
                width: root.corner
                height: root.peekH
            }
        }

        HoverHandler { onHoveredChanged: root.hoverChanged(hovered) }
    }

    FloatingWindow {
        id: popup

        title: "Calendar"
        visible: root.open
        color: Theme.bg
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        onClosed: root.close()

        Rectangle {
            id: card

            anchors.fill: parent
            implicitWidth: content.implicitWidth + 28
            implicitHeight: content.implicitHeight + 28
            color: Theme.bg
            focus: true
            Keys.onEscapePressed: root.close()

            HoverHandler { onHoveredChanged: root.hoverChanged(hovered) }

            ColumnLayout {
                id: content
                anchors.centerIn: parent
                spacing: 10

                RowLayout {
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

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.border
                }

                Calendar { now: sysClock.date }
            }
        }
    }
}
