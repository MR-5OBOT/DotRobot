import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Caelestia-style state pips, square (0 radius): small dot = empty,
// filled = occupied, pink = focused.
ColumnLayout {
    id: root
    spacing: 8

    readonly property var wss: Hyprland.workspaces.values
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1
    // show at least 1..5, extend if higher workspaces exist
    readonly property int count: Math.max(5, ...wss.map(w => w.id), 5)

    Repeater {
        model: root.count

        delegate: Item {
            required property int index
            readonly property int wsId: index + 1
            readonly property bool occupied: root.wss.some(w => w.id === wsId)
            readonly property bool focused: root.focusedId === wsId

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 22
            implicitHeight: 22

            Rectangle {
                anchors.centerIn: parent
                // focused: big pink · occupied: medium filled · empty: tiny dot
                width: parent.focused ? 18 : parent.occupied ? 12 : 6
                height: width
                radius: 0
                color: parent.focused ? Theme.pink : parent.occupied ? Theme.dim : Theme.border

                Behavior on width {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({workspace=" + parent.wsId + "})")
            }
        }
    }
}
