pragma Singleton
import QtQuick
import "../../../island/Singletons" as Island

// DotRobot replacement for serpantinum's ThemeBackend. Upstream builds the
// palette with matugen; here it reads island's shared palette. Slot names stay
// serpantinum's Catppuccin-style ones so the vendored modules bind unchanged:
// the neutrals carry a little of the wallpaper's hue, "mauve" is the primary.
Item {
    id: root

    property string fontFamily: "Adwaita Mono"
    property int borderRadius: 8

    readonly property color swatch: Island.Dyn.primary
    readonly property real hue: swatch.hslHue
    readonly property real sat: Math.min(Math.max(swatch.hslSaturation, 0.35), 0.75)
    function tone(s, l) { return Qt.hsla(root.hue, s, l, 1); }

    property color crust: tone(sat * 0.35, 0.045)
    property color base: tone(sat * 0.35, 0.085)
    property color surface0: tone(sat * 0.30, 0.14)
    property color surface1: tone(sat * 0.25, 0.20)
    property color surface2: tone(sat * 0.22, 0.26)
    property color overlay1: tone(sat * 0.15, 0.48)
    property color subtext0: tone(sat * 0.15, 0.72)
    property color text: tone(sat * 0.20, 0.90)
    property color mauve: tone(swatch ? sat : 0.45, 0.74)
}
