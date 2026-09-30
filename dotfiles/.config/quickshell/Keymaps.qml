import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Keymap cheat sheet: `qs ipc call keymaps toggle` (SUPER + /). A pure-black
// top-edge notch; closes on Esc, the × button, or a click anywhere outside it.
// Add a keyboard or app by appending a group below. In `keys`, " + " and " / "
// between key names draw as separators and everything else as a keycap.
PanelWindow {
    id: win

    readonly property var groups: [
        {
            title: "ZIYOULANG T60",
            note: "Fn layer · on-board, works on any OS",
            binds: [
                ["Fn + \\", "Cycle lighting effect (the \\ beside Enter)"],
                ["Fn + ] / [", "Backlight brightness up / down"],
                ["Fn + ' / ;", "Effect speed up / down"],
                ["Fn + Right Shift", "Hold 2 s: / Alt Menu Ctrl turn into arrows"],
                ["Fn + Win", "Lock the Win key"],
                ["Fn + 1 … =", "F1 – F12"],
                ["Fn + Space", "Reset to factory settings"],
                ["Fn + other", "Media, volume, Home, Mail (side legends)"]
            ]
        }
    ]

    property bool open: false
    readonly property real drop: open ? card.height : 0  // island drops toasts below the card

    IpcHandler {
        target: "keymaps"
        function toggle(): void { win.open = !win.open; }
    }

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    mask: BarState.widgetMask
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-keymaps"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        active: win.open
        windows: [win].concat(BarState.islandWindows)
        onCleared: win.open = false
    }

    MouseArea {  // click-outside, any button
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: win.open = false
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: win.open ? 0 : -height   // hangs flush from the top edge and slides out of it
        width: 480
        height: col.implicitHeight + 28
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Theme.notchRadius
        bottomRightRadius: Theme.notchRadius
        color: "#000000"

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }  // swallow clicks on the card

        NotchEars {
            anchors.top: parent.top
            width: parent.width
            color: card.color
        }

        Item {  // key sink
            focus: true
            Keys.onEscapePressed: win.open = false
        }

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 12; leftMargin: 18; rightMargin: 12 }
            spacing: 0

            Repeater {
                model: win.groups

                ColumnLayout {
                    id: group
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.topMargin: index > 0 ? 14 : 0
                    spacing: 0

                    RowLayout {  // header; the first one carries the close button
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        Layout.bottomMargin: 8
                        spacing: 10

                        Icon { text: "keyboard"; size: 18; color: Theme.notchAccent }
                        Text {
                            text: group.modelData.title
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: Theme.text
                        }
                        Text {
                            Layout.fillWidth: true
                            text: group.modelData.note ?? ""
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: Theme.dim
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: group.index === 0
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 14
                            color: closeMa.containsMouse ? "#1a1a1a" : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Icon {
                                anchors.centerIn: parent
                                text: "close"
                                size: 16
                                color: closeMa.containsMouse ? Theme.text : Theme.dim
                            }
                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.open = false
                            }
                        }
                    }

                    Repeater {
                        model: group.modelData.binds

                        Rectangle {  // one bind: keycaps left, what it does right
                            id: row
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.rightMargin: 6
                            Layout.preferredHeight: 34
                            radius: 8
                            color: rowMa.containsMouse ? "#0c0c0c" : "transparent"

                            MouseArea { id: rowMa; anchors.fill: parent; hoverEnabled: true }

                            Row {
                                id: caps
                                anchors.verticalCenter: parent.verticalCenter
                                width: 150
                                spacing: 5

                                Repeater {
                                    model: row.modelData[0].split(/ ([+\/]) /)

                                    Rectangle {
                                        id: cap
                                        required property string modelData
                                        required property int index
                                        readonly property bool sep: index % 2 === 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: sep ? label.implicitWidth : Math.max(24, label.implicitWidth + 14)
                                        height: 22
                                        radius: 5
                                        color: sep ? "transparent" : "#0a0a0a"
                                        border.width: sep ? 0 : 1
                                        border.color: "#262626"

                                        Rectangle {  // keycap lip
                                            visible: !cap.sep
                                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
                                            height: 2
                                            radius: 4
                                            color: "#161616"
                                        }

                                        Text {
                                            id: label
                                            anchors.centerIn: parent
                                            anchors.verticalCenterOffset: cap.sep ? 0 : -1
                                            text: cap.modelData
                                            font.family: Theme.font
                                            font.pixelSize: 12
                                            font.weight: cap.index === 0 ? Font.Bold : Font.Medium
                                            color: cap.sep ? Theme.dim : cap.index === 0 ? Theme.notchAccent : Theme.text
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors { left: caps.right; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                text: row.modelData[1]
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: rowMa.containsMouse ? Theme.text : "#b4b4b4"
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
