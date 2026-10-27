pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "widgets" as Widgets
import "island/Singletons" as Island
import "lib/workspaces.js" as Workspaces
import "island/components" as IslandUi

// Occupied workspaces across all monitors. Toggle: qs ipc call workspaces toggle.
PanelWindow {
    id: win

    property bool open: false
    property int selected: -1
    property int pendingWorkspace: -1
    readonly property var monitors: Island.Monitors.list
    readonly property var occupied: Workspaces.occupiedWorkspaces(
        Hyprland.toplevels.values.map(t => t.lastIpcObject))
    readonly property int columns: Math.max(1, Math.min(4, occupied.length))
    readonly property int rows: Math.max(1, Math.ceil(occupied.length / columns))
    readonly property color accent: Island.Theme.vermLit

    onOccupiedChanged: {
        if (occupied.indexOf(selected) === -1)
            selected = occupied.length ? occupied[0] : -1;
    }

    function refresh() {
        Hyprland.refreshToplevels();
        Island.Monitors.refresh();
    }

    function toggle() {
        if (!open && Island.Monitors.focusedScreen)
            screen = Island.Monitors.focusedScreen;
        open = !open;
    }

    function activate(index) {
        pendingWorkspace = index;
        win.open = false;
    }

    onBackingWindowVisibleChanged: {
        // Hiding the layer restores focus; switch only after that restoration.
        if (!backingWindowVisible && pendingWorkspace >= 0) {
            const target = pendingWorkspace;
            pendingWorkspace = -1;
            Qt.callLater(() => Hyprland.dispatch(Workspaces.focusRequest(target)));
        }
    }

    function step(direction) {
        if (occupied.length === 0) return;
        const current = Math.max(0, occupied.indexOf(selected));
        selected = occupied[Workspaces.move(current, direction, columns, occupied.length)];
    }

    function monitorFor(index, windows) {
        const rules = Island.Workspacerules.byMonitor;
        const ruledName = Object.keys(rules).find(name => rules[name].indexOf(index) !== -1);
        return monitors.find(m => windows.length > 0 && m.id === windows[0].lastIpcObject.monitor)
            || monitors.find(m => Workspaces.workspaceIndex(m.activeWorkspace) === index)
            || monitors.find(m => m.name === ruledName)
            || monitors.find(m => m.name === win.screen.name)
            || { x: 0, y: 0, width: win.width, height: win.height, scale: 1 };
    }

    onOpenChanged: {
        if (open) {
            pendingWorkspace = -1;
            const current = Workspaces.workspaceIndex(Island.Monitors.focused
                ? Island.Monitors.focused.activeWorkspace : null);
            selected = occupied.indexOf(current) !== -1 ? current : (occupied.length ? occupied[0] : -1);
            refresh();
            keys.forceActiveFocus();
        }
    }

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-workspaces"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "workspaces"
        function toggle(): void { win.toggle(); }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win].concat(BarState.islandWindows)
        onCleared: win.open = false
    }

    // Geometry changes do not always emit IPC events.
    Timer { interval: 750; repeat: true; running: win.open; onTriggered: Hyprland.refreshToplevels() }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onTabPressed: win.step(1)
        Keys.onBacktabPressed: win.step(-1)
        Keys.onLeftPressed: win.step(-1)
        Keys.onRightPressed: win.step(1)
        Keys.onUpPressed: win.step(-win.columns)
        Keys.onDownPressed: win.step(win.columns)
        Keys.onReturnPressed: win.activate(win.selected)
        Keys.onEnterPressed: win.activate(win.selected)
        Keys.onEscapePressed: win.open = false
        Keys.onReleased: event => {
            if (win.open && (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R)) {
                event.accepted = true;
                win.activate(win.selected);
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#80000000"
            opacity: card.opacity
            MouseArea { anchors.fill: parent; onClicked: win.open = false }
        }

        Rectangle {
            id: card
            readonly property real tileW: Math.floor(Math.min((win.width - 104) / win.columns,
                ((win.height - 154) / win.rows - 32) * 16 / 9, 280))
            width: Math.max(320, grid.width + 40)
            height: (win.occupied.length ? grid.height : 90) + 104
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: win.open ? 0 : -height
            bottomLeftRadius: Theme.notchRadius
            bottomRightRadius: Theme.notchRadius
            color: Theme.notchBg
            opacity: win.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent }
            IslandUi.NotchEars { width: parent.width }

            RowLayout {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                Text {
                    text: "Workspaces"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 16; bold: true }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: win.occupied.length + (win.occupied.length === 1 ? " workspace" : " workspaces")
                    color: Theme.dim
                    font { family: Theme.font; pixelSize: 12 }
                }
            }

            Grid {
                id: grid
                x: (parent.width - width) / 2
                y: 54
                columns: win.columns
                spacing: 12

                Repeater {
                    model: ScriptModel { values: win.occupied }
                    delegate: Rectangle {
                        id: tile
                        required property int modelData
                        readonly property bool selected: modelData === win.selected
                        readonly property var windows: Hyprland.toplevels.values.filter(t =>
                            Workspaces.containsWindow(t.lastIpcObject, tile.modelData))
                            .sort((a, b) => b.lastIpcObject.focusHistoryID - a.lastIpcObject.focusHistoryID)
                        readonly property var monitor: win.monitorFor(modelData, windows)
                        readonly property var geometry: Workspaces.monitorGeometry(monitor)
                        readonly property bool current: Workspaces.workspaceIndex(monitor.activeWorkspace) === modelData

                        width: card.tileW
                        height: width * 9 / 16 + 32
                        radius: 10
                        color: Theme.surface
                        border.width: selected ? 2 : 1
                        border.color: selected ? win.accent : (hover.hovered ? Theme.dim : Theme.border)
                        scale: selected ? 1.025 : 1
                        z: selected ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Accessible.role: Accessible.Button
                        Accessible.name: "Workspace " + modelData + ", " + windows.length + " windows" + (current ? ", active" : "")
                        Accessible.selected: selected
                        Accessible.onPressAction: win.activate(modelData)

                        Item {
                            id: preview
                            x: 6
                            y: 6
                            width: parent.width - 12
                            height: parent.height - 38
                            clip: true
                            readonly property real factor: Math.min(width / tile.geometry.width, height / tile.geometry.height)

                            Image {
                                anchors.fill: parent
                                readonly property string path: Widgets.Wallpaper.getWallpaperPath(tile.monitor.name || win.screen.name)
                                source: path ? "file://" + (/\.(mp4|webm|mkv|mov)$/i.test(path)
                                    ? Widgets.Wallpaper.stateDir + "/island-wallpaper-still.png" : path) : ""
                                sourceSize.width: Math.ceil(width * win.screen.devicePixelRatio)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                opacity: 0.5
                            }

                            Repeater {
                                model: win.open ? tile.windows : []
                                delegate: Rectangle {
                                    id: windowPreview
                                    required property var modelData
                                    readonly property var client: modelData.lastIpcObject
                                    x: (client.at[0] - tile.geometry.x) * preview.factor
                                        + (preview.width - tile.geometry.width * preview.factor) / 2
                                    y: (client.at[1] - tile.geometry.y) * preview.factor
                                        + (preview.height - tile.geometry.height * preview.factor) / 2
                                    width: client.size[0] * preview.factor
                                    height: client.size[1] * preview.factor
                                    z: client.floating ? 1 : 0
                                    color: Theme.ghost
                                    border { width: 1; color: Theme.faint }
                                    clip: true

                                    Text {
                                        anchors { fill: parent; margins: 6 }
                                        text: windowPreview.modelData.title || windowPreview.client.class
                                        textFormat: Text.PlainText
                                        color: Theme.text
                                        font { family: Theme.font; pixelSize: 10 }
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    ScreencopyView {
                                        anchors { fill: parent; margins: 1 }
                                        captureSource: windowPreview.modelData.wayland
                                        live: true
                                        paintCursor: false
                                    }
                                }
                            }

                        }

                        RowLayout {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10; bottomMargin: 8 }
                            spacing: 6
                            Rectangle { width: 5; height: 5; radius: 3; color: win.accent; visible: tile.current }
                            Text {
                                text: tile.modelData
                                color: tile.selected ? win.accent : Theme.text
                                font { family: Theme.font; pixelSize: 12; bold: true }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: tile.windows.length ? tile.windows.length + (tile.windows.length === 1 ? " window" : " windows") : ""
                                color: Theme.dim
                                font { family: Theme.font; pixelSize: 10 }
                            }
                        }

                        HoverHandler { id: hover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.activate(tile.modelData)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: win.occupied.length === 0
                text: "No occupied workspaces"
                color: Theme.dim
                font { family: Theme.font; pixelSize: 12 }
            }

            Text {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 16 }
                width: parent.width - 40
                text: "Hold Super · Tab / Shift+Tab / arrows · Release Super to switch · Esc to cancel"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.dim
                font { family: Theme.font; pixelSize: 10 }
            }
        }
    }
}
