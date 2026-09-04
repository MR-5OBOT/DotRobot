import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Fixed-action drop-in menu (power, session actions, …). Same top-center card as the
// launcher; keyboard + click nav. Toggle: qs ipc call <ipcTarget> toggle
PanelWindow {
    id: win

    property string ipcTarget: ""
    property string title: ""
    property string titleIcon: ""
    property int cardWidth: 220
    property var actions: []          // [{ icon, label, cmd: [...] }]
    property bool open: false
    property int sel: 0

    onOpenChanged: sel = 0

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

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: win.open ? 8 : -height   // drops in from the top edge
        width: win.cardWidth
        height: col.implicitHeight + 2
        color: Theme.bg

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // swallow clicks on the card

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
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
            spacing: 0

            RowLayout {  // header
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                spacing: 10
                Icon { text: win.titleIcon; size: 16; color: Theme.dim }
                Text {
                    Layout.fillWidth: true
                    text: win.title
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: Theme.dim
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            Repeater {
                model: win.actions
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: index === win.sel

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    color: current ? Theme.pink : (hover.hovered ? Theme.surface : "transparent")

                    RowLayout {
                        anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        spacing: 12
                        Icon { text: row.modelData.icon; size: 17; color: row.current ? "#ffffff" : Theme.text }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.label
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: row.current
                            color: row.current ? "#ffffff" : Theme.text
                        }
                    }

                    HoverHandler { id: hover }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { win.sel = row.index; win.run(); }
                    }
                }
            }
        }
    }
}
