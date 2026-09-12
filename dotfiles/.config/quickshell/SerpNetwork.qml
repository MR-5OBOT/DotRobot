import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "serp"
import "serp/network"

// Host window for serpantinum's Wi-Fi/Bluetooth panel (serp/network/
// NetworkPopup.qml, AGPL-3.0 — see serp/README.md). The popup is a bare Item
// with no size of its own; upstream's WindowRegistry gives it 720x600 and pins
// it to the bar's end of the screen, which is what this reproduces.
// Toggle with:  qs ipc call serpnetwork toggle
PanelWindow {
    id: win
    property bool open: false
    readonly property int panelW: 720
    readonly property int panelH: 600

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-serpnetwork"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Open straight onto a tab: the bar's wifi and bluetooth buttons each want
    // their own side. Clicking the button of the tab already showing closes it.
    // The panel re-reads its mode file every time it becomes visible, so that
    // file — not the property — decides the tab. Write it, then show; while the
    // panel is already open it watches the file, so this switches tabs too.
    property string pendingMode: "wifi"
    function openWith(mode) {
        if (win.open && popup.activeMode === mode) {
            win.open = false;
            return;
        }
        win.pendingMode = mode;
        Quickshell.execDetached(["bash", "-c",
            "mkdir -p '" + popup.cacheDir + "' && printf '%s' '" + mode + "' > '" + popup.cacheDir + "/mode'"]);
        modeWriteTimer.restart();
    }

    Timer {
        id: modeWriteTimer
        interval: 150
        onTriggered: {
            popup.activeMode = win.pendingMode;
            win.open = true;
        }
    }

    IpcHandler {
        target: "serpnetwork"
        function toggle(): void { win.open = !win.open; }
        function wifi(): void { win.openWith("wifi"); }
        function bt(): void { win.openWith("bt"); }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: win.open = false
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.open = false

        MouseArea {   // click outside the panel closes it
            anchors.fill: parent
            onClicked: win.open = false
        }

        Item {
            id: holder
            // top-right corner; how much screen it may take is
            // serp/settings.json -> network.screenFraction
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 12
            anchors.topMargin: 12
            readonly property real fraction: Config.rawSettings.network?.screenFraction ?? 0.62
            readonly property real f: Math.min(1, win.width * fraction / win.panelW, win.height * fraction / win.panelH)
            width: win.panelW * f
            height: win.panelH * f

            // stays below the popup, or it swallows the panel's own clicks
            MouseArea { anchors.fill: parent }

            SerpNetworkPopup {
                id: popup
                visible: win.open
                width: win.panelW
                height: win.panelH
                transformOrigin: Item.TopLeft
                scale: holder.f
            }
        }
    }
}
