pragma Singleton
import QtQuick
import "island/Singletons" as Island

// Colours for the top-edge notch widgets (launcher, clipboard, calculator, ...),
// taken from the island's Theme so they follow its Light / Dark / Dynamic palette
// and its wallpaper accent. Shapes and fonts are the widgets' own.
QtObject {
    readonly property color notchBg: Island.Theme.cardTop      // the notch card itself
    readonly property color surface: Island.Theme.tileBg       // raised / selected rows
    readonly property color border: Island.Theme.border        // hairline separators
    readonly property color text: Island.Theme.cream
    readonly property color bright: Island.Theme.bright        // emphasised text (selected row, hover)
    readonly property color subtle: Island.Theme.subtle
    readonly property color dim: Island.Theme.dim
    readonly property color faint: Island.Theme.faint
    readonly property color hover: Island.Theme.hairSoft       // hovered buttons and rows
    readonly property color well: Island.Theme.frameBg         // recessed fills (keycaps)
    readonly property color ghost: Island.Theme.ghost          // solid placeholder tiles
    readonly property color notchAccent: Island.Theme.vermLit  // the island's accent

    readonly property int radius: 4               // small rounded corners
    readonly property int notchRadius: 18         // notch cards' bottom corners
    readonly property int notchEar: 12            // concave shoulders (island/components/NotchEars default)
    readonly property string font: "IosevkaTerm Nerd Font Mono"
    readonly property string iconFont: "Material Symbols Sharp"  // one cohesive family, 0-radius
}
