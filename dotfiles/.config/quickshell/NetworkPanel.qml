import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "widgets"
import "widgets/network"

// Host window for serpantinum's Wi-Fi/Bluetooth panel (widgets/network/
// NetworkPopup.qml, AGPL-3.0 — see widgets/README.md). The popup is a bare Item
// with no size of its own; upstream's WindowRegistry gives it 720x600 and pins
// it to the bar's end of the screen, which is what this reproduces.
// Toggle with:  qs ipc call wifi toggle
// The island opens it top-centre instead:  qs ipc call wifi wifiIsland
PanelWindow {
    id: win
    property bool open: false
    property bool atTop: false   // opened from the island: drop in top-centre like its panels
    readonly property int panelW: 720
    readonly property int panelH: 600

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wifi"
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
        target: "wifi"
        function toggle(): void { if (!win.open) win.atTop = false; win.open = !win.open; }
        function wifi(): void { win.atTop = false; win.openWith("wifi"); }
        function bt(): void { win.atTop = false; win.openWith("bt"); }
        function wifiIsland(): void { win.atTop = true; win.openWith("wifi"); }
        function btIsland(): void { win.atTop = true; win.openWith("bt"); }
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
            // top-right corner, or a top-centre notch like the island's when opened
            // from it; how much screen it may take is
            // ~/.config/mr5obot/settings.json -> network.screenFraction
            anchors.right: win.atTop ? undefined : parent.right
            anchors.horizontalCenter: win.atTop ? parent.horizontalCenter : undefined
            anchors.top: parent.top
            anchors.rightMargin: 12
            anchors.topMargin: win.atTop ? 0 : 12
            readonly property real fraction: Config.rawSettings.network?.screenFraction ?? 0.62
            readonly property real f: Math.min(1, win.width * fraction / win.panelW, win.height * fraction / win.panelH)
            width: win.panelW * f
            height: win.panelH * f

            // the notch slides out of the screen edge as it opens
            transform: Translate {
                y: win.atTop && !win.open ? -holder.height : 0
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            // stays below the popup, or it swallows the panel's own clicks
            MouseArea { anchors.fill: parent }

            NetworkOrbit {
                id: popup
                visible: win.open
                width: win.panelW
                height: win.panelH
                transformOrigin: Item.TopLeft
                scale: holder.f
                notch: win.atTop
                notchColor: Theme.notchBg
                notchRadius: Theme.notchRadius / holder.f   // popup is scaled by f

                /**
                 * Back to the island's Home surface, in the same spot and shape as
                 * the chevron the island's own surfaces carry. Only when the island
                 * opened this panel — the corner placement has no Home behind it.
                 * Reached the way Pill.qml reaches this panel: a detached
                 * `qs ipc call`, with the shell's own config env stripped.
                 */
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 9
                    width: 16
                    height: 16
                    visible: win.atTop && win.open
                    z: 10

                    Icon {
                        anchors.centerIn: parent
                        text: "home"
                        size: 16
                        filled: false
                        color: backArea.containsMouse ? Theme.text : Theme.dim
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    MouseArea {
                        id: backArea
                        anchors.fill: parent
                        anchors.margins: -7
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            win.open = false;
                            Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
                                "qs", "ipc", "call", "island", "home", ""]);
                        }
                    }
                }
            }

            NotchEars {
                anchors.top: parent.top
                width: parent.width
                visible: win.atTop
            }
        }
    }
}
