pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// DotRobot replacement for serpantinum's ThemeBackend. Upstream builds the
// palette with matugen, which also SIGUSR1s every running kitty; here it is
// derived in-process from the current wallpaper with quickshell's
// ColorQuantizer, using the same hue pick as DesktopClock.qml. Slot names stay
// serpantinum's Catppuccin-style ones so the vendored modules bind unchanged:
// the neutrals carry a little of the wallpaper's hue, "mauve" is the primary.
Item {
    id: root

    readonly property var themeConfig: Config.getSetting("theme", {})
    property string fontFamily: themeConfig.fontFamily ?? "Adwaita Mono"
    property int borderRadius: themeConfig.borderRadius ?? 8
    readonly property int clampedBorderRadius: borderRadius <= 24 ? borderRadius : Math.floor(24 + Math.pow(borderRadius - 24, 0.55))

    // same state file and fallback as WallpaperState.qml
    readonly property string home: Quickshell.env("HOME")
    property string wallpaper: home + "/Pictures/wallpapers/MR5OBOT.jpg"
    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || (root.home + "/.local/state")) + "/qs-wallpaper"
        watchChanges: true
        printErrors: false
        onLoaded: {
            const t = text().trim();
            if (t.length > 0)
                root.wallpaper = t;
        }
        onFileChanged: reload()
    }

    ColorQuantizer {
        id: quant
        source: root.wallpaper.length ? "file://" + root.wallpaper : ""
        depth: 3          // 8 swatches
        rescaleSize: 64   // quantize a thumbnail, not the full-size image
    }

    // Biggest colourful hue group wins (see DesktopClock.qml for why a single
    // most-colourful swatch is wrong). null = grey wallpaper.
    function dominant(colors) {
        const chroma = c => c.hsvSaturation * c.hsvValue;
        const near = (a, b) => { const d = Math.abs(a - b); return Math.min(d, 1 - d) < 0.06; };
        let best = null, bestScore = 0;
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i];
            if (chroma(c) < 0.12)
                continue;
            let score = chroma(c) * 0.01;
            for (let j = 0; j < colors.length; j++)
                if (chroma(colors[j]) >= 0.12 && near(c.hslHue, colors[j].hslHue))
                    score += chroma(colors[j]);
            if (score > bestScore) { best = c; bestScore = score; }
        }
        return best;
    }

    readonly property var swatch: dominant(quant.colors)
    // grey wallpaper: neutral greys, and the primary falls back to DotRobot's pink hue
    readonly property real hue: swatch ? swatch.hslHue : 0.92
    readonly property real sat: swatch ? Math.min(Math.max(swatch.hslSaturation, 0.35), 0.75) : 0
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
