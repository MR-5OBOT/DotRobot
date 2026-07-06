import QtQuick
import QtQuick.Layouts

// Month grid with prev/next navigation. `now` drives the today highlight,
// `monthOffset` is the viewed month relative to the current one.
ColumnLayout {
    id: root
    required property var now
    property int monthOffset: 0

    readonly property var shown: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)
    readonly property int year: shown.getFullYear()
    readonly property int month: shown.getMonth()
    readonly property int today: now.getDate()
    readonly property bool currentMonth: monthOffset === 0

    spacing: 10

    // 0 = leading blank, 1..N = day number
    readonly property var cells: {
        const first = new Date(year, month, 1).getDay();
        const days = new Date(year, month + 1, 0).getDate();
        const a = [];
        for (let i = 0; i < first; i++)
            a.push(0);
        for (let d = 1; d <= days; d++)
            a.push(d);
        return a;
    }

    RowLayout {
        // month label left, nav chevrons grouped right (date-picker pattern);
        // row width == grid width so the edges align.
        Layout.preferredWidth: grid.width
        Layout.alignment: Qt.AlignHCenter

        Text {
            Layout.fillWidth: true
            text: Qt.formatDate(root.shown, "MMMM yyyy")
            font.family: Theme.font
            font.pixelSize: 13
            font.bold: true
            color: Theme.pink
            // click the title to jump back to the current month
            MouseArea {
                anchors.fill: parent
                visible: !root.currentMonth
                onClicked: root.monthOffset = 0
            }
        }

        Rectangle {  // prev month
            implicitWidth: 22
            implicitHeight: 22
            color: prevHover.hovered ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Icon {
                anchors.centerIn: parent
                text: "chevron_left"
                size: 16
                color: prevHover.hovered ? Theme.pink : Theme.dim
            }
            HoverHandler { id: prevHover }
            MouseArea {
                anchors.fill: parent
                onClicked: root.monthOffset--
            }
        }

        Rectangle {  // next month
            implicitWidth: 22
            implicitHeight: 22
            color: nextHover.hovered ? Theme.surface : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
            Icon {
                anchors.centerIn: parent
                text: "chevron_right"
                size: 16
                color: nextHover.hovered ? Theme.pink : Theme.dim
            }
            HoverHandler { id: nextHover }
            MouseArea {
                anchors.fill: parent
                onClicked: root.monthOffset++
            }
        }
    }

    Grid {
        id: grid
        Layout.alignment: Qt.AlignHCenter
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
            delegate: Text {
                required property string modelData
                width: 26
                height: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                font.family: Theme.font
                font.pixelSize: 11
                color: Theme.dim
            }
        }

        Repeater {
            model: root.cells
            delegate: Rectangle {
                required property int modelData
                width: 26
                height: 24
                radius: Theme.radius
                color: modelData === root.today && root.currentMonth ? Theme.pink : "transparent"

                Text {
                    anchors.centerIn: parent
                    visible: parent.modelData !== 0
                    text: parent.modelData
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: parent.modelData === root.today && root.currentMonth ? "#ffffff" : Theme.text
                }
            }
        }
    }
}
