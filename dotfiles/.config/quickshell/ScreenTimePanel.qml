import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "widgets" as Widgets
import "widgets/guide/wellbeing"

// Host for serpantinum's digital wellbeing tab (widgets/wellbeing/
// DigitalWellbeingTab.qml, AGPL-3.0 — see widgets/README.md). Upstream shows it as
// one tab inside its GuidePopup and the tab reaches back into that popup for a
// scaling helper, the cache/state paths and the visible tab index; the QtObject
// below stands in for it. The numbers come from focus_daemon.py, which tracks
// the focused window into a SQLite db and is started from hypr autostart.
// Toggle with:  qs ipc call screentime toggle
PanelWindow {
    id: win
    property bool open: false

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screentime"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: "screentime"
        function toggle(): void { win.open = !win.open; }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: win.open = false
    }

    // stands in for upstream's GuidePopup
    QtObject {
        id: guide
        function s(v) { return Math.round(v); }
        readonly property var appPaths: Widgets.Caching
        readonly property int currentTab: 0
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.open = false

        MouseArea {   // click outside closes
            anchors.fill: parent
            onClicked: win.open = false
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            readonly property real fraction: Widgets.Config.rawSettings.wellbeing?.screenFraction ?? 0.66
            width: Math.min(900, win.width * fraction)
            height: Math.min(520, win.height * fraction)
            color: Widgets.ThemeBackend.base
            radius: Widgets.ThemeBackend.borderRadius
            clip: true

            // stays below the tab, or it eats the tab's own clicks
            MouseArea { anchors.fill: parent }

            ScreenTimeTab {
                anchors.fill: parent
                rootObj: guide
                tabIndex: 0
            }
        }
    }
}
