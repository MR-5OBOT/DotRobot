pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Hyprland
import "Singletons"
import "components"
import "surfaces"

/**
 * The pill body. One element carries every state. Width/height driven by `state`
 * (rest, hover/pinned, mixer, calendar) with a no-overshoot easing so surfaces
 * grow out of the pill in place. Surfaces are stacked absolutely and cross-fade.
 *
 * Hover comes from a passive HoverHandler, pin from a passive TapHandler, so
 * neither swallows pointer events from the surfaces stacked above: workspace
 * dots, the clock target, tray icons and the mixer faders get their own clicks
 * and drags.
 */
Item {
    id: pill

    property real s: 1
    property string screenName: ""
    property var barWindow
    property string surface: ""

    /**
     * Tail retention: a closed surface keeps its object tree alive until its
     * own countdown elapses so a quick return is still instant. Every closed
     * surface is tracked by name in `closedAt` and swept independently, so
     * closing one never extends another's tail. When memory saver is on each
     * surface gets a tiered cooldown (heavy/thirsty surfaces evict sooner);
     * when off, closed surfaces stay resident for the whole session and only
     * the explicit `unloadAll` IPC drops them.
     */
    property string prevSurface: ""

    /**
     * Idle (ms) before a closed surface is unloaded, keyed by surface name,
     * scaled from the Flags.unloadSec base (`unloadS` here). The two heaviest
     * surfaces (wallpaper, mixer) keep the shortest tail; everything else gets
     * one 60s reset for quick re-toggles before it is reclaimed, so a session
     * that touched every surface returns near boot RSS within a couple of
     * minutes. Unlisted names fall through to that same short default.
     */
    readonly property real unloadS: (Flags.memorySaver ? Math.max(10, Flags.unloadSec) : 1e12)
    readonly property var unloadIdleMs: ({
        // heaviest, evict first
        wallpaper:   unloadS * 1000,
        mixer:       unloadS * 1000,
        // thirsty frequent fliers: one generous reset, then reclaim
        clipboard:   unloadS * 2 * 1000,
        media:       unloadS * 2 * 1000,
        calendar:    unloadS * 2 * 1000,
        // everything else: a single 60s reset for quick re-toggles, then reclaim
        default:     unloadS * 2 * 1000
    })

    /**
     * Every surface that has stopped being open, keyed by surface name, with
     * the epoch ms it closed. `surfaceItem` drops the entry when the surface
     * reopens (that *is* the "reset the clock and wait again" of the tail);
     * the sweep timer unloads each entry once its own tier has elapsed.
     */
    property var closedAt: ({})

    onSurfaceChanged: {
        if (pill.prevSurface.length > 0 && pill.prevSurface !== pill.surface)
            pill.scheduleUnload(pill.prevSurface);
        pill.prevSurface = pill.surface;
    }

    Component.onCompleted: Surfaces.register(pill)

    property bool hovered: false
    /**
     * True while a reveal interaction is in flight: the pointer touched the
     * reveal strip and is still over it or the collapsed pill it pulled in.
     * The strip sits in the input mask even when the pill is hidden, so this
     * persists across the strip -> pill transition until the pointer leaves,
     * keeping the mask covering both and the pill collapsed until it is
     * clicked.
     */
    property bool revealSession: false
    property bool pinned: false
    property bool forcePinned: false
    /** Latch held by an explicit Expand click in the media card. Unlike hoverLatch it survives cursor exit, so the expanded pill stays up until the user dismisses it (tap the pill, open a surface, or focus loss). */
    property bool expandLatch: false

    readonly property bool held: pinned || forcePinned
    readonly property bool homeOpen: surface === "home"
    readonly property bool mixerOpen: surface === "mixer"
    readonly property bool calendarOpen: surface === "calendar"

    /** The pill's app launcher is replaced by the main shell's (the Super+Space one). */
    function openUserLauncher() {
        Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
            "qs", "ipc", "call", "launcher", "toggle"]);
    }

    /** The pill's clipboard surface is replaced by the main shell's (the Super+V one). */
    function openUserClipboard() {
        Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
            "qs", "ipc", "call", "clipboard", "toggle"]);
    }

    /** The pill's wallpaper strip is replaced by the main shell's picker (the Super+W one). */
    function openUserWallpaper() {
        Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
            "qs", "ipc", "call", "wallpicker", "toggle"]);
    }

    /** The pill's wifi surface is replaced by the main shell's wifi panel, opened top-centre. */
    function openUserWifi() {
        Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
            "qs", "ipc", "call", "wifi", "wifiIsland"]);
    }

    /** Bluetooth is blueman-manager's job; the pill only shows adapter state and toggles it. */
    function openUserBt() {
        Quickshell.execDetached(["blueman-manager"]);
    }
    readonly property bool powerOpen: surface === "power"
    readonly property bool mediaOpen: surface === "media"
    readonly property bool linkOpen: surface === "link"
    readonly property bool weatherOpen: surface === "weather"
    readonly property bool batteryOpen: surface === "battery"
    readonly property bool sysmonOpen: surface === "sysmon"
    readonly property bool appearanceOpen: surface === "appearance"
    readonly property bool displayOpen: surface === "display"
    readonly property bool themeOpen: surface === "theme"
    readonly property bool interfaceOpen: surface === "interface"
    readonly property bool fontpickerOpen: surface === "fontpicker"
    readonly property bool settingsLike: appearanceOpen || displayOpen || themeOpen || interfaceOpen || fontpickerOpen
    readonly property bool hasMedia: Players.list.length > 0

    readonly property var netDevices: (typeof Networking !== "undefined" && Networking && Networking.devices) ? Networking.devices.values : []
    readonly property var wifiDev: netDevices.find(function(d) { return d && d.type === DeviceType.Wifi }) || null
    readonly property bool wifiOn: (typeof Networking !== "undefined" && Networking) ? Networking.wifiEnabled : false
    readonly property var wifiNets: (wifiDev && wifiDev.networks) ? wifiDev.networks.values : []
    readonly property var wifiActive: wifiNets.find(function(n) { return n && n.connected }) || null
    readonly property real wifiLevel: (wifiActive && wifiActive.signalStrength) || 0
    readonly property var btAdapter: (typeof Bluetooth !== "undefined" && Bluetooth) ? Bluetooth.defaultAdapter : null
    readonly property bool btOn: btAdapter ? btAdapter.enabled === true : false
    readonly property bool surfaceOpen: surface.length > 0
    property bool hoverLatch: false

    /**
     * False for the first seconds after the shell maps. Hyprland hands pointer
     * focus to a freshly mapped layer surface at the cursor's position, which
     * the window-level HoverHandler reads as a pill hover and latches the pill
     * open (issue #20). Latching only after boot settles filters that spurious
     * enter; a real hover during the window just expands late, harmlessly.
     */
    property bool bootSettled: false

    Timer {
        interval: 3000
        running: true
        onTriggered: pill.bootSettled = true
    }

    readonly property bool expanded: surfaceOpen || held || hoverLatch || expandLatch

    /**
     * First expansion (hover, latch, held, or any surface) marks weather as
     * actually wanted, so its refresh/fetch network work starts only then. The
     * chip itself is always built and renders the cached forecast instantly.
     */
    onExpandedChanged: {
        if (pill.expanded)
            Weather.needed = true;
    }

    /**
     * The collapsed pill becomes a compact top-centre capsule when the "strip"
     * main display is picked: it docks flush against the top screen edge, so
     * its top corners square off while the bottom corners stay rounded — the
     * Dynamic Glacier silhouette. Window reservation and auto-hide behave
     * exactly like the other faces.
     */
    readonly property bool stripBar: Flags.mainDisplay === "strip"

    /**
     * True when this pill sits on the monitor Hyprland currently has focused.
     * Only used to drop the cursor latch on focus loss: `hidden` itself is
     * central and does not key off monitor focus, so transient (OSD/toast)
     * appearances retract on their own even on the focused monitor.
     */
    readonly property bool monFocused: {
        const m = Hyprland.focusedMonitor;
        return m ? m.name === pill.screenName : false;
    }

    /**
     * Auto-hide mode retracts as soon as this monitor loses focus, even if the
     * cursor is still over the strip or pill: a click only expands the pill
     * temporarily, so focus loss (or cursor exit, via graceTimer) is what
     * releases the latch. Outside auto-hide the pill's pin still holds.
     */
    onMonFocusedChanged: if (!monFocused && Flags.autoHide) {
        revealSession = false;
        hoverLatch = false;
        expandLatch = false;
    }

    /**
     * True when a transient overlay owns the pill: an OSD flash (workspace,
     * volume, track, brightness, battery) or a notification toast. These pop the pill open without the cursor ever
     * getting involved, so the pill must let them finish and then retract on
     * its own — transients hold the pill up, but they leave no latch behind.
     */
    readonly property bool transientLive: toastActive

    /**
     * True when the pill should retract off the top edge: auto-hide is on and
     * nothing is holding the pill open — no reveal session under the cursor, no
     * expansion (pin, latch or open surface), no in-flight file drop, no game
     * bar, and no live transient overlay. This is the single central gate for
     * auto-hide: it deliberately does not key off monitor focus, so any
     * cursor-less appearance (a workspace switch, an OSD flash, a toast) retracts by itself once it is done. The reveal
     * strip above it still catches the pointer, so a hidden pill slides back in
     * on reach. Deliberately ignores raw `hovered`: the reveal session flag
     * (with its 350ms grace) is what keeps the pill up while the cursor is near
     * it, so a cursor sitting on the strip's edge cannot bounce it.
     */
    readonly property bool hidden: Flags.autoHide && !revealSession && !expanded && !dragActive
        && !transientLive

    /**
     * The special workspace shown on this pill's monitor, surfaced as a plain word
     * in place of the clock so it is obvious you are looking at the minimized stash
     * or the private space rather than your real desktop. Empty in the normal case.
     */
    readonly property string specialView: {
        var ms = Hyprland.monitors.values;
        for (var i = 0; i < ms.length; i++) {
            if (ms[i] && ms[i].name === pill.screenName) {
                var o = ms[i].lastIpcObject;
                var sw = (o && o.specialWorkspace) ? o.specialWorkspace.name : "";
                if (sw && sw.indexOf("special:") === 0) {
                    var id = sw.slice("special:".length);
                    var sl = Spaces.list;
                    for (var j = 0; j < sl.length; j++)
                        if (sl[j] && sl[j].id === id)
                            return sl[j].name;
                    if (id === "minimized") return "Minimized";
                    if (id === "private") return "Private";
                    if (id === "stash") return "Stash";
                    return id.charAt(0).toUpperCase() + id.slice(1);
                }
                return "";
            }
        }
        return "";
    }
    readonly property bool toastActive: Notifs.popups.length > 0
    readonly property bool osdActive: osd.flashing

    /**
     * A transient OSD (workspace switch, volume, brightness) that starts while
     * a non-critical toast is showing retires that toast permanently instead of
     * covering it and letting it reappear — a covered-and-returned toast reads
     * as a second notification. Critical toasts are never covered or retired:
     * the mode ladder gives them priority over the OSD.
     */
    onOsdActiveChanged: if (osdActive && toastActive && !Notifs.toastCritical) Notifs.clearPopups()

    readonly property real restW: 160 * s
    readonly property real restH: 38 * s

    /**
     * Strip-face geometry: a compact top-centre notch pill. Its width is
     * computed explicitly (not from the row's implicit width) so the media
     * title can be elided to exactly what the budget allows; on a 1920px
     * screen the content lands around 500-600px wide. Lower-priority sections
     * (visualizer, then media) fold away first when the budget tightens.
     */
    readonly property real stripPad: 20 * s
    readonly property real stripGap: 16 * s
    readonly property real stripCap: Math.max(320 * s, Math.min(600 * s, (barWindow ? barWindow.width : 1920 * s) - 60 * s))
    readonly property real stripArtW: 22 * s
    readonly property real stripMinTitle: 55 * s
    readonly property real stripMaxTitle: 220 * s

    readonly property real stripVizW: (Cava.bars * 1.8 + (Cava.bars - 1) * 1.2) * s

    /** Media-side gaps depend only on the visualizer state. */
    readonly property int stripMediaGaps: 1 + (Cava.active ? 1 : 0)

    readonly property bool stripMedia: Players.has && stripRoomForTitle >= stripMinTitle
    readonly property real stripRoomForTitle: stripCap - 2 * stripPad - stripArtW - stripFixedW
        - 4 * stripGap - stripMediaGaps * stripGap
        - (Cava.active ? stripVizW : 0)
    readonly property real stripTitleW: stripMedia ? Math.min(stripMaxTitle, stripRoomForTitle, Math.max(stripMinTitle, stripTitleMetrics.advanceWidth)) : 0
    readonly property real stripFixedW: stripDay.implicitWidth + stripTime.implicitWidth
        + stripWs.implicitWidth + stripLay.implicitWidth + stripBat.implicitWidth

    readonly property real stripFaceW: {
        let w = 2 * stripPad + stripFixedW + 4 * stripGap;
        if (stripMedia) {
            w += stripArtW + stripGap + stripTitleW;
            if (Cava.active) w += stripVizW + stripGap;
            w += stripGap;
        }
        return w;
    }
    readonly property real hoverPad: 20 * s
    readonly property real hoverW: hoverRow.implicitWidth + 2 * hoverPad
    readonly property real hoverH: 58 * s
    readonly property real calendarS: s * 1.05
    readonly property real homeW: 620 * s
    /* Tall enough for the left column's real content: media card 118 + gap 9 +
       the clock card, whose clock/date/weather/4-day strip needs ~140. At 396
       the clock card got ~107 and its content overflowed up over the media card. */
    readonly property real homeH: 446 * s
    readonly property real mixerH: 214 * s
    readonly property real powerW: 330 * s
    readonly property real powerH: 150 * s
    readonly property real mediaW: 470 * s
    readonly property real mediaH: 132 * s
    readonly property real batteryW: 316 * s
    readonly property real sysmonW: 392 * s
    readonly property real settingsScale: 0.9
    readonly property real settingsW: 392 * s * settingsScale
    readonly property real fontpickerW: 360 * s * settingsScale
    readonly property real toastW: 342 * s
    readonly property real dragOverW: 300 * s
    readonly property real dragOverH: 126 * s
    readonly property real restCorner: 18 * s
    readonly property real openCorner: 22 * s

    /**
     * Latch-once lazy load. Every surface sleeps in an inactive Loader until its
     * first open; the size and ame thunks below resolve items through here by
     * surface name. The ordering is the trick: flip `active` before any read of
     * the loader, so the calling binding never has the loader registered as a
     * dep when the flip fires mid-evaluation (that read-then-write would be a
     * binding loop). The write is idempotent and the Loader loads synchronously,
     * so a first open reads the real implicitHeight in the same evaluation and
     * the morph target is exact. When a surface leaves, scheduleUnload starts
     * its own tail; opening it again before the tail fires cancels the drop, so
     * only surfaces that stay closed actually unload.
     */
    function surfaceItem(name) {
        if (!pill.loaders[name])
            return null;
        const ld = pill.loaders[name]();
        if (!ld)
            return null;
        ld.active = true;
        pill.cancelUnload(name);
        return ld.item;
    }

    /**
     * Single source of truth for every morphing surface, keyed by its `surface`
     * string. Each entry owns the surface's target size (a thunk so the geometry
     * it reads registers as a live dep of targetSize) and a thunk resolving the
     * surface item Ame anchors to while it is open (null = Ame falls back to the
     * pill's own hover or wake anchor). `mode`, `targetSize` and `ameSurface` all
     * derive from this, so adding a surface is one entry here plus its Loader —
     * no parallel ternary chains to keep in lockstep.
     */
    readonly property var surfaces: ({
        home:      { size: () => { surfaceItem("home"); return Qt.size(homeW, homeH); }, ame: () => surfaceItem("home") },
        calendar:  { size: () => { const it = surfaceItem("calendar"); return Qt.size((it.implicitWidth > 0 ? it.implicitWidth : 282 * calendarS) + 36 * calendarS, it.implicitHeight + 32 * calendarS); }, ame: () => surfaceItem("calendar") },
        weather:   { size: () => { const it = surfaceItem("weather"); return Qt.size((it.implicitWidth > 0 ? it.implicitWidth : 282 * s) + 36 * s, it.implicitHeight + 32 * s); }, ame: () => surfaceItem("weather") },
        power:     { size: () => { surfaceItem("power"); return Qt.size(powerW, powerH); }, ame: () => surfaceItem("power") },
        media:     { size: () => { surfaceItem("media"); return Qt.size(mediaW, mediaH); }, ame: () => surfaceItem("media") },
        mixer:     { size: () => Qt.size(93 * Math.max(4, surfaceItem("mixer").faderCount) * s, mixerH), ame: () => surfaceItem("mixer") },
        link:      { size: () => { const it = surfaceItem("link"); return Qt.size(it.desiredW, it.implicitHeight + 26 * s); }, ame: () => surfaceItem("link") },
        battery:   { size: () => Qt.size(batteryW, surfaceItem("battery").implicitHeight + 26 * s), ame: () => surfaceItem("battery") },
        sysmon:    { size: () => Qt.size(sysmonW, surfaceItem("sysmon").implicitHeight + 33 * s), ame: () => surfaceItem("sysmon") },
        appearance: { size: () => Qt.size(settingsW, surfaceItem("appearance").implicitHeight + 29 * s), ame: () => surfaceItem("appearance") },
        display:    { size: () => Qt.size(settingsW, surfaceItem("display").implicitHeight + 29 * s), ame: () => surfaceItem("display") },
        theme:      { size: () => Qt.size(settingsW, surfaceItem("theme").implicitHeight + 29 * s), ame: () => surfaceItem("theme") },
        interface:  { size: () => Qt.size(settingsW, surfaceItem("interface").implicitHeight + 29 * s), ame: () => surfaceItem("interface") },
        fontpicker: { size: () => Qt.size(fontpickerW, surfaceItem("fontpicker").implicitHeight + 29 * s), ame: () => surfaceItem("fontpicker") }
    })

    /**
     * Loader lookup by surface name, as thunks so the map never pins a loader
     * before it is built. The unload machinery keeps every closed surface
     * resident for its own tiered countdown, then drops it — so opening a
     * surface pays its build cost once, and re-opening within the tail is
     * instant.
     */
    readonly property var loaders: ({
        home:       () => ldHome,
        calendar:   () => ldCalendar,
        weather:    () => ldWeather,
        power:      () => ldPower,
        media:      () => ldMedia,
        mixer:      () => ldMixer,
        link:       () => ldLink,
        battery:    () => ldBattery,
        sysmon:     () => ldSysmon,
        appearance: () => ldAppearance,
        display:    () => ldDisplay,
        theme:      () => ldTheme,
        interface:  () => ldInterface,
        fontpicker: () => ldFontpicker
    })

    /**
     * Arm a closed surface's own tail. Only surfaces that are actually loaded
     * are tracked, so a name can never sit in the map pointing at an inactive
     * loader. Reopening the surface before the tail elapses has already called
     * cancelUnload by the time this could re-fire, so the countdown restarts
     * on the next close — "open again before its tier elapses, stay alive".
     */
    function scheduleUnload(name) {
        if (!name || !pill.loaders[name])
            return;
        const ld = pill.loaders[name]();
        if (!ld || !ld.active)
            return;
        pill.closedAt[name] = Date.now();
        sweepTimer.start();
    }

    function cancelUnload(name) {
        if (!name)
            return;
        delete pill.closedAt[name];
        if (Object.keys(pill.closedAt).length === 0)
            sweepTimer.stop();
    }

    /**
     * This surface's own idle window, from the tier map by surface name.
     * Loaders not actually defined (typo'd or removed names) fall through to
     * the full default so they never evict accidentally early.
     */
    function idleFor(name) {
        var v = pill.unloadIdleMs[name];
        if (v === undefined)
            v = pill.unloadIdleMs.default;
        return v;
    }

    /**
     * Periodic sweep. Each closed surface carries its own timestamp, so every
     * one is dropped independently once its own tier has elapsed; unloading one
     * never shortens or lengthens another's countdown.
     */
    Timer {
        id: sweepTimer
        interval: 5000
        repeat: true
        running: false
        onTriggered: {
            var now = Date.now();
            var names = Object.keys(pill.closedAt);
            var keeps = false;
            var dropped = false;
            for (var i = 0; i < names.length; i++) {
                var name = names[i];
                if (now - pill.closedAt[name] >= pill.idleFor(name)) {
                    const fn = pill.loaders[name];
                    const ld = fn ? fn() : null;
                    if (ld && ld.active) {
                        ld.active = false;
                        dropped = true;
                    }
                    delete pill.closedAt[name];
                } else {
                    keeps = true;
                }
            }
            if (dropped)
                Qt.callLater(pill.reapJs);
            if (!keeps)
                sweepTimer.stop();
        }
    }

    /**
     * Detached JS models/closures outlive a Loader teardown until the engine's
     * next major collection. A GC right after an eviction reclaims those
     * wrappers up-front instead of piling into a later spike. Guarded because
     * the `gc` global is not available in every JS environment.
     */
    function reapJs() {
        if (typeof gc === "function")
            gc();
    }

    /**
     * Drop every closed surface now, regardless of how much of its tail is
     * left. The open surface is never in `closedAt`, so it is untouched. This
     * is what the unloadAll IPC routes to every pill.
     */
    function unloadClosedSurfaces() {
        var names = Object.keys(pill.closedAt);
        var dropped = false;
        for (var i = 0; i < names.length; i++) {
            const fn = pill.loaders[names[i]];
            const ld = fn ? fn() : null;
            if (ld && ld.active) {
                ld.active = false;
                dropped = true;
            }
            delete pill.closedAt[names[i]];
        }
        sweepTimer.stop();
        if (dropped)
            Qt.callLater(pill.reapJs);
    }

    readonly property string mode: dragActive ? "dragOver"
        : (surfaceOpen && surfaces[surface] !== undefined ? surface
        : (toastActive && Notifs.toastCritical && !held ? "toast"
        : (toastActive && !held ? "toast"
        : (expanded ? "hover" : "rest"))))

    /**
     * AppImage drag-install state, live only while a file hovers the resting pill.
     * `dragStage` walks hover -> installing -> done, or bad for a non-AppImage drop.
     */
    property bool dragActive: false
    property string dragName: ""
    property string dragStage: ""

    signal requestSurface(string name)
    signal requestClose()

    /**
     * Forward an arrow-key nudge to the open mixer's targeted fader. Returns true
     * when the mixer is open and a fader consumed the step.
     */
    function mixerStep(deltaPct) {
        return (pill.mixerOpen && ldMixer.item) ? ldMixer.item.stepFocused(deltaPct) : false;
    }

    /**
     * Move the open mixer's keyboard focus across the fader row; `dir` is +1
     * (right) or -1 (left). No-op unless the mixer is open.
     */
    function mixerFocusMove(dir) {
        if (pill.mixerOpen && ldMixer.item)
            ldMixer.item.moveFocus(dir);
    }

    /**
     * Resolve which settings-family surface owns keyboard row navigation right
     * now: the category index or one of its morphing sub-surfaces. Returns null
     * when none of them is open.
     */
    function rowNavSurface() {
        if (pill.appearanceOpen)
            return ldAppearance.item;
        if (pill.displayOpen)
            return ldDisplay.item;
        if (pill.themeOpen)
            return ldTheme.item;
        if (pill.interfaceOpen)
            return ldInterface.item;
        if (pill.fontpickerOpen)
            return ldFontpicker.item;
        return null;
    }

    /**
     * Move the focused settings row by `dir` (+1 down, -1 up), carrying the soul
     * seam. Returns true when a settings-family surface is open and consumed it.
     */
    function settingsMove(dir) {
        var nav = pill.rowNavSurface();
        if (!nav)
            return false;
        nav.kbMove(dir);
        return true;
    }

    /**
     * Step the focused settings row's control: a segmented choice cycles by
     * `dir`, a toggle is set on (dir > 0) or off. Returns true when consumed.
     */
    function settingsAdjust(dir) {
        var nav = pill.rowNavSurface();
        if (!nav)
            return false;
        nav.kbAdjust(dir);
        return true;
    }

    /**
     * Activate the focused settings row: a toggle flips, a nav row opens its
     * sub-surface. Returns true when a settings-family surface is open.
     */
    function settingsActivate() {
        var nav = pill.rowNavSurface();
        if (!nav)
            return false;
        nav.kbActivate();
        return true;
    }

    /**
     * Step the open surface back one level when its header bar is clicked: a
     * settings sub-surface (display, theme, interface, font picker) returns to
     * the appearance index, and the index or any other surface dismisses to the
     * hover pill. Empty space in the body never triggers this.
     */
    function surfaceBack() {
        if (pill.displayOpen || pill.themeOpen || pill.interfaceOpen || pill.fontpickerOpen) {
            pill.requestSurface("appearance");
            return;
        }
        pill.requestClose();
    }

    /**
     * Slide the open power surface's keyboard focus by `dir` tiles; +1 is right
     * and -1 is left. No-op unless the power surface is open.
     */
    function powerMove(dir) {
        if (pill.powerOpen && ldPower.item)
            ldPower.item.move(dir);
    }

    /**
     * Enter pressed on the open power surface's focused tile: fires a safe tile
     * at once, latches a destructive tile's heat hold. Returns true when a tile
     * consumed the key. No-op (false) unless the power surface is open.
     */
    function powerPress() {
        return (pill.powerOpen && ldPower.item) ? ldPower.item.pressFocused() : false;
    }

    /**
     * Enter released on the open power surface: drains an unfinished destructive
     * hold so a key let go before the fill completes never confirms.
     */
    function powerRelease() {
        if (pill.powerOpen && ldPower.item)
            ldPower.item.releaseFocused();
    }

    onSurfaceOpenChanged: if (surfaceOpen) {
        pinned = false;
        revealSession = false;
        hoverLatch = false;
        expandLatch = false;
        revealTimer.stop();
    }

    QtObject {
        id: clock
        readonly property var loc: Qt.locale("en_US")
        readonly property var now: sysClock.date
        readonly property string timeFormat: (Flags.time12h ? "h:mm" : "HH:mm")
            + (Flags.clockSeconds ? ":ss" : "")
            + (Flags.time12h ? " AP" : "")
        readonly property string hhmm: Qt.formatTime(now, timeFormat)
        readonly property string date: loc.toString(now, "ddd d MMM")
        readonly property string weekday: loc.toString(now, "ddd")
    }

    SystemClock {
        id: sysClock
        precision: Flags.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    /**
     * Re-sync the clock when the machine wakes from sleep or lid close.
     * SystemClock's internal timer is monotonic, so it does not advance while
     * suspended and the displayed time stays frozen at the pre-sleep minute
     * until that timer drains. systemd-logind broadcasts PrepareForSleep(true)
     * before suspending and PrepareForSleep(false) on wake; on the wake signal
     * we re-enable the clock to force it to re-read the wall clock immediately.
     */
    Process {
        id: sleepWatcher
        running: true
        command: ["dbus-monitor", "--system",
            "type='signal',sender='org.freedesktop.login1',member='PrepareForSleep'"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("boolean false") >= 0) {
                    sysClock.enabled = false;
                    sysClock.enabled = true;
                }
            }
        }
        onExited: () => sleepWatcher.running = true
    }

    property real morphRadius: (mode === "rest" || mode === "hover") ? restCorner : openCorner

    /**
     * Target geometry for the non-surface morph modes. Surface sizes come from
     * the `surfaces` descriptor; these are the pill's own modes that have no
     * surface item. Thunks so the properties they read register as live deps of
     * targetSize. osd uses its own content-driven size — the workspace flash
     * fits its dot row (so it stays short even on the wide strip notch) while
     * volume/brightness keep their fixed widths. The toast keeps its
     * fixed width and sizes its height to the notification.
     */
    readonly property var modeSize: ({
        toast: () => Qt.size(toastW, toastLoader.item ? toastLoader.item.implicitHeight + 24 * s : restH),
        hover: () => Qt.size(hoverW, hoverH),
        dragOver:    () => Qt.size(dragOverW, dragOverH)
    })

    /**
     * The pill's resting size for the current display mode.
     */
    readonly property size restSize: stripBar
        ? Qt.size(Math.max(restW, stripFaceW), restH)
        : Qt.size(Math.max(restW, restRow.implicitWidth + 36 * s), restH)

    readonly property size targetSize: {
        const sf = surfaces[mode];
        if (sf) {
            const z = sf.size();
            return Qt.size(z.width, z.height + Surfaces.pad * s);
        }
        const f = modeSize[mode];
        if (f)
            return f();
        return restSize;
    }
    readonly property real targetW: targetSize.width
    readonly property real targetH: targetSize.height

    width: targetW
    height: targetH

    /**
     * How settled the pill is into its target geometry: 0 while the morph is far
     * away, 1 once it arrives. Content opacities key off this, not their own
     * timers, so a surface fades in as the pill reaches full size, never over a
     * half-grown pill.
     */
    readonly property real morphCloseness: {
        const d = Math.max(Math.abs(width - targetW), Math.abs(height - targetH));
        return 1 - Math.min(1, d / (110 * s));
    }

    /**
     * Gate the soul bead until the hover morph has arrived and its icons exist.
     * Fire it earlier and the bead aims at anchors that aren't laid out yet.
     * Latched so small width changes inside hover (workspace dot growing, tray
     * icons appearing) don't flicker the bead off.
     */
    property bool hoverSoulGate: false
    readonly property bool hoverArrived: mode === "hover" && morphCloseness > 0.55
    onHoverArrivedChanged: if (hoverArrived) hoverSoulGate = true

    /**
     * Rest and hover sit a few dozen pixels apart, so the 420ms morph is nearly
     * all settle tail on that hop and reads sluggish. Both endpoints in the
     * rest/hover pair get the shorter glide; every real surface morph keeps the
     * full duration.
     */
    property string lastMode: "rest"
    property bool hoverHop: false

    onModeChanged: {
        hoverHop = (mode === "hover" || mode === "rest") && (lastMode === "hover" || lastMode === "rest");
        lastMode = mode;
        if (mode !== "hover") {
            hoverSoulGate = false;
            soulTarget = "";
            soulWsIndex = -1;
        }
    }
    onHoverSoulGateChanged: if (hoverSoulGate) kanjiFlashAnim.restart()

    property string soulTarget: ""
    property int soulWsIndex: -1

    property real kanjiFlash: 0

    SequentialAnimation {
        id: kanjiFlashAnim
        NumberAnimation { target: pill; property: "kanjiFlash"; to: 1; duration: 90; easing.type: Easing.OutCubic }
        NumberAnimation { target: pill; property: "kanjiFlash"; to: 0; duration: 320; easing.type: Easing.OutCubic }
    }

    Behavior on width { NumberAnimation { id: morphAnimW; duration: pill.hoverHop ? Motion.glide : Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }
    Behavior on height { NumberAnimation { id: morphAnimH; duration: pill.hoverHop ? Motion.glide : Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }
    Behavior on morphRadius { NumberAnimation { id: morphAnimR; duration: pill.hoverHop ? Motion.glide : Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }

    /**
     * True while any morph axis animates. The body's effect layer (live drop
     * shadow) re-renders its offscreen buffer at every size step, on every
     * monitor, so it is the top per-frame cost of a morph; dropping the shadow
     * mid-flight and restoring it on settle keeps the morph cheap (issue #20).
     */
    readonly property bool morphing: morphAnimW.running || morphAnimH.running || morphAnimR.running

    Rectangle {
        id: body
        anchors.fill: parent

        /**
         * Corner flatness rides the morph curve so docking into the game bar
         * squares the corners as one continuous shape change instead of a snap.
         * The pill always docks flush to the screen's top edge as a notch: its
         * top corners square off against the edge (NotchEars flare them into
         * it) while the bottom corners stay rounded.
         */
        property real topFlat: 1

        radius: pill.morphRadius
        topLeftRadius: pill.morphRadius * (1 - topFlat)
        topRightRadius: pill.morphRadius * (1 - topFlat)
        bottomLeftRadius: pill.morphRadius
        bottomRightRadius: pill.morphRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.cardTop, Flags.pillOpacity) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.cardBot, Flags.pillOpacity) }
        }

        /**
         * The live drop shadow keeps an offscreen render of the whole body on
         * every monitor. Drag it off entirely while the pill is auto-hidden
         * off-screen (nobody sees the shadow there) — the layer's FBO and the
         * per-frame update only exist while the pill is actually visible.
         */
        layer.enabled: !pill.morphing && !pill.hidden
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, Theme.shadowOpacity)
            shadowBlur: 0.7
            shadowVerticalOffset: 3 * pill.s
        }

    }

    /** Concave shoulders flaring the docked body into the screen's top edge. */
    NotchEars {
        anchors.top: parent.top
        width: parent.width
        r: 14 * pill.s
        color: Qt.alpha(Theme.cardTop, Flags.pillOpacity)
    }

    /**
     * Rest anchor for Ame: the 時 kanji centre. The idle outline condenses into
     * the bead here before it moves.
     */
    readonly property point wakePoint: {
        void pill.width;
        void pill.height;
        return restKanji.mapToItem(pill, restKanji.width / 2, restKanji.height / 2);
    }

    /**
     * Bead target while hovered. soulTarget is a sticky key written by the hover
     * sources: the bead parks on the last focused dot or icon and glides to the
     * next, so crossing a gap between targets doesn't snap it back to the active
     * workspace. Pill geometry is voided so the anchor follows the hover morph,
     * the point stays live.
     */
    readonly property point soulPoint: {
        void pill.width;
        void pill.height;
        const drop = 12 * pill.s;
        if (soulTarget === "wifi")
            return wifiIcon.mapToItem(pill, wifiIcon.width / 2, wifiIcon.height + drop * 0.55);
        if (soulTarget === "bt")
            return btIcon.mapToItem(pill, btIcon.width / 2, btIcon.height + drop * 0.55);
        if (soulTarget === "battery")
            return batteryIcon.mapToItem(pill, batteryIcon.width / 2, batteryIcon.height + drop * 0.55);
        if (soulTarget === "media")
            return mediaIcon.mapToItem(pill, mediaIcon.width / 2, mediaIcon.height + drop * 0.55);
        if (soulTarget === "inbox")
            return inboxIcon.mapToItem(pill, inboxIcon.width / 2, inboxIcon.height + drop * 0.55);
        if (soulTarget === "mixer")
            return mixerIcon.mapToItem(pill, mixerIcon.width / 2, mixerIcon.height + drop * 0.55);
        if (soulTarget === "power")
            return powerIcon.mapToItem(pill, powerIcon.width / 2, powerIcon.height + drop * 0.55);
        if (soulTarget === "sysmon")
            return sysmonIcon.mapToItem(pill, sysmonIcon.width / 2, sysmonIcon.height + drop * 0.55);
        if (soulTarget === "wallpaper")
            return wallpaperIcon.mapToItem(pill, wallpaperIcon.width / 2, wallpaperIcon.height + drop * 0.55);
        if (soulTarget === "clipboard")
            return clipboardIcon.mapToItem(pill, clipboardIcon.width / 2, clipboardIcon.height + drop * 0.55);
        if (soulTarget === "appearance")
            return appearanceIcon.mapToItem(pill, appearanceIcon.width / 2, appearanceIcon.height + drop * 0.55);
        if (soulTarget === "ws" && soulWsIndex >= 0) {
            void ws.activeName;
            void ws.width;
            const p = ws.mapToItem(pill, ws.slotCenterX(soulWsIndex), ws.height / 2);
            return Qt.point(p.x, p.y + drop);
        }
        return ws.mapToItem(pill, ws.activeDotPoint.x, ws.activeDotPoint.y + drop);
    }

    /**
     * Which open surface owns Ame's anchor. Each surface exports its own
     * `ameForm`/`amePoint`; the pill picks the open surface's `ame` from the
     * descriptor and maps it. Null = nothing open (or a surface with no anchor,
     * e.g. wallpaper), so Ame falls back to the pill's own hover/wake anchor.
     */
    readonly property var ameSurface: (surfaceOpen && surfaces[surface] !== undefined)
        ? surfaces[surface].ame() : null

    Ame {
        id: ame
        anchors.fill: parent
        s: pill.s
        heat: (pill.powerOpen && ldPower.item) ? ldPower.item.holdProgress : 0
        wake: pill.wakePoint
        wickDir: pill.powerOpen ? 1 : -1
        form: pill.ameSurface ? pill.ameSurface.ameForm
            : (pill.mode === "hover" && pill.hoverSoulGate ? "soul" : "off")
        point: pill.ameSurface
            ? Qt.point(pill.ameSurface.x + pill.ameSurface.amePoint.x,
                       pill.ameSurface.y + pill.ameSurface.amePoint.y)
            : (pill.mode === "hover" ? pill.soulPoint : pill.wakePoint)
    }

    onHoveredChanged: {
        if (hovered) {
            if (!Flags.autoHide && Flags.expandTo === "media" && pill.hasMedia
                && !pill.surfaceOpen && !pill.dragActive
                && bootSettled && !toastActive) {
                /* expandTo "media" with auto-hide off: a hover grows the pill
                 * into the player itself instead of the icon face. Auto-hide
                 * still reveals the normal pill; a click opens the player
                 * (TapHandler below). Game mode never hands the bar to the
                 * player, or the exit chip would be buried under it. */
                pill.requestSurface("media");
            } else if (Flags.autoHide && !revealSession && !expanded && !surfaceOpen) {
                revealSession = true;
                revealTimer.stop();
            }
            /* Hover no longer grows the pill into the icon row: Home carries the
             * same controls, and a click opens it. hoverLatch is still set by
             * the media card's Expand. */
        } else {
            if (!pinned && !surfaceOpen && !revealSession)
                hoverLatch = false;
            graceTimer.restart();
            revealTimer.start();
        }
    }

    Timer {
        id: graceTimer
        interval: 300
        onTriggered: {
            if (pill.morphCloseness < 0.95) {
                graceTimer.restart();
                return;
            }
            pill.hoverLatch = false;
        }
    }

    /**
     * Ends a reveal session once the pointer has left the reveal strip and the
     * collapsed pill (and nothing else holds the pill open). The interval is a
     * grace window so the strip -> pill handoff never drops the session mid-move.
     */
    Timer {
        id: revealTimer
        interval: 350
        onTriggered: {
            if (!pill.hovered && !pill.pinned && !pill.surfaceOpen)
                pill.revealSession = false;
        }
    }

    TapHandler {
        enabled: !pill.surfaceOpen
        gesturePolicy: TapHandler.WithinBounds
        onTapped: {
            if (pill.expandLatch) {
                pill.expandLatch = false;
                pill.hoverLatch = false;
                return;
            }
            if (Flags.expandTo === "media" && pill.hasMedia)
                pill.requestSurface("media");
            else
                pill.requestSurface("home");
        }
    }

    /**
     * Right-click toggles the media player from anywhere on the pill: on the
     * collapsed pill it pops the now-playing surface open, and on the open
     * media surface it dismisses back to the clock. Other surfaces are left to
     * their own clicks and the modal backdrop.
     */
    TapHandler {
        acceptedButtons: Qt.RightButton
        enabled: !pill.surfaceOpen || pill.mediaOpen
        gesturePolicy: TapHandler.WithinBounds
        onTapped: {
            if (pill.mediaOpen)
                pill.requestClose();
            else
                pill.requestSurface("media");
        }
    }

    property var installQueue: []

    function localPath(url) {
        var s = String(url);
        if (s.indexOf("file://") === 0)
            s = s.substring(7);
        return decodeURIComponent(s);
    }

    readonly property var dropExt: /\.(appimage|deb|rpm|flatpakref|zip|tgz|txz|tbz2|ttf|otf|png|jpe?g|webp)$|\.(pkg\.)?tar\.(gz|xz|bz2|zst)$/i

    function droppablePaths(urls) {
        var out = [];
        for (var i = 0; i < urls.length; i++)
            if (pill.dropExt.test(String(urls[i])))
                out.push(pill.localPath(urls[i]));
        return out;
    }

    function dropLabel(urls) {
        var p = pill.localPath(urls.length ? urls[0] : "");
        return p.substring(p.lastIndexOf("/") + 1).replace(pill.dropExt, "");
    }

    property bool installedAny: false
    property bool installedApp: false
    property bool installFailed: false
    property string installKind: "app"
    property string installAction: "new"
    property string installLine: ""
    property string installProto: ""
    property string installPct: ""
    property int installSeconds: 0

    function runNextInstall() {
        if (pill.installQueue.length === 0) {
            pill.dragStage = pill.installedAny ? "done" : "fail";
            (pill.installedAny ? dropDoneTimer : dropBadTimer).restart();
            return;
        }
        var next = pill.installQueue.shift();
        pill.dragName = next.substring(next.lastIndexOf("/") + 1).replace(pill.dropExt, "");
        pill.installLine = "";
        pill.installProto = "";
        pill.installPct = "";
        installProc.command = ["bash", Config.islandPath("scripts", "app-install.sh"), "install", next];
        installProc.running = true;
    }

    /**
     * Streams installer stdout instead of collecting it: slow backends (flatpak
     * runtime pulls, pacman) narrate their steps, and the drop face mirrors the
     * newest line live. The machine-readable result is the one tab-separated
     * kind-prefixed line, fished out of the stream as it passes.
     */
    Process {
        id: installProc
        stdout: SplitParser {
            onRead: (data) => {
                var seg = data.split("\r").pop().replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "").trim();
                if (seg.length === 0)
                    return;
                if (/^(app|native|font|wallpaper)\t/.test(seg)) {
                    pill.installProto = seg;
                } else {
                    pill.installLine = seg;
                    var pct = seg.match(/(\d{1,3})\s*%/);
                    if (pct && Number(pct[1]) <= 100)
                        pill.installPct = pct[1] + "%";
                }
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0 && pill.installProto.length > 0) {
                pill.installedAny = true;
                var parts = pill.installProto.split("\t");
                pill.installKind = parts[0];
                pill.installAction = parts[2];
                if (parts[0] === "app" || parts[0] === "native")
                    pill.installedApp = true;
                if (parts[0] === "font" && parts.length >= 4)
                    droppedFont.source = "file://" + parts[3];
            } else {
                pill.installFailed = true;
            }
            pill.runNextInstall();
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: pill.dragStage === "installing"
        onTriggered: pill.installSeconds++
    }

    /**
     * Registers a just-dropped font in this running process; the fontconfig
     * cache alone only reaches apps started later. Ready -> the font picker's
     * family list refreshes and the new face shows up without a restart.
     */
    FontLoader {
        id: droppedFont
        onStatusChanged: if (status === FontLoader.Ready) Theme.refreshFonts()
    }

    Timer {
        id: dropDoneTimer
        interval: 1100
        onTriggered: {
            pill.dragActive = false;
            pill.dragStage = "";
            if (pill.installedApp)
                pill.openUserLauncher();
        }
    }

    Timer {
        id: dropBadTimer
        interval: 1300
        onTriggered: {
            pill.dragActive = false;
            pill.dragStage = "";
        }
    }

    /**
     * Shared drop lifecycle. Entered during a drag (either over the pill itself
     * or over the auto-hide reveal strip in shell.qml), dropped at release.
     * Extracted so the hidden pill's reveal strip can hand drops straight into
     * the same install flow the resting pill uses.
     */
    function dropEntered(urls) {
        pill.dragActive = true;
        pill.dragStage = pill.droppablePaths(urls).length > 0 ? "hover" : "bad";
        pill.dragName = pill.dropLabel(urls);
    }

    function dropExited() {
        if (pill.dragStage === "hover" || pill.dragStage === "bad") {
            pill.dragActive = false;
            pill.dragStage = "";
        }
    }

    function dropDropped(urls) {
        var files = pill.droppablePaths(urls);
        if (files.length === 0) {
            pill.dragActive = true;
            pill.dragStage = "bad";
            pill.dragName = pill.dropLabel(urls);
            dropBadTimer.restart();
            return;
        }
        pill.dragActive = true;
        pill.dragStage = "installing";
        pill.installedAny = false;
        pill.installedApp = false;
        pill.installFailed = false;
        pill.installKind = "app";
        pill.installAction = "new";
        pill.installSeconds = 0;
        pill.installQueue = files;
        pill.runNextInstall();
    }

    /**
     * File drops land only on the resting pill; an open surface turns the pill
     * into a fullscreen modal that swallows the drag before it can start.
     * app-install.sh routes each drop by type (apps install, fonts land in the
     * font dir, images become the wallpaper), anything else flashes a rejection.
     */
    DropArea {
        anchors.fill: parent
        enabled: !pill.surfaceOpen && pill.dragStage !== "installing" && pill.dragStage !== "done"
        keys: ["text/uri-list"]
        onEntered: (drag) => {
            drag.acceptProposedAction();
            pill.dropEntered(drag.urls);
        }
        onExited: pill.dropExited()
        onDropped: (drop) => {
            drop.acceptProposedAction();
            pill.dropDropped(drop.urls);
        }
    }

    /**
     * Drop-zone face: corner brackets frame a stage glyph and label that walk
     * from "drop to install" through the spinner to a checkmark. Shares the morph
     * fade of the other pill faces, so it grows in as the pill reaches its size.
     */
    Item {
        id: dragOverView
        anchors.fill: parent
        anchors.margins: 11 * pill.s
        enabled: pill.mode === "dragOver"
        opacity: pill.mode === "dragOver" ? Math.pow(pill.morphCloseness, 1.2) : 0
        visible: opacity > 0.01

        Behavior on opacity { NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard } }

        readonly property color accent: (pill.dragStage === "bad" || pill.dragStage === "fail") ? "#e0533f" : Theme.vermLit
        readonly property real brLen: 15 * pill.s
        readonly property real brThick: 2 * pill.s

        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]
            delegate: Item {
                id: corner
                required property var modelData
                readonly property bool rightSide: modelData[0] === 1
                readonly property bool bottomSide: modelData[1] === 1
                x: rightSide ? dragOverView.width - dragOverView.brLen : 0
                y: bottomSide ? dragOverView.height - dragOverView.brLen : 0
                width: dragOverView.brLen
                height: dragOverView.brLen

                Rectangle {
                    width: dragOverView.brLen
                    height: dragOverView.brThick
                    radius: dragOverView.brThick / 2
                    color: dragOverView.accent
                    anchors.top: corner.bottomSide ? undefined : parent.top
                    anchors.bottom: corner.bottomSide ? parent.bottom : undefined
                    anchors.left: corner.rightSide ? undefined : parent.left
                    anchors.right: corner.rightSide ? parent.right : undefined
                }
                Rectangle {
                    width: dragOverView.brThick
                    height: dragOverView.brLen
                    radius: dragOverView.brThick / 2
                    color: dragOverView.accent
                    anchors.top: corner.bottomSide ? undefined : parent.top
                    anchors.bottom: corner.bottomSide ? parent.bottom : undefined
                    anchors.left: corner.rightSide ? undefined : parent.left
                    anchors.right: corner.rightSide ? parent.right : undefined
                }
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 44 * pill.s
            spacing: 7 * pill.s

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 26 * pill.s
                height: 26 * pill.s

                GlyphIcon {
                    id: dragGlyph
                    anchors.fill: parent
                    stroke: 2
                    color: dragOverView.accent
                    name: (pill.dragStage === "bad" || pill.dragStage === "fail") ? "close"
                        : (pill.dragStage === "installing" ? "reboot"
                        : (pill.dragStage === "done" ? "check" : "download"))

                    RotationAnimation on rotation {
                        running: pill.dragStage === "installing"
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                    onNameChanged: if (pill.dragStage !== "installing") rotation = 0
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pill.dragStage === "bad" ? "Can't install this"
                    : (pill.dragStage === "fail" ? "Install failed"
                    : (pill.dragStage === "installing" ? ("Installing"
                        + (pill.installPct.length > 0 ? " " + pill.installPct : "")
                        + (pill.installSeconds >= 3 ? "  " + Math.floor(pill.installSeconds / 60) + ":" + String(pill.installSeconds % 60).padStart(2, "0") : ""))
                    : (pill.dragStage === "done" ? (pill.installFailed ? "Installed, some failed"
                        : (!pill.installedApp && pill.installKind === "wallpaper" ? "Wallpaper set"
                        : (!pill.installedApp && pill.installKind === "font" ? "Font installed"
                        : (pill.installAction === "updated" ? "Updated"
                        : (pill.installAction === "reinstalled" ? "Reinstalled" : "Installed")))))
                    : "Drop to install")))
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 13 * pill.s
                font.weight: Font.Medium
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: pill.dragStage === "installing" && pill.installLine.length > 0 ? pill.installLine : pill.dragName
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 11 * pill.s
                elide: Text.ElideMiddle
                maximumLineCount: 1
            }
        }
    }

    Item {
        id: rest
        anchors.fill: parent
        opacity: (pill.expanded || pill.dragActive || pill.mode === "toast") ? 0 : Math.pow(pill.morphCloseness, 1.5)
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: pill.mode === "rest" ? Motion.fast : Math.round(260 * Motion.mult) } }

        /**
         * Strip face: one compact pill of media + status hanging from the top
         * edge. Media art and title lead, then a live cava spark, and finally weekday, time, workspace, layout and
         * battery. Sections fold (visualizer, then media) as the width budget
         * tightens; the row is centred so the pill hugs the screen top like a
         * notch. Width is pill.stripFaceW, not the row's implicit width, so the
         * elided title never inflates the pill.
         *
         * The active-workspace number is served by the hover `ws` instance
         * (Phase 4 dedupe): it is always alive, so the number is current the
         * moment this mode is shown, and its `enabled: hover.live` only gates
         * the dot MouseAreas, never its hyprctl watcher.
         */
        Row {
            id: stripFace
            visible: pill.specialView === "" && pill.stripBar
            anchors.centerIn: parent
            spacing: pill.stripGap

            Rectangle {
                id: stripArt
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.stripMedia
                width: pill.stripArtW
                height: pill.stripArtW
                radius: 5 * pill.s
                color: Theme.tileBg
                clip: true
                Image {
                    id: stripArtImg
                    anchors.fill: parent
                    source: Players.artUrl
                    sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                /** No art from the player: the source's own app icon stands in. */
                Image {
                    id: stripArtIcon
                    anchors.centerIn: parent
                    width: parent.width - 8 * pill.s
                    height: parent.height - 8 * pill.s
                    source: Players.appIconFor(Players.active)
                    sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    visible: stripArtImg.status !== Image.Ready && status === Image.Ready
                }
            }

            Text {
                id: stripTitle
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.stripMedia
                text: Players.title
                width: pill.stripTitleW
                elide: Text.ElideRight
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 12.5 * pill.s
                font.weight: Font.Medium
            }

            MusicBars {
                id: stripViz
                anchors.verticalCenter: parent.verticalCenter
                visible: pill.stripMedia && Cava.active
                s: pill.s
                span: 14
            }

            Text {
                id: stripDay
                anchors.verticalCenter: parent.verticalCenter
                text: clock.weekday
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 12 * pill.s
                font.weight: Font.DemiBold
            }
            Text {
                id: stripTime
                anchors.verticalCenter: parent.verticalCenter
                text: clock.hhmm
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 17 * pill.s
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
            Text {
                id: stripWs
                anchors.verticalCenter: parent.verticalCenter
                text: ws.activeWs
                color: Theme.vermLit
                font.family: Theme.font
                font.pixelSize: 12 * pill.s
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
            Text {
                id: stripLay
                anchors.verticalCenter: parent.verticalCenter
                text: kbLayout.code
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 12 * pill.s
                font.weight: Font.DemiBold
            }
            Row {
                id: stripBat
                anchors.verticalCenter: parent.verticalCenter
                visible: Battery.present
                spacing: 4 * pill.s
                GlyphIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Battery.charging
                    width: 11 * pill.s
                    height: 11 * pill.s
                    name: "bolt"
                    color: Battery.low ? Theme.vermLit : Theme.dim
                    stroke: 1.6
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Battery.pct + "%"
                    color: Battery.low ? Theme.vermLit : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * pill.s
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
            }
        }

        TextMetrics {
            id: stripTitleMetrics
            text: Players.title
            font.family: Theme.font
            font.pixelSize: 12.5 * pill.s
            font.weight: Font.Medium
        }

        Row {
            id: restRow
            visible: !pill.stripBar
            anchors.centerIn: parent
            spacing: 9 * pill.s
            Item {
                id: restKanji
                visible: pill.specialView === "" && Flags.mainDisplay === "minimal"
                anchors.verticalCenter: parent.verticalCenter
                width: kanjiFill.implicitWidth
                height: kanjiFill.implicitHeight

                /** Audio leaving the speakers flips the clock glyph over to the live waveform. */
                readonly property bool barsOn: Flags.musicViz && Cava.active

                Text {
                    anchors.fill: parent
                    opacity: (Flags.showGlyphs && !restKanji.barsOn) ? 1 : 0
                    text: kanjiFill.text
                    color: "transparent"
                    font: kanjiFill.font
                    style: Text.Outline
                    styleColor: Qt.alpha(Theme.vermLit,
                        Math.min(1, (pill.mode === "rest" || !pill.hoverSoulGate ? 0.5 : 0) + pill.kanjiFlash))
                    Behavior on opacity { NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard } }
                }

                Text {
                    id: kanjiFill
                    opacity: (Flags.showGlyphs && !restKanji.barsOn) ? 1 : 0
                    text: "時"
                    color: Theme.cream
                    font.family: Theme.fontJp
                    font.weight: Font.Medium
                    font.pixelSize: 15 * pill.s
                    Behavior on opacity { NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard } }
                }

                GlyphIcon {
                    anchors.centerIn: parent
                    opacity: (!Flags.showGlyphs && !restKanji.barsOn) ? 1 : 0
                    width: 17 * pill.s
                    height: 17 * pill.s
                    name: "clock"
                    color: Theme.cream
                    stroke: 1.7
                    Behavior on opacity { NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard } }
                }

                MusicBars {
                    id: musicBars
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: kanjiFill.baseline
                    s: pill.s
                    /** Culled (not just faded) while the waveform is off, so the
                     *  per-bar easing anims don't keep ticking at 60fps invisibly. */
                    visible: restKanji.barsOn
                    opacity: restKanji.barsOn ? 1 : 0
                    scale: restKanji.barsOn ? 1 : 0.7
                    Behavior on opacity { NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard } }
                    Behavior on scale { NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard } }
                }
            }
            Text {
                visible: pill.specialView === "" && Flags.mainDisplay === "minimal"
                anchors.verticalCenter: parent.verticalCenter
                text: clock.hhmm
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 16 * pill.s
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
            Text {
                visible: pill.specialView === "" && Flags.mainDisplay === "classic"
                anchors.verticalCenter: parent.verticalCenter
                text: clock.date
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * pill.s
                font.weight: Font.DemiBold
            }
            Text {
                visible: pill.specialView === "" && Flags.mainDisplay === "classic"
                anchors.verticalCenter: parent.verticalCenter
                text: clock.hhmm
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 16 * pill.s
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
            Text {
                visible: pill.specialView === "" && Flags.mainDisplay === "system"
                anchors.verticalCenter: parent.verticalCenter
                text: clock.weekday
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * pill.s
                font.weight: Font.DemiBold
            }
            Text {
                visible: pill.specialView === "" && Flags.mainDisplay === "system"
                anchors.verticalCenter: parent.verticalCenter
                text: clock.hhmm
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 15 * pill.s
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
            Text {
                visible: pill.specialView === "" && Flags.mainDisplay === "system"
                    && ws.activeWs !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: ws.activeWs
                color: Theme.vermLit
                font.family: Theme.font
                font.pixelSize: 11 * pill.s
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            Text {
                visible: pill.specialView === "" && Flags.mainDisplay === "system"
                anchors.verticalCenter: parent.verticalCenter
                text: kbLayout.code
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * pill.s
                font.weight: Font.DemiBold
            }
            Row {
                visible: pill.specialView === "" && Flags.mainDisplay === "system"
                    && Battery.present
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3 * pill.s
                GlyphIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Battery.charging
                    width: 10 * pill.s
                    height: 10 * pill.s
                    name: "bolt"
                    color: Battery.low ? Theme.vermLit : Theme.dim
                    stroke: 1.6
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Battery.pct + "%"
                    color: Battery.low ? Theme.vermLit : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11 * pill.s
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
            }
            Text {
                visible: pill.specialView !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pill.specialView
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 16 * pill.s
                font.weight: Font.DemiBold
            }
        }
    }

    KbLayout {
        id: kbLayout
    }

    Item {
        id: hover
        anchors.fill: parent
        opacity: pill.mode === "hover" ? Math.pow(pill.morphCloseness, 1.2) : 0
        visible: true
        Behavior on opacity { NumberAnimation { duration: pill.mode === "hover" ? Motion.fast : 40 } }

        readonly property bool live: pill.mode === "hover"

        Row {
            id: hoverRow
            anchors.centerIn: parent
            spacing: 20 * pill.s

            Workspaces {
                id: ws
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                screenName: pill.screenName
                s: pill.s
                gap: 8 * pill.s
                enabled: hover.live
                onHoverIndexChanged: if (hoverIndex >= 0) {
                    pill.soulTarget = "ws";
                    pill.soulWsIndex = hoverIndex;
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 22 * pill.s
                color: Theme.hair
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: hoverClock.implicitWidth
                height: hoverClock.implicitHeight

                Column {
                    id: hoverClock
                    anchors.centerIn: parent
                    spacing: 2 * pill.s
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: clock.hhmm
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 18 * pill.s
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: clock.date
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 8.5 * pill.s
                        font.weight: Font.Medium
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.6 * pill.s
                    }
                }

                MouseArea {
                    anchors.centerIn: parent
                    width: hoverClock.implicitWidth + 22 * pill.s
                    height: hoverClock.implicitHeight + 10 * pill.s
                    enabled: hover.live
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pill.requestSurface("calendar")
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 22 * pill.s
                color: Theme.hair
            }

            Row {
                id: statusRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12 * pill.s

                Item {
                    id: mediaIcon
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pill.hasMedia
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "music"
                        color: mediaArea.containsMouse ? Theme.cream : (Players.playing ? Theme.flameGlow : Theme.iconDim)
                        stroke: 1.7
                    }

                    MouseArea {
                        id: mediaArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("media")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "media"
                    }
                }

                Item {
                    id: weatherGlance
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Weather.ready
                    width: weatherRow.implicitWidth
                    height: weatherRow.implicitHeight

                    Row {
                        id: weatherRow
                        anchors.centerIn: parent
                        spacing: 5 * pill.s

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16 * pill.s
                            height: 16 * pill.s
                            name: Weather.glyphFor(Weather.codeNow, Weather.isDay)
                            color: Theme.subtle
                            stroke: 1.8
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.tempNow + "°"
                            color: Theme.subtle
                            font.family: Theme.font
                            font.pixelSize: 12.5 * pill.s
                            font.weight: Font.Medium
                            font.features: { "tnum": 1 }
                        }
                    }

                    MouseArea {
                        id: weatherArea
                        anchors.centerIn: parent
                        width: weatherRow.implicitWidth + 12 * pill.s
                        height: weatherRow.implicitHeight + 8 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("weather")
                    }
                }

                MinimizedTray {
                    id: minimized
                    anchors.verticalCenter: parent.verticalCenter
                    s: pill.s
                    screenName: pill.screenName
                    enabled: hover.live
                    visible: count > 0
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: minimized.count > 0
                    width: 1
                    height: 14 * pill.s
                    color: Theme.hair
                    opacity: 0.7
                }

                Tray {
                    anchors.verticalCenter: parent.verticalCenter
                    s: pill.s
                    barWindow: pill.barWindow
                    enabled: hover.live
                }

                Item {
                    id: dndIcon
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Flags.dnd
                    width: 16 * pill.s
                    height: 16 * pill.s

                    Shape {
                        id: dndShape

                        width: 16
                        height: 16
                        scale: pill.s
                        transformOrigin: Item.TopLeft
                        x: dndShape.boundingRect.width > 0
                           ? dndIcon.width / 2 - (dndShape.boundingRect.x + dndShape.boundingRect.width / 2) * pill.s
                           : (dndIcon.width - 16 * pill.s) / 2
                        y: dndShape.boundingRect.height > 0
                           ? dndIcon.height / 2 - (dndShape.boundingRect.y + dndShape.boundingRect.height / 2) * pill.s
                           : (dndIcon.height - 16 * pill.s) / 2
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeColor: Theme.vermLit
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            startX: 5.2; startY: 12.2
                            PathLine { x: 12.2; y: 12.2 }
                            PathLine { x: 12.2; y: 7.2 }
                            PathCubic {
                                control1X: 12.2; control1Y: 5.4
                                control2X: 11.2; control2Y: 4.0
                                x: 9.5; y: 3.5
                            }
                        }
                        ShapePath {
                            strokeColor: Theme.vermLit
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 6.8; startY: 13.6
                            PathLine { x: 9.2; y: 13.6 }
                        }
                        ShapePath {
                            strokeColor: Theme.vermLit
                            strokeWidth: 1.6
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 3.2; startY: 2.8
                            PathLine { x: 13.0; y: 13.4 }
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pill.wifiDev !== null || pill.btAdapter !== null || Battery.present
                    spacing: 12 * pill.s

                    Item {
                        id: wifiIcon
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pill.wifiDev !== null
                        width: 15 * pill.s
                        height: 15 * pill.s

                        WifiGlyph {
                            anchors.centerIn: parent
                            s: pill.s
                            level: pill.wifiLevel
                            on: pill.wifiOn
                            stroke: 1.7
                        }

                        MouseArea {
                            id: wifiArea
                            anchors.fill: parent
                            anchors.margins: -6 * pill.s
                            hoverEnabled: true
                            enabled: hover.live
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (e) => {
                                if (e.button === Qt.RightButton) {
                                    if (typeof Networking !== "undefined" && Networking)
                                        Networking.wifiEnabled = !Networking.wifiEnabled;
                                    return;
                                }
                                pill.openUserWifi();
                            }
                            onContainsMouseChanged: if (containsMouse) pill.soulTarget = "wifi"
                        }
                    }

                    Item {
                        id: btIcon
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pill.btAdapter !== null
                        width: 15 * pill.s
                        height: 15 * pill.s

                        GlyphIcon {
                            anchors.fill: parent
                            name: "bluetooth"
                            color: btArea.containsMouse ? Theme.cream
                                : (pill.btOn ? Theme.iconDim : Qt.alpha(Theme.iconDim, 0.4))
                            stroke: 1.7
                        }

                        MouseArea {
                            id: btArea
                            anchors.fill: parent
                            anchors.margins: -6 * pill.s
                            hoverEnabled: true
                            enabled: hover.live
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (e) => {
                                if (e.button === Qt.RightButton) {
                                    if (pill.btAdapter)
                                        pill.btAdapter.enabled = !pill.btAdapter.enabled;
                                    return;
                                }
                                pill.openUserBt();
                            }
                            onContainsMouseChanged: if (containsMouse) pill.soulTarget = "bt"
                        }
                    }

                    Item {
                        id: batteryIcon
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Battery.present
                        width: 17 * pill.s
                        height: 17 * pill.s

                        readonly property color tint: Battery.low ? Theme.vermLit
                            : (Battery.charging ? Theme.flameGlow : (batteryArea.containsMouse ? Theme.cream : Theme.iconDim))

                        GlyphIcon {
                            id: battGlyph
                            anchors.fill: parent
                            name: "battery"
                            color: batteryIcon.tint
                            stroke: 1.7
                        }

                        /** Charge level inside the glyph's body (x 4..17, y 9..15 of its 24-unit grid). */
                        Rectangle {
                            x: 4 * battGlyph.u
                            y: 9 * battGlyph.u
                            width: Math.max(battGlyph.u, 13 * battGlyph.u * Battery.frac)
                            height: 6 * battGlyph.u
                            radius: 0.8 * battGlyph.u
                            color: batteryIcon.tint
                        }

                        MouseArea {
                            id: batteryArea
                            anchors.fill: parent
                            anchors.margins: -6 * pill.s
                            hoverEnabled: true
                            enabled: hover.live
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pill.requestSurface("battery")
                            onContainsMouseChanged: if (containsMouse) pill.soulTarget = "battery"
                        }
                    }
                }

                Item {
                    id: inboxIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "inbox"
                        color: inboxArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    Rectangle {
                        visible: Notifs.unread > 0
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -2 * pill.s
                        anchors.rightMargin: -2 * pill.s
                        width: 5 * pill.s
                        height: 5 * pill.s
                        radius: width / 2
                        color: Theme.flameGlow
                    }

                    MouseArea {
                        id: inboxArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("link")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "inbox"
                    }
                }

                Item {
                    id: mixerIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "mixer"
                        color: mixerArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    MouseArea {
                        id: mixerArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("mixer")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "mixer"
                    }
                }

                Item {
                    id: sysmonIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "monitor"
                        color: sysmonArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    MouseArea {
                        id: sysmonArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("sysmon")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "sysmon"
                    }
                }

                Item {
                    id: wallpaperIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "wallpaper"
                        color: wallpaperArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    MouseArea {
                        id: wallpaperArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.openUserWallpaper()
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "wallpaper"
                    }
                }

                Item {
                    id: clipboardIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "clipboard"
                        color: clipboardArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    MouseArea {
                        id: clipboardArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.openUserClipboard()
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "clipboard"
                    }
                }

                Item {
                    id: appearanceIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "cog"
                        scale: 0.86
                        transformOrigin: Item.Center
                        color: appearanceArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.6
                    }

                    MouseArea {
                        id: appearanceArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("appearance")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "appearance"
                    }
                }

                Item {
                    id: powerIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: 17 * pill.s
                    height: 17 * pill.s

                    GlyphIcon {
                        anchors.fill: parent
                        name: "shutdown"
                        color: powerArea.containsMouse ? Theme.cream : Theme.iconDim
                        stroke: 1.7
                    }

                    MouseArea {
                        id: powerArea
                        anchors.fill: parent
                        anchors.margins: -6 * pill.s
                        hoverEnabled: true
                        enabled: hover.live
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.requestSurface("power")
                        onContainsMouseChanged: if (containsMouse) pill.soulTarget = "power"
                    }
                }
            }
        }
    }

    /**
     * Morphing surfaces, one tail-unloaded Loader each (see surfaceItem). Eager,
     * they dominated startup and per-monitor RAM; now a surface is built
     * synchronously on its first open, kept for one private tiered countdown
     * after it stops being open, then dropped — so nothing is retained for surfaces
     * the user never opens, and closed ones don't linger past their own tail. Each
     * loader fills the pill so the PillSurface inside anchors exactly as it did as a
     * direct child.
     */

    /**
     * Breadcrumb back to whichever surface opened this one: no icon, the word
     * itself is the control. Drawn by the pill rather than PillSurface so a
     * clipping surface (sysmon's gauges) cannot cut it off, and set in the same
     * type as every surface's own header eyebrow so it reads as part of it.
     * Surfaces.pad widens the panel by exactly this much, so nothing overlaps.
     */
    /**
     * Breadcrumb back to whichever surface opened this one: no icon, the word
     * itself is the control. A single Text, not a Row — children with
     * anchors.fill inside a Row are illegal and stop it laying out at all.
     * Drawn by the pill so a clipping surface cannot cut it off, set in the
     * same eyebrow type every surface header uses, and Surfaces.pad widens the
     * panel by exactly this much so nothing overlaps.
     */
    Item {
        id: backBtn
        z: 100
        visible: Surfaces.back.length > 0 && pill.surfaceOpen
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        /* Centred in the band PillSurface leaves above the surface. */
        anchors.topMargin: 9 * pill.s
        width: 16 * pill.s
        height: 16 * pill.s

        GlyphIcon {
            anchors.fill: parent
            name: "home"
            color: backHover.hovered ? Theme.cream : Theme.subtle
            stroke: 1.7
            Behavior on color { ColorAnimation { duration: Motion.fast } }
        }

        HoverHandler { id: backHover }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -7 * pill.s
            cursorShape: Qt.PointingHandCursor
            onClicked: Surfaces.goBack()
        }
    }

    /** The lane is exactly as wide as the breadcrumb, plus a gap. */
    Binding {
        target: Surfaces
        property: "pad"
        value: (Surfaces.back.length > 0 && pill.surfaceOpen)
            ? Math.ceil(backBtn.height / pill.s) + 9 : 0
    }

    Loader {
        id: ldHome
        active: false
        anchors.fill: parent
        sourceComponent: Home {
            s: pill.s
            open: pill.homeOpen
            barWindow: pill.barWindow
            morphCloseness: pill.morphCloseness
            screenName: pill.screenName
            onRequestSurface: (name) => pill.requestSurface(name)
            onRequestClose: pill.requestClose()
        }
    }

    Loader {
        id: ldMixer
        active: false
        anchors.fill: parent
        sourceComponent: Mixer {
            s: pill.s
            open: pill.mixerOpen
            morphCloseness: pill.morphCloseness
        }
    }

    Loader {
        id: ldCalendar
        active: false
        anchors.fill: parent
        sourceComponent: Calendar {
            s: pill.calendarS
            open: pill.calendarOpen
            morphCloseness: pill.morphCloseness
        }
    }

    Loader {
        id: ldWeather
        active: false
        anchors.fill: parent
        sourceComponent: WeatherSurface {
            s: pill.s
            open: pill.weatherOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }




    Loader {
        id: ldPower
        active: false
        anchors.fill: parent
        sourceComponent: Power {
            s: pill.s
            open: pill.powerOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    Loader {
        id: ldMedia
        active: false
        anchors.fill: parent
sourceComponent: Media {
            s: pill.s
            open: pill.mediaOpen
            morphCloseness: pill.morphCloseness
            topFlat: pill.stripBar ? 1 : 0
            pinned: pill.pinned
            onRequestClose: pill.requestClose()
            onRequestPin: pill.forcePinned = !pill.forcePinned
            onRequestExpand: {
                pill.requestClose();
                pill.hoverLatch = true;
                pill.expandLatch = true;
            }
        }
    }

    Loader {
        id: ldLink
        active: false
        anchors.fill: parent
        sourceComponent: Link {
            s: pill.s
            open: pill.linkOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }



    Loader {
        id: ldBattery
        active: false
        anchors.fill: parent
        sourceComponent: BatterySurface {
            s: pill.s
            open: pill.batteryOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    Loader {
        id: ldSysmon
        active: false
        anchors.fill: parent
        sourceComponent: SysmonSurface {
            s: pill.s
            open: pill.sysmonOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    Loader {
        id: ldAppearance
        active: false
        anchors.fill: parent
        sourceComponent: Appearance {
            s: pill.s * pill.settingsScale
            open: pill.appearanceOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: ldDisplay
        active: false
        anchors.fill: parent
        sourceComponent: DisplaySurface {
            s: pill.s * pill.settingsScale
            open: pill.displayOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: ldTheme
        active: false
        anchors.fill: parent
        sourceComponent: ThemeSurface {
            s: pill.s * pill.settingsScale
            open: pill.themeOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: ldInterface
        active: false
        anchors.fill: parent
        sourceComponent: InterfaceSurface {
            s: pill.s * pill.settingsScale
            open: pill.interfaceOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    Loader {
        id: ldFontpicker
        active: false
        anchors.fill: parent
        sourceComponent: FontPicker {
            s: pill.s * pill.settingsScale
            open: pill.fontpickerOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
    }

    /**
     * OSD state controller only. The visible OSD now lives in its own
     * decoupled popup (surfaces/OsdPopup.qml); this instance stays hidden and
     * just feeds the game-mode volume chip and toast-retire logic.
     */
    Osd {
        id: osd
        s: pill.s
        screenName: pill.screenName
        suppressed: pill.surfaceOpen || pill.held
        expanded: pill.expanded
        visible: false
        enabled: false
    }

    Loader {
        id: toastLoader
        active: pill.toastActive
        anchors.fill: parent
        anchors.topMargin: 12 * pill.s
        anchors.leftMargin: 16 * pill.s
        anchors.rightMargin: 16 * pill.s
        anchors.bottomMargin: 12 * pill.s
        enabled: pill.mode === "toast"
        opacity: pill.mode === "toast" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity {
            NumberAnimation { duration: Motion.standard; easing.type: Motion.easeStandard }
        }

        sourceComponent: Item {
            implicitHeight: toastContent.implicitHeight

            Toast {
                id: toastContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                s: pill.s
                live: pill.mode === "toast"
                notif: Notifs.popups.length > 0 ? Notifs.popups[Notifs.popups.length - 1] : null
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                visible: Notifs.popups.length > 1
                text: "+" + (Notifs.popups.length - 1)
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 9 * pill.s
                font.weight: Font.DemiBold
            }
        }
    }

}
