import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "island/Singletons" as Island
import "island/surfaces"

PanelWindow {
    id: win

    property bool open: false
    readonly property real s: Island.Flags.uiScale

    function toggle(monitor) {
        const target = Quickshell.screens.find(s => s.name === monitor) || Island.Monitors.focusedScreen;
        if (open && screen === target) {
            open = false;
            return;
        }
        screen = target;
        open = true;
    }

    visible: open || panel.opacity > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    mask: BarState.widgetMask
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open) {
        content.forceActiveFocus();
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { win.toggle(""); }
        function hide(): void { win.open = false; }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win].concat(BarState.islandWindows)
        onCleared: win.open = false
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (win.open && !Quickshell.screens.includes(win.screen)) win.open = false;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.open = false

        MouseArea {
            anchors.fill: parent
            enabled: win.open
            onPressed: win.open = false
        }

        Rectangle {
            id: panel
            x: win.width - width - 16 * win.s
            y: 16 * win.s
            width: Math.min(360 * win.s, win.width - 24 * win.s)
            height: win.height - 32 * win.s
            color: Island.Theme.light ? "#f6f2ec" : "#0b0c10"
            border.width: 1
            border.color: Island.Theme.frameBorder
            opacity: win.open ? 1 : 0
            transform: Translate {
                x: win.open ? 0 : panel.width + 24 * win.s
                Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            }
            Behavior on opacity { NumberAnimation { duration: 180 } }

            MouseArea { anchors.fill: parent }

            Link {
                anchors.fill: parent
                anchors.margins: 20 * win.s
                s: win.s
                open: win.open
                onRequestClose: win.open = false
            }
        }
    }
}
