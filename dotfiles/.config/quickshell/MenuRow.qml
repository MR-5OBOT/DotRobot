import QtQuick
import QtQuick.Layouts
import "widgets"

// One row of a drop-in menu card, drawn the way serpantinum's Wi-Fi/Bluetooth
// panel draws its list cards (widgets/reusables/FillButton.qml): the panel's own
// corner radius and palette, surface0 under the pointer, the accent when
// selected, and the accent bleeding out behind the row as a soft glow.
// Shared by ActionMenu and PowerProfileMenu so the two stay identical.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property string tag: ""            // right-aligned note, e.g. "active"
    property bool selected: false
    property color accent: ThemeBackend.mauve

    readonly property alias hovered: ma.containsMouse
    readonly property color fg: selected ? ThemeBackend.crust : ThemeBackend.text

    signal clicked()

    implicitHeight: 38

    Rectangle {   // glow behind the selected row
        anchors.fill: parent
        anchors.margins: -2
        radius: ThemeBackend.borderRadius + 2
        color: root.accent
        opacity: root.selected ? 0.18 : 0
        z: -1
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        anchors.fill: parent
        radius: ThemeBackend.borderRadius
        color: root.selected ? root.accent : (ma.containsMouse ? ThemeBackend.surface0 : "transparent")
        Behavior on color { ColorAnimation { duration: 180 } }

        scale: ma.pressed ? 0.985 : (root.selected || ma.containsMouse ? 1.015 : 1.0)
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

        RowLayout {
            anchors { left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 10

            Icon { text: root.icon; size: 17; color: root.fg }

            Text {
                Layout.fillWidth: true
                text: root.label
                font.family: ThemeBackend.fontFamily
                font.weight: Font.Bold
                font.pixelSize: 12
                color: root.fg
                elide: Text.ElideRight
            }

            Text {
                visible: text !== ""
                text: root.tag
                font.family: ThemeBackend.fontFamily
                font.pixelSize: 11
                color: root.selected ? ThemeBackend.crust : ThemeBackend.overlay1
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
