import QtQuick
import Quickshell
import Quickshell.Wayland

// Fullscreen "go sleep" nag between 01:00 and 06:00. Click anywhere to
// snooze it; it comes back every 20 minutes until you actually sleep.
PanelWindow {
    id: nag

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property bool lateNight: clock.date.getHours() >= 1 && clock.date.getHours() < 6
    property bool dismissed: false
    onLateNightChanged: if (!lateNight) dismissed = false

    Timer {
        id: snooze
        interval: 20 * 60 * 1000
        running: nag.dismissed && nag.lateNight
        onTriggered: nag.dismissed = false
    }

    visible: lateNight && !dismissed
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "#e6000000"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-gosleep"

    Column {
        anchors.centerIn: parent
        spacing: 18

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "go-sleep.png"
            width: nag.width * 0.9
            height: nag.height * 0.8   // leave room for the caption
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "no wife! still waking? oh so its money okay... but go sleep"
            font.family: Theme.font
            font.pixelSize: 22
            font.bold: true
            color: Theme.pink
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: nag.dismissed = true
    }
}
