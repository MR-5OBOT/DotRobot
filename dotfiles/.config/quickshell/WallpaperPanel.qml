import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "widgets" as Widgets
import "widgets/wallpaper"
import "island/Singletons" as Island

// Host for serpantinum's wallpaper picker (widgets/wallpaper/WallpaperPicker.qml,
// AGPL-3.0 — see widgets/README.md). Upstream registers it full width, 650 tall,
// anchored centre-left, and pairs it with its own WallpaperEngine that paints
// the wallpaper. That engine is not vendored: the picker asks its Wallpaper
// singleton to apply; this bridges that signal to island's wallpaper backend.
// serp is imported under a namespace because its state singleton is also
// called Wallpaper, which would clash with this shell's Wallpaper.qml.
// Here it hangs from the top edge like the island's panels, on a transparent background.
// Toggle with:  qs ipc call wallpicker toggle
PanelWindow {
    id: win
    property bool open: false
    readonly property int panelH: 650

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpicker"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: "wallpicker"
        function toggle(): void { win.open = !win.open; }
    }

    // The picker holds ~100MB of delegates and decoded previews. With the
    // island's memory saver on it is built on open and dropped a minute after
    // close; a cold open then decodes its previews again (~2s of blank cards).
    onOpenChanged: if (!open) keepAlive.restart()
    Timer { id: keepAlive; interval: 60000 }

    Connections {
        target: Widgets.Wallpaper
        function onWallpaperChanged(screenName, path, transition) {
            if (path && path.length > 0)
                Island.Walls.apply(path, screenName);
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
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            // the strip takes about half the screen height; the picker is scaled to fit
            readonly property real f: Math.min(1, win.height * 0.55 / win.panelH)
            width: win.width - 48
            height: win.panelH * f

            // slides out of the screen edge as it opens
            transform: Translate {
                y: win.open ? 0 : -holder.height
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }

            // below the picker, or it swallows the carousel's clicks
            MouseArea { anchors.fill: parent }

            Item {
                anchors.fill: parent
                clip: true   // keep the carousel inside its strip

                Loader {
                    active: win.open || keepAlive.running || !Island.Flags.memorySaver
                    sourceComponent: WallpaperCarousel {
                        visible: win.open
                        hostScreen: win.screen
                        width: holder.width / holder.f
                        height: win.panelH
                        transformOrigin: Item.TopLeft
                        scale: holder.f
                    }
                }
            }
        }
    }
}
