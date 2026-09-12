import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Fixed-action menu (power, session actions, …) as an icon strip that slides in
// from the right edge. Icon-only, so the label rides along as a hover tooltip.
// Keyboard + click nav. Toggle: qs ipc call <ipcTarget> toggle
PanelWindow {
    id: win

    property string ipcTarget: ""
    property string title: ""         // kept for callers; the strip has no header
    property string titleIcon: ""
    property int buttonSize: 46
    property var actions: []          // [{ icon, label, cmd: [...] }]
    property bool open: false
    property int sel: 0
    property int hoverIdx: -1

    onOpenChanged: { sel = 0; hoverIdx = -1; }

    function run() {
        const a = actions[sel];
        if (a) {
            Quickshell.execDetached(a.cmd);
            open = false;
        }
    }

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-" + ipcTarget
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: win.ipcTarget
        function toggle(): void { win.open = !win.open; }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: win.open = false
    }

    MouseArea { anchors.fill: parent; onClicked: win.open = false }  // click-outside

    // label for whichever button is hovered, parked to the left of the strip
    Rectangle {
        id: tip
        visible: win.hoverIdx >= 0 && win.hoverIdx < win.actions.length && card.opacity > 0.5
        anchors.right: card.left
        anchors.rightMargin: 8
        y: card.y + col.y + win.hoverIdx * (win.buttonSize + col.spacing) + (win.buttonSize - height) / 2
        width: tipText.implicitWidth + 20
        height: 28
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        radius: Theme.radius

        Text {
            id: tipText
            anchors.centerIn: parent
            text: win.hoverIdx >= 0 && win.hoverIdx < win.actions.length ? win.actions[win.hoverIdx].label : ""
            font.family: Theme.font
            font.pixelSize: 12
            color: Theme.text
        }
    }

    Rectangle {
        id: card
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: win.open ? 8 : -width   // slides in from the right edge
        width: win.buttonSize + 12
        height: col.implicitHeight + 12
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        radius: Theme.radius

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // swallow clicks on the strip

        Item {  // key sink — no text input in this menu
            focus: true
            Keys.onEscapePressed: win.open = false
            Keys.onReturnPressed: win.run()
            Keys.onEnterPressed: win.run()
            Keys.onDownPressed: win.sel = (win.sel + 1) % Math.max(1, win.actions.length)
            Keys.onUpPressed: win.sel = (win.sel - 1 + win.actions.length) % Math.max(1, win.actions.length)
            Keys.onTabPressed: win.sel = (win.sel + 1) % Math.max(1, win.actions.length)
            Keys.onBacktabPressed: win.sel = (win.sel - 1 + win.actions.length) % Math.max(1, win.actions.length)
        }

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: win.actions
                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool current: index === win.sel

                    Layout.preferredWidth: win.buttonSize
                    Layout.preferredHeight: win.buttonSize
                    radius: Theme.radius
                    color: current ? Theme.pink : (hover.hovered ? Theme.surface : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Icon {
                        anchors.centerIn: parent
                        text: btn.modelData.icon
                        size: 22
                        color: btn.current ? "#ffffff" : Theme.text
                    }

                    HoverHandler {
                        id: hover
                        onHoveredChanged: {
                            if (hovered) {
                                win.hoverIdx = btn.index;
                                win.sel = btn.index;
                            } else if (win.hoverIdx === btn.index) {
                                win.hoverIdx = -1;
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { win.sel = btn.index; win.run(); }
                    }
                }
            }
        }
    }
}
