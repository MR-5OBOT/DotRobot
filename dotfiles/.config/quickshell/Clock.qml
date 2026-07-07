import QtQuick
import QtQuick.Layouts
import Quickshell

// Bar: stacked HH / MM / ss + calendar icon. Click the icon -> month calendar popup.
Item {
    id: root
    implicitWidth: parent.width
    implicitHeight: col.implicitHeight + 12

    // the bar's content rect, so the calendar popout can match its height
    property Item barContent

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "HH")
            font.family: Theme.font
            font.pixelSize: 15
            font.bold: true
            color: Theme.text
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "mm")
            font.family: Theme.font
            font.pixelSize: 15
            color: Theme.pink
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            text: Qt.formatDateTime(clock.date, "ss")
            font.family: Theme.font
            font.pixelSize: 10
            color: Theme.dim
        }

        Icon {  // calendar below the time; hovering it shows the calendar popup
            id: calIcon
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            text: "calendar_month"
            size: 15
            color: pop.open ? Theme.pink : Theme.dim
            Behavior on color { ColorAnimation { duration: 120 } }
            HoverHandler {
                onHoveredChanged: pop.itemHovered = hovered
            }
        }
    }

    Popout {
        id: pop
        // top-align with the bar; fall back to the icon if unset
        anchorItem: root.barContent ? root.barContent : calIcon
        topAligned: root.barContent !== null
        contentComponent: Component {
            Calendar {
                now: clock.date
            }
        }
    }
}
