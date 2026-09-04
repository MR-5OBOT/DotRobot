pragma Singleton
import QtQuick

// Dark theme, dark muted pink accent, square corners. Defined once.
QtObject {
    readonly property color bg: "#101010"       // panel + popup background
    readonly property color surface: "#181818"   // raised rows inside popups
    readonly property color border: "#2a2a2a"    // hairline separators
    readonly property color text: "#e8e8e8"
    readonly property color dim: "#7a7a7a"
    readonly property color pink: "#862F55"       // accent
    readonly property color pinkDim: "#742849"

    readonly property int barWidth: 42
    readonly property int radius: 0               // no rounded corners
    readonly property int gap: 8
    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property string iconFont: "Material Symbols Sharp"  // one cohesive family, 0-radius
}
