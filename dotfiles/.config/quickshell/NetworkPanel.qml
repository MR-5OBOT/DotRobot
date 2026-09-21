import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "widgets"
import "widgets/network"

// Host window for serpantinum's Wi-Fi/Ethernet panel (widgets/network/
// NetworkPopup.qml, AGPL-3.0 — see widgets/README.md). The popup is a bare Item
// with no size of its own; upstream's WindowRegistry gives it 720x600 and pins
// it to the bar's end of the screen, which is what this reproduces.
// Toggle with:  qs ipc call wifi toggle | wifiIsland
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
    WlrLayershell.namespace: "quickshell-wifi"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Clicking the button of the tab already showing closes it. The panel re-reads
    // its mode file every time it becomes visible, so that file — not the property
    // — decides the tab. Write it, then show; while the panel is already open it
    // watches the file, so this switches tabs too.
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
        function toggle(): void { win.open = !win.open; }
        function wifiIsland(): void { win.openWith("wifi"); }
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
            // Hard-locked top-centre, the one place every panel in this shell opens.
            // (It used to swap anchors.right/horizontalCenter per placement; toggling
            // an anchor to undefined left the panel pinned at the screen's left edge.)
            // How much screen it may take: ~/.config/mr5obot/settings.json -> network.screenFraction
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            readonly property real fraction: Config.rawSettings.network?.screenFraction ?? 0.62
            readonly property real f: Math.min(1, win.width * fraction / win.panelW, win.height * fraction / win.panelH)
            width: win.panelW * f
            height: win.panelH * f

            // the notch slides out of the screen edge as it opens
            transform: Translate {
                y: win.open ? 0 : -holder.height
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
                notch: true
                notchColor: Theme.notchBg
                notchRadius: Theme.notchRadius / holder.f   // popup is scaled by f

                /**
                 * Back to the island's Home surface, in the same spot and shape as
                 * the chevron the island's own surfaces carry. Reached the way
                 * Pill.qml reaches this panel: a detached `qs ipc call`, with the
                 * shell's own config env stripped.
                 */
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 9
                    width: 16
                    height: 16
                    visible: win.open
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
            }
        }
    }
}
