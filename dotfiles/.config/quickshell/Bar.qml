import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Auto-hiding vertical panel on the left. Normally collapsed to a thin peek
// strip (near-fullscreen); hovering the edge slides the full bar out over the
// window. Stays out while a popup is open (BarState.revealed).
PanelWindow {
    id: bar
    required property var screen

    property int peek: 6  // invisible hover-trigger width (nothing is drawn here)

    anchors { top: true; bottom: true; left: true }
    implicitWidth: Theme.barWidth
    exclusiveZone: 0                 // windows keep the full screen
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top

    // input region: invisible peek strip at the edge when hidden, full bar shown.
    // The bar draws nothing when collapsed (content is fully off-screen), so this
    // strip is an invisible hover trigger.
    mask: Region {
        x: 0
        y: 0
        width: BarState.revealed ? bar.width : bar.peek
        height: bar.height
    }

    // hover detection spans the window but input is limited by the mask above
    HoverHandler {
        onHoveredChanged: BarState.hovered = hovered
    }

    Rectangle {
        id: content
        width: Theme.barWidth
        height: parent.height
        color: Theme.bg

        // slide fully off when hidden -> nothing visible until hovered
        x: BarState.revealed ? 0 : -Theme.barWidth
        Behavior on x {
            NumberAnimation {
                duration: 300
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]  // M3 emphasized decel
            }
        }

        // settled only when fully out and at rest — popups gate on this
        onXChanged: BarState.settled = BarState.revealed && x === 0
        Connections {
            target: BarState
            function onRevealedChanged() {
                if (!BarState.revealed)
                    BarState.settled = false;
            }
        }

        // grouped "child frame": raised surface, square corners, matching vibe
        component Frame: Rectangle {
            color: Theme.surface
            border.width: 1
            border.color: Theme.border
            radius: Theme.radius   // 0
            implicitWidth: 34
        }

        Frame {  // launcher
            id: appsFrame
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: 34
            height: 34
            Icon {
                id: appsBtn
                anchors.centerIn: parent
                text: "apps"
                size: 18
                color: appsMA.containsMouse ? Theme.pink : Theme.dim
                Behavior on color { ColorAnimation { duration: 120 } }
                MouseArea {
                    id: appsMA
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    onClicked: BarState.launcherOpen = !BarState.launcherOpen
                }
            }
        }

        Frame {  // time + calendar
            id: clockFrame
            anchors.top: appsFrame.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: 34
            height: clock.implicitHeight + 12
            Clock {
                id: clock
                anchors.centerIn: parent
                width: parent.width
            }
        }

        Frame {  // workspaces
            anchors.centerIn: parent
            width: 34
            height: wsInner.implicitHeight + 14
            Workspaces {
                id: wsInner
                anchors.centerIn: parent
                width: parent.width
            }
        }

        ColumnLayout {
            id: statusCol
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Frame {  // system tray, only when it has icons
                Layout.alignment: Qt.AlignHCenter
                visible: tray.children.length > 0
                implicitHeight: tray.implicitHeight + 14
                Tray {
                    id: tray
                    anchors.centerIn: parent
                }
            }

            Frame {  // media + system status
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: sysCol.implicitHeight + 14
                ColumnLayout {
                    id: sysCol
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 8

                    Media { Layout.fillWidth: true }
                    Bluetooth { Layout.fillWidth: true }
                    Network { Layout.fillWidth: true }
                    Volume { Layout.fillWidth: true }
                    Battery { Layout.fillWidth: true }
                }
            }
        }
    }
}
