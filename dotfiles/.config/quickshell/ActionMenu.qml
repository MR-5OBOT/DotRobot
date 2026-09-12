import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "widgets"

// Fixed-action menu (power, session actions, …) as a labelled card that drops
// in from the top edge — the same shape, palette and rows as PowerProfileMenu,
// both drawn to match serpantinum's Wi-Fi/Bluetooth panel (see MenuRow.qml).
// Keyboard + click nav. Toggle: qs ipc call <ipcTarget> toggle
PanelWindow {
    id: win

    property string ipcTarget: ""
    property string title: ""
    property string titleIcon: ""
    property var actions: []          // [{ icon, label, cmd: [...] }]
    property bool open: false
    property int sel: 0

    onOpenChanged: sel = 0

    function move(d) {
        if (actions.length === 0)
            return;
        sel = (sel + d + actions.length) % actions.length;
    }

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
        width: 260
        height: col.implicitHeight + 16
        radius: ThemeBackend.borderRadius
        color: ThemeBackend.base
        border.color: ThemeBackend.surface0
        border.width: 1

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // swallow clicks on the card

        Item {  // key sink — no text input in this menu
            focus: true
            Keys.onEscapePressed: win.open = false
            Keys.onReturnPressed: win.run()
            Keys.onEnterPressed: win.run()
            Keys.onDownPressed: win.move(1)
            Keys.onUpPressed: win.move(-1)
            Keys.onTabPressed: win.move(1)
            Keys.onBacktabPressed: win.move(-1)
            Keys.onPressed: e => {
                if (e.key === Qt.Key_J)
                    win.move(1);
                else if (e.key === Qt.Key_K)
                    win.move(-1);
            }
        }

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 4

            RowLayout {  // header
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 2
                spacing: 8
                Icon { text: win.titleIcon; size: 14; color: ThemeBackend.overlay1 }
                Text {
                    Layout.fillWidth: true
                    text: win.title
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: 11
                    color: ThemeBackend.overlay1
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.bottomMargin: 4; color: ThemeBackend.surface0 }

            Repeater {
                model: win.actions
                delegate: MenuRow {
                    id: row
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight

                    icon: modelData.icon
                    label: modelData.label
                    selected: index === win.sel
                    onHoveredChanged: if (hovered) win.sel = row.index
                    onClicked: { win.sel = row.index; win.run(); }
                }
            }
        }
    }
}
