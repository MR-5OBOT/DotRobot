pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Shared session flags persisted to a small JSON file and watched for external
 * change, so every Pill daemon (pill, lock) reads and writes the same
 * Do-Not-Disturb and Keep-Awake state live without a second notification server
 * or idle inhibitor. Toggling in one surface updates the others on the next file
 * event, and the state survives a daemon restart.
 */
Singleton {
    id: root

    property alias dnd: adapter.dnd
    property alias keepAwake: adapter.keepAwake
    property alias time12h: adapter.time12h
    property alias clockSeconds: adapter.clockSeconds
    property alias mainDisplay: adapter.mainDisplay
    property alias expandTo: adapter.expandTo
    property alias showGlyphs: adapter.showGlyphs
    property alias paletteMode: adapter.paletteMode
    property alias wallpaperDir: adapter.wallpaperDir
    property alias wallpaperFit: adapter.wallpaperFit
    property alias randomScope: adapter.randomScope
    property alias uiScale: adapter.uiScale

    /**
     * First-run UI scale, never a fixed 100%. Every surface sizes off
     * `(screen height / 1080) * uiScale`, so a screen the compositor already
     * scales reports fewer logical pixels and the island comes out small:
     * 1080p at Hyprland scale 1.5 reports 720, which drew it at two thirds.
     * Default to the offered step nearest the ratio that puts it back at 1:1
     * — 150% for that screen, 100% for an unscaled 1080p — so the bar is right
     * out of the box and the Interface page only has to override taste.
     */
    readonly property real autoScale: {
        const screens = Quickshell.screens;
        const h = (screens && screens.length > 0 && screens[0].height > 0) ? screens[0].height : 1080;
        const want = 1080 / h;
        const steps = [1.0, 1.15, 1.3, 1.5];   // the Interface page's own steps
        let best = steps[0];
        for (let i = 1; i < steps.length; i++)
            if (Math.abs(steps[i] - want) < Math.abs(best - want))
                best = steps[i];
        return best;
    }
    property alias reduceMotion: adapter.reduceMotion
    property alias manualHue: adapter.manualHue
    property alias manualDark: adapter.manualDark
    property alias manualSat: adapter.manualSat
    property alias uiFont: adapter.uiFont
    property alias pillOpacity: adapter.pillOpacity
    property alias pillBlur: adapter.pillBlur
    property alias autoHide: adapter.autoHide
    property alias topGap: adapter.topGap
    property alias appGap: adapter.appGap
    property alias idleLockMin: adapter.idleLockMin
    property alias idleScreenOffMin: adapter.idleScreenOffMin
    property alias idleSuspendMin: adapter.idleSuspendMin
    property alias weatherCity: adapter.weatherCity
    property alias musicViz: adapter.musicViz
    property alias nightLightMode: adapter.nightLightMode
    property alias nightLightTemp: adapter.nightLightTemp
    property alias nightLightOnMin: adapter.nightLightOnMin
    property alias nightLightOffMin: adapter.nightLightOffMin
    property alias memorySaver: adapter.memorySaver
    property alias unloadSec: adapter.unloadSec

    FileView {
        id: file
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/island/flags.json"
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function(error) {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property bool dnd: false
            property bool keepAwake: false
            property bool time12h: false
            property bool clockSeconds: false
            /** Collapsed-pill face: "minimal" (glyph + time), "classic" (date + time), "system" (weekday, time, workspace, layout, battery) or "strip" (full-width top bar). */
            property string mainDisplay: "minimal"
            /** What the media card's Expand control opens: "media" keeps the surface as the main screen, "pill" swaps to the expanded pill. With auto-hide off, "media" also makes hovering the resting pill grow into the player. */
            property string expandTo: "pill"
            property bool showGlyphs: true
            property string paletteMode: "static"
            /** Explicit wallpaper folder override. Empty means autodetect: the dir wallpaper.sh last resolved (island-wallpaper-dir state file), then ~/Pictures/wallpapers. Lives in user state so an in-app update never clobbers a custom folder. */
            property string wallpaperDir: ""
            /** Still/video wallpaper scaling: awww --resize "no" (center), "crop" (cover), "fit" (contain) or "stretch", driving the strip's Cover/Contain/Stretch/Center control. */
            property string wallpaperFit: "crop"
            /** Super+B random target: "all" repaints every monitor, "cursor" only the one under the pointer. */
            property string randomScope: "all"
            property real uiScale: root.autoScale
            property bool reduceMotion: false
            property int manualHue: 30
            property bool manualDark: true
            property real manualSat: 0.5
            property string uiFont: ""
            property real pillOpacity: 1.0
            property bool pillBlur: false
            property bool autoHide: true
            /** Top margin as a fraction of the shipped 8px. 0 sits the pill flush to the screen edge. */
            property real topGap: 1.0
            /** Pill-to-window band as a fraction of the shipped 12px. 0 tucks the windows flush under the pill. */
            property real appGap: 1.0
            property int idleLockMin: 5
            property int idleScreenOffMin: 6
            property int idleSuspendMin: 0
            property string weatherCity: ""
            property bool musicViz: true
            property string nightLightMode: "off"
            property int nightLightTemp: 4000
            property int nightLightOnMin: 1260
            property int nightLightOffMin: 450
            /** Drop closed surfaces after their own idle tier instead of holding them in RAM all session. */
            property bool memorySaver: true
            /** Wallpaper-tier idle in seconds when memorySaver is on; the other tiers scale off it. */
            property real unloadSec: 30
        }
    }
}
