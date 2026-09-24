pragma Singleton
import QtQuick
import "../../"
import "../../../island/Singletons" as Island

// DotRobot replacement for serpantinum's ThemeBackend. Upstream builds the
// palette with matugen; here it reads island's shared palette. Slot names stay
// serpantinum's Catppuccin-style ones so the vendored modules bind unchanged:
// the neutrals carry a little of the wallpaper's hue, "mauve" is the primary.
Item {
    id: root

    readonly property var themeConfig: Config.getSetting("theme", {})
    property string fontFamily: themeConfig.fontFamily ?? "Adwaita Mono"
    property int borderRadius: themeConfig.borderRadius ?? 8
    readonly property int clampedBorderRadius: borderRadius <= 24 ? borderRadius : Math.floor(24 + Math.pow(borderRadius - 24, 0.55))

    readonly property color swatch: Island.Dyn.primary
    readonly property real hue: swatch.hslHue
    readonly property real sat: Math.min(Math.max(swatch.hslSaturation, 0.35), 0.75)
    function tone(s, l) { return Qt.hsla(root.hue, s, l, 1); }

    // Accent slots are pulled part-way to the wallpaper's hue, the way matugen
    // harmonises them. Decorative slots (the clock's blue/sapphire/teal) go
    // most of the way so the bar reads as one family; red and yellow keep their
    // own hue, because low battery and alerts rely on it.
    function harmony(h, mix, s, l) {
        const d = ((h - root.hue + 1.5) % 1) - 0.5;
        return Qt.hsla((root.hue + d * mix + 1) % 1, s, l, 1);
    }

    property color crust: tone(sat * 0.35, 0.045)
    property color mantle: tone(sat * 0.35, 0.06)
    property color base: tone(sat * 0.35, 0.085)
    property color surface0: tone(sat * 0.30, 0.14)
    property color surface1: tone(sat * 0.25, 0.20)
    property color surface2: tone(sat * 0.22, 0.26)
    property color overlay0: tone(sat * 0.15, 0.40)
    property color overlay1: tone(sat * 0.15, 0.48)
    property color overlay2: tone(sat * 0.15, 0.56)
    property color subtext0: tone(sat * 0.15, 0.72)
    property color subtext1: tone(sat * 0.15, 0.80)
    property color text: tone(sat * 0.20, 0.90)
    property color mauve: tone(swatch ? sat : 0.45, 0.74)

    // status colours, hue pulled part-way to the wallpaper's (see harmony above)
    property color red: harmony(0.97, 0.15, 0.65, 0.72)
    property color maroon: harmony(0.99, 0.25, 0.55, 0.76)
    property color peach: harmony(0.07, 0.25, 0.60, 0.76)
    property color yellow: harmony(0.12, 0.20, 0.65, 0.78)
    property color green: harmony(0.30, 0.55, 0.45, 0.78)
    property color teal: harmony(0.47, 0.60, 0.40, 0.82)
    property color sapphire: harmony(0.55, 0.60, 0.45, 0.80)
    property color blue: harmony(0.61, 0.60, 0.35, 0.88)
    property color pink: harmony(0.88, 0.55, 0.50, 0.80)
}
