pragma Singleton
import QtQuick
import Quickshell

/**
 * Pill palette. Dark only: surfaces and text are the fixed hex below. On
 * Dynamic the accent ramp follows the wallpaper through the generated `Dyn`
 * singleton (Manual feeds it a user-picked hue through wallcolors.py); on Dark
 * it keeps the fixed warm hex.
 */
Singleton {
    readonly property bool dyn: Flags.paletteMode === "dynamic" || Flags.paletteMode === "manual"

    /**
     * Bright warm pop shared by the flame glow, charging glyphs, the recording
     * countdown, the unread inbox dot, the calendar's today cell and the held
     * power tile. The dynamic branch uses the wallpaper accent (Dyn.primary):
     * on-primary-container can collapse the
     * token to black, while the accent always loads and contrasts the pill
     * surface. The static branches keep the fixed warm hex.
     */
    readonly property color onGlow: dyn ? Dyn.primary : "#ff9a64"

    readonly property color verm:     dyn ? Qt.darker(Dyn.primary, 1.18) : "#c0442b"
    readonly property color vermLit:  dyn ? Dyn.primary : "#e0563b"
    readonly property color vermDeep: dyn ? Dyn.primaryContainer : "#a3371f"
    /** Surfaces and text stay pure black and neutral grey; only the accent follows the wallpaper. */
    readonly property color cream:    "#ececec"
    readonly property color bright:   "#ffffff"
    readonly property color dim:      "#8c8c8c"
    readonly property color cardTop:  "#000000"
    readonly property color cardBot:  "#000000"
    readonly property color border:   "#2b2b2b"
    readonly property color shadow:     Qt.rgba(0, 0, 0, 0.55)
    readonly property color tileBg:   "#141414"
    readonly property color subtle:   "#a8a8a8"
    readonly property color faint:    "#6a6a6a"
    readonly property color iconDim:  "#bdbdbd"
    readonly property color hair:     Qt.alpha(cream, 0.13)
    readonly property color hairSoft: Qt.alpha(cream, 0.08)
    readonly property color sheen:    Qt.alpha(cream, 0.07)
    readonly property color vermDim:   dyn ? Qt.darker(Dyn.primary, 1.5) : "#8a5440"
    readonly property color vermDimDeep: dyn ? Qt.darker(Dyn.primary, 2.2) : "#5a3526"
    readonly property color vermBurn:  dyn ? Qt.darker(Dyn.primaryContainer, 1.1) : "#8a2c14"
    readonly property color tickRest:  "#c2c2c2"
    readonly property color threadBg:  Qt.alpha(cream, 0.13)
    readonly property color flameCore: dyn ? Qt.lighter(onGlow, 1.03) : "#ffd9c2"
    readonly property color flameGlow: dyn ? onGlow : "#ff9a64"

    /**
     * Flame canvas ramp: literal hex strings (color type won't work), fed
     * directly to Canvas addColorStop/strokeStyle. A color property serializes
     * to #aarrggbb and corrupts the gradient render, so the dynamic branch passes
     * generated hex strings through untouched rather than any Qt.darker math.
     */
    readonly property string flameInk:   dyn ? Dyn.primary : "#f0795a"
    readonly property string flameEmber: dyn ? Dyn.primaryContainer : "#7e2812"
    readonly property string flameBurn:  dyn ? Dyn.primaryContainer : "#8a2c14"
    readonly property string flameTip:   dyn ? Dyn.primaryGlow : "#ffb38a"
    readonly property color todayWarm: dyn ? onGlow : "#ffb38a"
    readonly property color ghost:     "#242424"
    readonly property color frameBg:      Qt.alpha(cream, 0.055)
    readonly property color frameBorder:  Qt.alpha(cream, 0.10)
    readonly property color creamMenu:     Qt.alpha(cream, 0.82)
    readonly property real shadowOpacity: 0.5
    readonly property string font: "Noto Sans"

    /**
     * MPRIS trackArtists arrives as a JS array from some players and as a
     * plain string from others (Spotify); calling join on the string throws
     * and kills the whole binding. Handles both, falls back to trackArtist.
     */
    function joinArtists(artists, single) {
        if (artists && typeof artists.join === "function" && artists.length > 0)
            return artists.join(", ");
        if (artists && String(artists).length > 0)
            return String(artists);
        return single ? String(single) : "";
    }
}
