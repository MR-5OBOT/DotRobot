import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "serp" as Serp
import "serp/wallpaper"

// Host for serpantinum's wallpaper picker (serp/wallpaper/WallpaperPicker.qml,
// AGPL-3.0 — see serp/README.md). Upstream registers it full width, 650 tall,
// anchored centre-left, and pairs it with its own WallpaperEngine that paints
// the wallpaper. That engine is not vendored: the picker asks its Wallpaper
// singleton to apply, and this bridges that signal to WallpaperState, so the
// shell's own Wallpaper.qml keeps painting and DesktopClock and the vendored
// ThemeBackend keep reading the same state file.
// serp is imported under a namespace because its state singleton is also
// called Wallpaper, which would clash with this shell's Wallpaper.qml.
// Toggle with:  qs ipc call serpwallpaper toggle
PanelWindow {
    id: win
    property bool open: false
    readonly property int panelH: 650

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-serpwallpaper"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: "serpwallpaper"
        function toggle(): void { win.open = !win.open; }
    }

    Connections {
        target: Serp.Wallpaper
        function onWallpaperChanged(screenName, path, transition) {
            if (path && path.length > 0)
                WallpaperState.apply(path);
        }
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

        MouseArea {   // click outside the strip closes it
            anchors.fill: parent
            onClicked: win.open = false
        }

        Item {
            id: holder
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            readonly property real f: Math.min(1, (win.height - 40) / win.panelH)
            width: win.width
            height: win.panelH * f

            // below the picker, or it swallows the carousel's clicks
            MouseArea { anchors.fill: parent }

            SerpWallpaperPicker {
                id: picker
                visible: win.open
                hostScreen: win.screen
                width: win.width / holder.f
                height: win.panelH
                transformOrigin: Item.TopLeft
                scale: holder.f
            }
        }
    }
}
