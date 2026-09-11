import QtQuick
import Quickshell
import Quickshell.Wayland

// Analog desktop clock, bottom-right of each screen. Bottom layer = above the
// wallpaper, under every window. Empty input mask, so clicks pass through.
// Colours follow the wallpaper: its dominant hue tints the face and hands, and
// they fade over when the wallpaper changes.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property int size: 220   // logical px; eDP-1 is 1.5x, so ~330 real
    readonly property int edge: 40

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-desktop-clock"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0
    mask: Region {}
    color: "transparent"
    anchors { bottom: true; right: true }
    margins { bottom: edge; right: edge }
    implicitWidth: size
    implicitHeight: size

    SystemClock { id: clock; precision: SystemClock.Seconds }

    ColorQuantizer {
        id: quant
        source: WallpaperState.path.length ? "file://" + WallpaperState.path : ""
        depth: 3          // 8 swatches
        rescaleSize: 64   // quantize a thumbnail, not the full-size image
    }

    // Swatches carry no pixel counts, but a colour covering more of the image
    // fills more of the 8 buckets. So each colourful swatch scores the chroma of
    // every swatch near its hue and the biggest group wins: a few bright orange
    // pixels on a purple wallpaper lose to the purple. null = grey wallpaper.
    function dominant(colors) {
        const chroma = c => c.hsvSaturation * c.hsvValue;
        const near = (a, b) => { const d = Math.abs(a - b); return Math.min(d, 1 - d) < 0.06; };
        let best = null, bestScore = 0;
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i];
            if (chroma(c) < 0.12)
                continue;
            let score = chroma(c) * 0.01;   // tie-break: most colourful in its group
            for (let j = 0; j < colors.length; j++)
                if (chroma(colors[j]) >= 0.12 && near(c.hslHue, colors[j].hslHue))
                    score += chroma(colors[j]);
            if (score > bestScore) { best = c; bestScore = score; }
        }
        return best;
    }

    readonly property var swatch: dominant(quant.colors)
    readonly property real hue: swatch ? swatch.hslHue : 0
    // grey wallpaper: sat 0 makes face and hands neutral, accent falls back to Theme
    readonly property real sat: swatch ? Math.min(Math.max(swatch.hslSaturation, 0.35), 0.85) : 0
    readonly property color accent: swatch ? Qt.hsla(hue, sat, Math.max(swatch.hslLightness, 0.55), 1) : Theme.pink
    readonly property color faceColor: Qt.hsla(hue, sat * 0.45, 0.08, 0.92)
    readonly property color hourColor: Qt.hsla(hue, sat * 0.35, 0.90, 1)
    readonly property color minuteColor: Qt.hsla(hue, sat * 0.25, 0.62, 1)

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.faceColor
        Behavior on color { ColorAnimation { duration: 600 } }

        Hand { length: 0.30; thickness: 0.045; color: root.hourColor
               angle: (clock.hours % 12) * 30 + clock.minutes * 0.5 }
        Hand { length: 0.42; thickness: 0.030; color: root.minuteColor
               angle: clock.minutes * 6 + clock.seconds * 0.1 }
        Hand { length: 0.46; thickness: 0.015; color: root.accent
               angle: clock.seconds * 6 }

        Rectangle {   // hub
            anchors.centerIn: parent
            width: parent.width * 0.05; height: width
            radius: width / 2
            color: root.accent
            Behavior on color { ColorAnimation { duration: 600 } }
        }
    }

    // A hand pivots on its bottom edge at the face centre. Always sweeps
    // clockwise, so 59s -> 0s goes forward instead of spinning back.
    component Hand: Rectangle {
        property real length      // fraction of face height
        property real thickness   // fraction of face width
        property real angle       // degrees clockwise from 12
        width: parent.width * thickness
        height: parent.height * length
        radius: Theme.radius
        anchors.bottom: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        transformOrigin: Item.Bottom
        rotation: angle
        Behavior on rotation {
            RotationAnimation { duration: 1000; direction: RotationAnimation.Clockwise }
        }
        Behavior on color { ColorAnimation { duration: 600 } }
    }
}
