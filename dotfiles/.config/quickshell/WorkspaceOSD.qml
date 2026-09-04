import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Transient top-center "island" that drops in when the focused workspace
// changes, shows square pips (horizontal), then hides. Also hover-revealable:
// an invisible strip at the top-center edge brings it in for a look or a
// click (pips switch workspace). Overlay layer; input limited to the strip
// and the island itself, everything else stays click-through.
PanelWindow {
    id: osd

    property bool shown: false
    property int peekH: 8   // invisible hover-trigger strip height at the top edge
    readonly property var wss: Hyprland.workspaces.values
    readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int count: Math.max(5, ...wss.map(w => w.id), 5)

    // suppress the reveal that fires when the binding first evaluates on launch
    property bool ready: false
    Timer { running: true; interval: 400; onTriggered: osd.ready = true }

    onFocusedIdChanged: if (ready) { shown = true; hideTimer.restart(); }
    Timer { id: hideTimer; interval: 900; onTriggered: if (!hh.hovered) osd.shown = false }

    anchors.top: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-ws-osd"

    // input region: hover strip at the top edge + the island while on-screen
    mask: Region {
        x: 0
        y: 0
        width: osd.width
        height: osd.peekH
        Region {
            x: island.x
            y: island.y
            width: island.width
            height: island.height
        }
    }

    // hovering the strip reveals (after a small dwell) and pins it open;
    // leaving hides it. Workspace switches still auto-show via hideTimer.
    HoverHandler {
        id: hh
        onHoveredChanged: {
            if (hovered) {
                dwell.restart();
                hideTimer.stop();
            } else {
                dwell.stop();
                osd.shown = false;
            }
        }
    }
    Timer { id: dwell; interval: 180; onTriggered: osd.shown = true }

    // always mapped so the hover strip works while hidden
    visible: true
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

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Hyprland.dispatch("hl.dsp.focus({workspace=" + parent.wsId + "})")
                    }
                }
            }
        }
    }
}
