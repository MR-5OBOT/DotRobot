import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Transient top-center "island" that drops in when the focused workspace
// changes, shows the same square pips as the bar (horizontal), then hides.
// Overlay layer + empty input mask so it floats over fullscreen and never
// eats a click.
PanelWindow {
    id: osd

    property bool shown: false
    readonly property var wss: Hyprland.workspaces.values
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int count: Math.max(5, ...wss.map(w => w.id), 5)

    // suppress the reveal that fires when the binding first evaluates on launch
    property bool ready: false
    Timer { running: true; interval: 400; onTriggered: osd.ready = true }

    onFocusedIdChanged: if (ready) { shown = true; hideTimer.restart(); }
    Timer { id: hideTimer; interval: 900; onTriggered: osd.shown = false }

    anchors.top: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-ws-osd"
    mask: Region {}   // fully click-through

    // stay mapped through the fade-out
    visible: shown || island.opacity > 0.01
    implicitWidth: island.implicitWidth
    implicitHeight: island.implicitHeight + 8

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: osd.shown ? 4 : -implicitHeight   // drops from the top edge
        implicitWidth: pips.implicitWidth + 24
        implicitHeight: pips.implicitHeight + 12

        color: Theme.bg
        radius: Theme.radius   // 0

        opacity: osd.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        RowLayout {
            id: pips
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: osd.count
                delegate: Item {
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool occupied: osd.wss.some(w => w.id === wsId)
                    readonly property bool focused: osd.focusedId === wsId

                    implicitWidth: 22
                    implicitHeight: 22

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.focused ? 16 : parent.occupied ? 11 : 6
                        height: width
                        radius: 0
                        color: parent.focused ? Theme.pink : parent.occupied ? Theme.dim : Theme.border
                        Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
