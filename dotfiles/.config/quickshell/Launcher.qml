import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

// Spotlight-style launcher: starts as a bare input row near the top; typing
// lists matches (6 visible, scrollable). Toggle: qs ipc call launcher toggle
PanelWindow {
    id: win

    // state lives in BarState so the bar's apps button can toggle it too
    readonly property bool open: BarState.launcherOpen
    property string query: ""
    property int sel: 0
    onSelChanged: list.positionViewAtIndex(sel, ListView.Contain)

    onOpenChanged: {
        query = "";
        sel = 0;
        input.text = "";
    }

    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var matches: {
        const q = query.toLowerCase().trim();
        if (!q)
            return [];  // spotlight: empty query shows nothing
        const starts = [], incl = [];
        for (const a of apps) {
            const n = a.name.toLowerCase();
            if (n.startsWith(q))
                starts.push(a);
            else if (n.includes(q))
                incl.push(a);
        }
        return [...starts, ...incl];
    }

    function launch() {
        const app = matches[sel];
        if (app) {
            app.execute();
            BarState.launcherOpen = false;
        }
    }

    visible: open || card.opacity > 0.01
    // fullscreen transparent overlay: any click outside the card closes it
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0   // float over windows, don't reserve space (kitty was shrinking)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            BarState.launcherOpen = !BarState.launcherOpen;
        }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: BarState.launcherOpen = false
    }

    MouseArea {  // click-outside catcher
        anchors.fill: parent
        onClicked: BarState.launcherOpen = false
    }

    Rectangle {
        id: card
        // top-center, drops in from the top edge (matches the workspace island)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: win.open ? 8 : -height
        width: 270
        height: col.implicitHeight + 2
        color: Theme.bg

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // swallow clicks on the card itself

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
            spacing: 0

            RowLayout {  // prompt
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                TextInput {
                    id: input
                    Layout.fillWidth: true
                    focus: true
                    font.family: Theme.font
                    font.pixelSize: 14
                    color: Theme.text
                    clip: true

                    Text {  // placeholder
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text.length === 0
                        text: "Search apps"
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: Theme.dim
                    }
                    onTextChanged: {
                        win.query = text;
                        win.sel = 0;
                    }
                    Keys.onEscapePressed: BarState.launcherOpen = false
                    Keys.onReturnPressed: win.launch()
                    Keys.onEnterPressed: win.launch()
                    Keys.onDownPressed: win.sel = Math.min(win.sel + 1, win.matches.length - 1)
                    Keys.onUpPressed: win.sel = Math.max(win.sel - 1, 0)
                    Keys.onTabPressed: win.sel = (win.sel + 1) % Math.max(1, win.matches.length)
                    Keys.onBacktabPressed: win.sel = (win.sel - 1 + win.matches.length) % Math.max(1, win.matches.length)
                }
            }

            Rectangle {  // separator, only when results show
                Layout.fillWidth: true
                visible: win.matches.length > 0
                height: 1
                color: Theme.border
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(win.matches.length, 6) * 34
                visible: win.matches.length > 0
                clip: true
                model: win.matches

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: index === win.sel

                    width: list.width
                    height: 34
                    color: current ? Theme.pink : (rowHover.hovered ? Theme.surface : "transparent")

                    RowLayout {
                        anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        spacing: 10

                        IconImage {
                            implicitSize: 20
                            source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            elide: Text.ElideRight
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: row.current
                            color: row.current ? "#ffffff" : Theme.text
                        }
                    }

                    HoverHandler { id: rowHover }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            win.sel = row.index;
                            win.launch();
                        }
                    }
                }
            }
        }
    }
}
