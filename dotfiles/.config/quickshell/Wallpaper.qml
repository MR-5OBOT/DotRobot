import QtQuick
import Quickshell
import Quickshell.Wayland

// Native wallpaper: one background-layer window per screen, draws
// WallpaperState.path. Replaces awww-daemon. Background layer = sits under all
// normal windows and reserves no space (exclusiveZone 0).
PanelWindow {
    required property var modelData
    screen: modelData

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper-bg"
    exclusiveZone: 0
    color: "black"   // shown during decode and on any letterbox edge
    anchors { top: true; bottom: true; left: true; right: true }

    Image {
        anchors.fill: parent
        source: WallpaperState.path.length ? "file://" + WallpaperState.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        // decode at screen size, not full image res — keeps VRAM sane
        sourceSize.width: modelData.width
        sourceSize.height: modelData.height
    }
}
