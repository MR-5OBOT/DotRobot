pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
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

    property string prevSurface: ""

    /** How long a closed surface stays built so a quick reopen is instant; 0 = memory saver off, never dropped. */
    readonly property int unloadMs: Flags.memorySaver ? 60000 : 0

    /** The surface on screen: the open one, or the one still sliding away. Its Loader must stay built. */
    readonly property string liveSurface: surface.length > 0 ? surface : retractSurface

    onSurfaceChanged: {
        if (pill.surface.length === 0 && pill.prevSurface.length > 0) {
            pill.retractSurface = pill.prevSurface;
            retractTimer.restart();
        }
        pill.prevSurface = pill.surface;
    }

    /**
     * The surface that just closed. While the pill auto-hides, `mode` keeps its
     * shape so the whole panel slides straight up and out instead of shrinking
     * into the hover card on screen; once the slide is done the pill turns back
     * into the card off-screen.
     */
    property string retractSurface: ""

    Timer {
        id: retractTimer
        interval: Motion.morph + 50 // the hide slide in Island.qml runs Motion.morph
        onTriggered: pill.retractSurface = ""
    }

    Component.onCompleted: if (waveWanted) Cava.viewers++

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
    /** Set by Island.qml while the pill hangs below a widget notch instead of the screen edge: round top corners, no ears. */
    property bool detached: false

    readonly property bool held: pinned || forcePinned
    readonly property bool homeOpen: surface === "home"
    readonly property bool mixerOpen: surface === "mixer"
    readonly property bool calendarOpen: surface === "calendar"
    readonly property bool powerOpen: surface === "power"
    readonly property bool batteryOpen: surface === "battery"
    readonly property bool sysmonOpen: surface === "sysmon"
    readonly property bool displayOpen: surface === "display"
    readonly property bool settingsLike: displayOpen

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

    readonly property bool expanded: surfaceOpen || held || hoverLatch

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
     * True when this pill sits on the monitor Hyprland currently has focused.
     * Only used to drop the cursor latch on focus loss: `hidden` itself is
     * central and does not key off monitor focus, so transient (OSD/toast)
     * appearances retract on their own even on the focused monitor.
     */
    readonly property bool monFocused: Monitors.focusedName === pill.screenName

    /**
     * The pill retracts as soon as this monitor loses focus, even if the
     * cursor is still over the strip or pill: a click only expands the pill
     * temporarily, so focus loss (or cursor exit, via graceTimer) is what
     * releases the latch.
     */
    onMonFocusedChanged: if (!monFocused) {
        revealSession = false;
        hoverLatch = false;
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
    readonly property bool hidden: !revealSession && !expanded && !dragActive
        && !transientLive

    readonly property bool toastActive: Notifs.popups.length > 0
    /** Set by Island.qml from the OSD popup that sits beside the pill. */
    property bool osdActive: false

    /**
     * A transient OSD (workspace switch, volume, brightness) that starts while
     * a non-critical toast is showing retires that toast permanently instead of
     * covering it and letting it reappear — a covered-and-returned toast reads
     * as a second notification. Critical toasts are never covered or retired:
     * the mode ladder gives them priority over the OSD.
     */
    onOsdActiveChanged: if (osdActive && toastActive && !Notifs.toastCritical) Notifs.clearPopups()


    readonly property real hoverPad: 20 * s
    readonly property real hoverW: hoverRow.implicitWidth + 2 * hoverPad
    readonly property real hoverH: 40 * s
    readonly property real calendarS: s * 1.05
    readonly property real homeW: 620 * s
    /* Tall enough for the left column's real content: media card 118 + gap 9 +
       the clock card, whose clock/date/weather/4-day strip needs ~140. At 396
       the clock card got ~107 and its content overflowed up over the media card. */
    readonly property real homeH: 446 * s
    readonly property real mixerH: 214 * s
    readonly property real powerW: 330 * s
    readonly property real powerH: 150 * s
    readonly property real batteryW: 316 * s
    readonly property real sysmonW: 392 * s
    readonly property real settingsScale: 0.9
    readonly property real settingsW: 392 * s * settingsScale
    readonly property real toastW: 342 * s
    readonly property real dragOverW: 300 * s
    readonly property real dragOverH: 126 * s
    readonly property real restCorner: 18 * s
    readonly property real openCorner: 22 * s

    /** A loaded surface's height, 0 while its Loader is still empty (the first open fills it in the same frame). */
    function itemH(ld) { return ld.item ? ld.item.implicitHeight : 0; }

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
        home:     { size: () => Qt.size(homeW, homeH), ame: () => ldHome.item },
        calendar: { size: () => Qt.size((ldCalendar.item && ldCalendar.item.implicitWidth > 0 ? ldCalendar.item.implicitWidth : 282 * calendarS) + 36 * calendarS, itemH(ldCalendar) + 32 * calendarS), ame: () => ldCalendar.item },
        power:    { size: () => Qt.size(powerW, powerH), ame: () => ldPower.item },
        mixer:    { size: () => Qt.size(93 * Math.max(4, ldMixer.item ? ldMixer.item.faderCount : 0) * s, mixerH), ame: () => ldMixer.item },
        battery:  { size: () => Qt.size(batteryW, itemH(ldBattery) + 26 * s), ame: () => ldBattery.item },
        sysmon:   { size: () => Qt.size(sysmonW, itemH(ldSysmon) + 33 * s), ame: () => ldSysmon.item },
        display:  { size: () => Qt.size(settingsW, itemH(ldDisplay) + 29 * s), ame: () => ldDisplay.item }
    })

    /**
     * A surface's Loader: built when it opens, kept for keepMs after it closes,
     * then dropped (keepMs 0 keeps it). Handlers rather than an `active:` binding,
     * so a close can never drop and rebuild it in the gap before the timer starts.
     */
    component SurfaceLoader: Loader {
        id: sl
        required property string name
        required property string live
        required property int keepMs
        readonly property bool shown: live === name
        active: false
        anchors.fill: parent
        onShownChanged: {
            if (shown) {
                tail.stop();
                active = true;
            } else {
                tail.restart();
            }
        }
        onKeepMsChanged: if (!shown && active) tail.restart()   // memory saver turned on: start dropping already-closed ones
        Timer {
            id: tail
            interval: sl.keepMs
            onTriggered: if (!sl.shown && sl.keepMs > 0) sl.active = false
        }
    }

    readonly property string mode: dragActive ? "dragOver"
        : (surfaceOpen && surfaces[surface] !== undefined ? surface
        : (hidden && surfaces[retractSurface] !== undefined ? retractSurface
        // The pill only ever shows while revealed, so it rests as the hover card:
        // reveal and retract slide that card in and out.
        : (toastActive && !held ? "toast" : "hover")))

    /**
     * Wallpaper drop state: hover -> saving -> done, or bad/fail for rejected drops.
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

    /** The open settings surface that owns keyboard row navigation (Display), or null. */
    function rowNavSurface() {
        return pill.displayOpen ? ldDisplay.item : null;
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

    /** The open surface's header bar was clicked: dismiss to the hover pill. Empty space in the body never triggers this. */
    function surfaceBack() {
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
        revealTimer.stop();
    }

    QtObject {
        id: clock
        readonly property var loc: Qt.locale("en_US")
        readonly property var now: sysClock.date
        readonly property string timeFormat: "HH:mm" + (Flags.clockSeconds ? ":ss" : "")
        readonly property string hhmm: Qt.formatTime(now, timeFormat)
        readonly property string date: loc.toString(now, "ddd d MMM")
        readonly property string weekday: loc.toString(now, "ddd")
    }

    SystemClock {
        id: sysClock
        precision: Flags.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    /** Re-enable the clock on wake so it re-reads the wall clock (see Resume). */
    Connections {
        target: Resume
        function onWoke() {
            sysClock.enabled = false;
            sysClock.enabled = true;
        }
    }

    property real morphRadius: mode === "hover" ? restCorner : openCorner

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
        toast: () => Qt.size(toastW, toastLoader.item ? toastLoader.item.implicitHeight + 24 * s : hoverH),
        hover: () => Qt.size(hoverW, hoverH),
        dragOver:    () => Qt.size(dragOverW, dragOverH)
    })

    readonly property size targetSize: {
        const sf = surfaces[mode];
        if (sf) {
            const z = sf.size();
            return Qt.size(z.width, z.height + Surfaces.pad * s);
        }
        return (modeSize[mode] || modeSize.hover)();
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

    onModeChanged: {
        if (mode !== "hover") {
            hoverSoulGate = false;
            soulTarget = "";
            soulWsIndex = -1;
        }
    }

    property string soulTarget: ""
    property int soulWsIndex: -1

    Behavior on width { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }
    Behavior on height { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }
    Behavior on morphRadius { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }

    /**
     * Drop shadow. One SDF quad that follows the body every frame without an
     * offscreen render, so it stays on through morphs (the old MultiEffect
     * layer re-rendered per size step and had to blink off, issue #20). Fades
     * with the auto-hide slide so its blur tail never peeks below the edge.
     */
    RectangularShadow {
        anchors.fill: body
        offset: Qt.vector2d(0, 3 * pill.s)
        blur: 22
        color: Qt.rgba(0, 0, 0, Theme.shadowOpacity)
        topLeftRadius: body.topLeftRadius
        topRightRadius: body.topRightRadius
        bottomLeftRadius: body.bottomLeftRadius
        bottomRightRadius: body.bottomRightRadius
        opacity: pill.hidden ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Motion.morph } }
    }

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
        property real topFlat: pill.detached ? 0 : 1
        Behavior on topFlat { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }

        radius: pill.morphRadius
        topLeftRadius: pill.morphRadius * (1 - topFlat)
        topRightRadius: pill.morphRadius * (1 - topFlat)
        bottomLeftRadius: pill.morphRadius
        bottomRightRadius: pill.morphRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.cardTop }
            GradientStop { position: 1.0; color: Theme.cardBot }
        }
    }

    /** Concave shoulders flaring the docked body into the screen's top edge. */
    NotchEars {
        id: ears
        anchors.top: parent.top
        width: parent.width
        r: 14 * pill.s
        color: Theme.cardTop
        opacity: body.topFlat
    }

    /**
     * Music wave: while something plays, the collapsed notch's whole outline
     * (ears, sides, rounded corners, bottom) swells with Cava's spectrum, traced by an
     * accent line. When auto-hide tucks the notch away only the bottom wave stays
     * behind, hanging from the screen's top edge. Each pill that shows it holds a
     * Cava viewer ref, so cava stops under fullscreen and open surfaces.
     */
    readonly property bool waveWanted: mode === "hover" && opacity > 0
    onWaveWantedChanged: Cava.viewers += waveWanted ? 1 : -1
    Component.onDestruction: if (waveWanted) Cava.viewers--

    Shape {
        id: wave
        readonly property real depth: 16 * pill.s
        // Cancels the hide slide's topGap (same timing as Island's Translate) so the hidden wave lands on the screen edge.
        property real hideShift: pill.hidden && pill.barWindow ? pill.barWindow.topGap : 0
        Behavior on hideShift { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }

        /**
         * Open SVG path pushed outward from the pill's outline by the spectrum
         * (mirrored, so bass sits mid-bottom and highs climb the sides). Shown:
         * screen edge to screen edge round both ears and the whole U, eased flat
         * only where the ears meet the screen edge. Drawn over the ears so they
         * never cover the line.
         * Hidden: just the flat bottom with a sqrt(sin) envelope.
         */
        readonly property string edge: {
            const l = Cava.levels, n = l.length, w = width, h = height, r = pill.morphRadius;
            if (n < 2 || w <= 2 * r) return "";
            const full = !pill.hidden, e = full ? ears.r : 0, ear = Math.PI * e / 2;
            const side = full ? Math.max(0, h - r - e) : 0, arc = full ? Math.PI * r / 2 : 0;
            const L = 2 * ear + 2 * side + 2 * arc + (w - 2 * r);
            const base = (s) => { // [x, y, outward nx, ny, max push] at arc length s along the outline
                if (!full) return [r + s, h, 0, 1];
                // Ears are concave (centre outside the pill): the normal points at the centre, and pushing past it would loop the line.
                if (s < ear) { const a = -Math.PI / 2 + s / e; return [-e + e * Math.cos(a), e + e * Math.sin(a), -Math.cos(a), -Math.sin(a), 0.8 * e]; }
                s -= ear;
                if (s < side) return [0, e + s, -1, 0];
                s -= side;
                if (s < arc) { const a = Math.PI - s / r; return [r + r * Math.cos(a), h - r + r * Math.sin(a), Math.cos(a), Math.sin(a)]; }
                s -= arc;
                if (s < w - 2 * r) return [r + s, h, 0, 1];
                s -= w - 2 * r;
                if (s < arc) { const a = Math.PI / 2 - s / r; return [w - r + r * Math.cos(a), h - r + r * Math.sin(a), Math.cos(a), Math.sin(a)]; }
                s -= arc;
                if (s < side) return [w, h - r - s, 1, 0];
                const a = Math.PI + (s - side) / e;
                return [w + e + e * Math.cos(a), e + e * Math.sin(a), -Math.cos(a), -Math.sin(a), 0.8 * e];
            };
            const m = Math.max(n, Math.round(L / (5 * pill.s)));
            const pts = [];
            for (let i = 0; i <= m; i++) {
                const s = L * i / m, t = i / m, f = t * (n - 1), k = Math.min(n - 2, Math.floor(f));
                const lv = l[k] + (l[k + 1] - l[k]) * (f - k);
                const env = full ? Math.min(1, Math.min(s, L - s) / (6 * pill.s)) : Math.sqrt(Math.sin(Math.PI * t));
                const b = base(s), d = Math.min(lv * depth * env, b[4] ?? Infinity);
                pts.push([b[0] + b[2] * d, b[1] + b[3] * d]);
            }
            // Quadratic curve through the midpoints of the samples.
            let p = `M${pts[0][0]} ${pts[0][1]}`;
            for (let i = 1; i < m; i++)
                p += ` Q${pts[i][0]} ${pts[i][1]} ${(pts[i][0] + pts[i + 1][0]) / 2} ${(pts[i][1] + pts[i + 1][1]) / 2}`;
            return p + ` L${pts[m][0]} ${pts[m][1]}`;
        }
        y: hideShift
        width: body.width
        height: body.height
        visible: pill.waveWanted && edge.length > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            // Closing the shown U along the top fills back over the body, so no seam shows.
            fillColor: Theme.cardBot
            strokeWidth: -1
            PathSvg { path: wave.edge.length ? wave.edge + " Z" : "" }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.vermLit
            strokeWidth: 1.5 * pill.s
            capStyle: ShapePath.RoundCap
            PathSvg { path: wave.edge }
        }
    }

    /**
     * Rest anchor for Ame: where a centred date + time line starts (the hover
     * clock's width). The idle outline condenses into the bead here before it moves.
     */
    readonly property point wakePoint: Qt.point((pill.width - hoverClock.implicitWidth) / 2, pill.height / 2)

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
            // Off while retracted: a visible bead keeps ticking its canvas even off-screen.
            : (pill.mode === "hover" && pill.hoverSoulGate && !pill.hidden ? "soul" : "off")
        point: pill.ameSurface
            ? Qt.point(pill.ameSurface.x + pill.ameSurface.amePoint.x,
                       pill.ameSurface.y + pill.ameSurface.amePoint.y)
            : (pill.mode === "hover" ? pill.soulPoint : pill.wakePoint)
    }

    onHoveredChanged: {
        if (hovered) {
            if (!revealSession && !expanded && !surfaceOpen) {
                revealSession = true;
                revealTimer.stop();
            }
            /* Hover grows the pill into workspaces + clock. A toast owns the
             * pill; latching under it would keep the pill open once the toast
             * is dismissed. */
            if (bootSettled && !toastActive && !surfaceOpen) {
                hoverLatch = true;
                graceTimer.stop();
            }
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
        onTapped: pill.requestSurface("home")
    }

    property var wallpaperQueue: []
    readonly property bool dropBusy: dragStage === "saving" || dragStage === "done"
    readonly property var dropExt: /\.(png|jpe?g|webp|gif|bmp)$/i
    property bool savedAny: false
    property bool saveFailed: false
    property string dropError: ""

    function dropLabel(urls) {
        var path = String(urls.length ? urls[0] : "").split(/[?#]/)[0];
        try { path = decodeURIComponent(path); } catch (e) {}
        return path.substring(path.lastIndexOf("/") + 1);
    }

    function droppablePaths(urls) {
        var out = [];
        for (var i = 0; i < urls.length; i++) {
            var url = String(urls[i]);
            if (/^(file:\/\/|https?:\/\/|\/)/i.test(url) && pill.dropExt.test(pill.dropLabel([url])))
                out.push(url);
        }
        return out;
    }

    function runNextWallpaper() {
        if (pill.wallpaperQueue.length === 0) {
            pill.dragStage = pill.savedAny ? "done" : "fail";
            dropResetTimer.restart();
            return;
        }
        var next = pill.wallpaperQueue.shift();
        pill.dragName = pill.dropLabel([next]);
        wallpaperDropProc.command = ["python3", Config.islandPath("scripts", "wallpaper-drop.py"), next, Config.wallpaperDir];
        wallpaperDropProc.running = true;
    }

    Process {
        id: wallpaperDropProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    pill.dropError = this.text.trim();
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0)
                pill.savedAny = true;
            else
                pill.saveFailed = true;
            pill.runNextWallpaper();
        }
    }

    Timer {
        id: dropResetTimer
        interval: 1800
        onTriggered: {
            pill.dragActive = false;
            pill.dragStage = "";
        }
    }

    // Shared by the resting pill and its auto-hide reveal strip.
    function dropEntered(urls) {
        if (pill.dropBusy)
            return false;
        dropResetTimer.stop();
        pill.dragActive = true;
        pill.dragStage = pill.droppablePaths(urls).length > 0 ? "hover" : "bad";
        pill.dragName = pill.dropLabel(urls);
        pill.dropError = "";
        return true;
    }

    function dropExited() {
        if (pill.dragStage === "hover" || pill.dragStage === "bad") {
            pill.dragActive = false;
            pill.dragStage = "";
        }
    }

    function dropDropped(urls) {
        if (pill.dropBusy)
            return false;
        dropResetTimer.stop();
        var files = pill.droppablePaths(urls);
        pill.dragActive = true;
        pill.dropError = "";
        if (files.length === 0) {
            pill.dragStage = "bad";
            pill.dragName = pill.dropLabel(urls);
            dropResetTimer.restart();
            return false;
        }
        pill.dragStage = "saving";
        pill.savedAny = false;
        pill.saveFailed = false;
        pill.wallpaperQueue = files;
        pill.runNextWallpaper();
        return true;
    }

    DropArea {
        anchors.fill: parent
        enabled: !pill.surfaceOpen && !pill.dropBusy
        keys: ["text/uri-list"]
        onEntered: (drag) => {
            drag.accepted = pill.dropEntered(drag.urls);
        }
        onExited: pill.dropExited()
        onDropped: (drop) => {
            if (pill.dropDropped(drop.urls))
                drop.accept(Qt.CopyAction);
            else
                drop.accepted = false;
        }
    }

    /**
     * Drop-zone face: corner brackets frame a stage glyph and label that walk
     * from "drop to save wallpaper" through the spinner to a checkmark. Shares the morph
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
                        : (pill.dragStage === "saving" ? "reboot"
                        : (pill.dragStage === "done" ? "check" : "download"))

                    RotationAnimation on rotation {
                        running: pill.dragStage === "saving"
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                    onNameChanged: if (pill.dragStage !== "saving") rotation = 0
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: pill.dragStage === "bad" ? "Wallpapers only"
                    : (pill.dragStage === "fail" ? "Couldn't save wallpaper"
                    : (pill.dragStage === "saving" ? "Saving wallpaper…"
                    : (pill.dragStage === "done" ? (pill.saveFailed ? "Saved; some failed" : "Saved to wallpapers")
                    : "Drop to save wallpaper")))
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 13 * pill.s
                font.weight: Font.Medium
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: (pill.dragStage === "fail" || (pill.dragStage === "done" && pill.saveFailed)) && pill.dropError.length > 0
                    ? pill.dropError : pill.dragName
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 11 * pill.s
                elide: Text.ElideMiddle
                maximumLineCount: 1
            }
        }
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

                Row {
                    id: hoverClock
                    anchors.centerIn: parent
                    spacing: 9 * pill.s
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: clock.date
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 11 * pill.s
                        font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: clock.hhmm
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 16 * pill.s
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                    }
                }
                // No click of its own: a click here falls through to the pill's TapHandler and opens Home.
            }
        }
    }

    /**
     * Morphing surfaces, one SurfaceLoader each: nothing is built for a surface
     * you never open, and a closed one is dropped after unloadMs. Each loader
     * fills the pill so the PillSurface inside anchors as a direct child would.
     */

    /**
     * Back button to whichever surface opened this one. Drawn by the pill rather
     * than PillSurface so a clipping surface (sysmon's gauges) cannot cut it off;
     * Surfaces.pad widens the panel by exactly this much, so nothing overlaps.
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

    SurfaceLoader {
        id: ldHome
        name: "home"
        live: pill.liveSurface
        keepMs: pill.unloadMs
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

    SurfaceLoader {
        id: ldMixer
        name: "mixer"
        live: pill.liveSurface
        keepMs: pill.unloadMs
        sourceComponent: Mixer {
            s: pill.s
            open: pill.mixerOpen
            morphCloseness: pill.morphCloseness
        }
    }

    SurfaceLoader {
        id: ldCalendar
        name: "calendar"
        live: pill.liveSurface
        keepMs: pill.unloadMs
        sourceComponent: Calendar {
            s: pill.calendarS
            open: pill.calendarOpen
            morphCloseness: pill.morphCloseness
        }
    }

    SurfaceLoader {
        id: ldPower
        name: "power"
        live: pill.liveSurface
        keepMs: pill.unloadMs
        sourceComponent: Power {
            s: pill.s
            open: pill.powerOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    SurfaceLoader {
        id: ldBattery
        name: "battery"
        live: pill.liveSurface
        keepMs: pill.unloadMs
        sourceComponent: BatterySurface {
            s: pill.s
            open: pill.batteryOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    SurfaceLoader {
        id: ldSysmon
        name: "sysmon"
        live: pill.liveSurface
        keepMs: pill.unloadMs
        sourceComponent: SysmonSurface {
            s: pill.s
            open: pill.sysmonOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
        }
    }

    SurfaceLoader {
        id: ldDisplay
        name: "display"
        live: pill.liveSurface
        keepMs: pill.unloadMs
        sourceComponent: DisplaySurface {
            s: pill.s * pill.settingsScale
            open: pill.displayOpen
            morphCloseness: pill.morphCloseness
            onRequestClose: pill.requestClose()
            onRequestSurface: (name) => pill.requestSurface(name)
        }
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
