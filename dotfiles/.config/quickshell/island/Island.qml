import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Singletons"
import "surfaces"

/**
 * The island: one component of the single qs process, loaded by the main
 * quickshell shell.qml. Each monitor carries two layer-shell windows:
 *
 *  - `reserve` is a zero-content strip that only claims an exclusive zone the
 *    height of the rest pill, so tiled windows always sit below the pill even
 *    while it is expanded or a surface is open.
 *  - `overlay` is a full-screen transparent Overlay layer hosting the single
 *    morphing pill anchored at top-centre. The pill never moves windows and is
 *    never re-parented; it just grows in place, so every surface grows out of
 *    the rest pill instead of popping up as a separate panel.
 *
 * Input is routed by the window mask. While the pill is collapsed the mask is
 * the pill rect only, so the rest of the screen clicks through to windows.
 * While the pill is expanded (hovered/pinned) or a surface is open the mask is
 * cleared so the whole layer catches clicks. A backdrop press dismisses, and
 * keyboard focus is taken on demand so Escape closes the open surface.
 */
Scope {
    id: root

    property string openMon: ""
    property string openSurface: ""
    property string peekMon: ""

    /** Where the open surface was reached from, "" when it was opened directly. */
    property string backSurface: ""
    onBackSurfaceChanged: Surfaces.back = root.backSurface

    /**
     * Low/full battery warnings come from ~/.config/hypr/scripts/autostart/
     * battery-notify.sh, which outlives shell restarts; the island owns the
     * notification server, so they arrive here as toasts.
     */
    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    Component.onCompleted: {
        refresh();
        void Events.events;   // singletons load lazily; calendar reminders must run with the calendar closed
        Surfaces.host = root;
    }

    PanelWindow {
        id: inhibitWin
        visible: Flags.keepAwake
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "island-inhibit"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors { top: true; left: true }
        IdleInhibitor { window: inhibitWin; enabled: Flags.keepAwake }
    }

    /**
     * The Wayland IdleInhibitor above only pauses the compositor's own idle
     * (DPMS); hypridle runs its own timer and never sees it, so the lock still
     * fired with keep-awake on. A logind idle inhibitor is the wire hypridle
     * does respect, so hold one for as long as the flag is set.
     */
    Process {
        running: Flags.keepAwake
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Island",
                  "--why=keep awake", "--mode=block", "sleep", "infinity"]
    }

    /**
     * Only these raw events can change what the pill renders (per-monitor
     * active workspace, minimized toplevels, monitor hotplug). Everything
     * else (window drags, resizes, title spam) must not trigger the triple
     * model refresh, which costs three Hyprland IPC round-trips.
     */
    readonly property var refreshEvents: ({
        workspace: true, workspacev2: true,
        createworkspace: true, createworkspacev2: true,
        destroyworkspace: true, destroyworkspacev2: true,
        moveworkspace: true, moveworkspacev2: true,
        renameworkspace: true, activespecial: true,
        focusedmon: true, focusedmonv2: true,
        openwindow: true, closewindow: true,
        movewindow: true, movewindowv2: true,
        fullscreen: true,
        monitoradded: true, monitoraddedv2: true, monitorremoved: true
    })

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (root.refreshEvents[event.name])
                root.refresh();
        }
    }

    /**
     * An empty monitor argument resolves to the focused monitor here, so the
     * keybind scripts skip their hyprctl+jq round trip and a surface open costs
     * one IPC call instead of three process spawns.
     */
    function toggleSurface(mon, surface) {
        if (!mon || mon.length === 0)
            mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        if (root.openMon === mon && root.openSurface === surface) {
            root.close();
            return;
        }
        root.backSurface = "";
        root.openMon = mon;
        root.openSurface = surface;
    }

    /**
     * Surface-to-surface move from inside the island: remember what we left so
     * the chevron can walk it back. Unlike toggleSurface this never closes on a
     * repeat, because it is a navigation, not a toggle.
     */
    function navigate(mon, surface) {
        if (!mon || mon.length === 0)
            mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        root.backSurface = (root.openMon === mon && root.openSurface.length > 0
            && root.openSurface !== surface) ? root.openSurface : "";
        root.openMon = mon;
        root.openSurface = surface;
    }

    function navigateBack() {
        const target = root.backSurface;
        root.backSurface = "";
        if (target.length === 0) {
            root.close();
            return;
        }
        root.openSurface = target;
    }

    function close() {
        root.backSurface = "";
        root.openMon = "";
        root.openSurface = "";
    }

    function peek(mon) {
        root.peekMon = root.peekMon === mon ? "" : mon;
    }

    IpcHandler {
        target: "island"
        function home(mon: string): void { root.toggleSurface(mon, "home"); }
        function mixer(mon: string): void { root.toggleSurface(mon, "mixer"); }
        function calendar(mon: string): void { root.toggleSurface(mon, "calendar"); }
        function launcher(mon: string): void {
            Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
                "qs", "ipc", "call", "launcher", "toggle"]);
        }
        function power(mon: string): void { root.toggleSurface(mon, "power"); }
        function link(mon: string): void { root.toggleSurface(mon, "link"); }
        function battery(mon: string): void { root.toggleSurface(mon, "battery"); }
        function sysmon(mon: string): void { root.toggleSurface(mon, "sysmon"); }
        function system(mon: string): void { root.toggleSurface(mon, "sysmon"); }
        function clipboard(mon: string): void {
            Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
                "qs", "ipc", "call", "clipboard", "toggle"]);
        }
        function wallpaper(mon: string): void {
            Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
                "qs", "ipc", "call", "wallpicker", "toggle"]);
        }
        function media(mon: string): void {
            if (Players.list.length > 0)
                root.toggleSurface(mon, "media");
        }
        function peek(mon: string): void { root.peek(mon); }
        function hide(): void { root.close(); }

        /**
         * Memory saver door: drop every closed surface on every monitor right
         * away, regardless of how much of its 30s tail is left. The open
         * surface is never touched; reopening a dropped surface rebuilds it.
         */
        function unloadAll(): void { Surfaces.unloadClosed(); }

        /** Opens any surface by name, settings sub-pages included; dev and scripting door. */
        function page(mon: string, name: string): void { root.toggleSurface(mon, name); }

        /**
         * Same, but as a navigation: the surface that was open becomes the back
         * target, so the chevron walks back to it. This is the door the island's
         * own rail uses; `page` stays the direct, no-history open.
         */
        function nav(mon: string, name: string): void { root.navigate(mon, name); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: reserve
            required property var modelData
            readonly property real s: modelData ? (modelData.height / 1080) * Flags.uiScale : 1
            readonly property real topGap: 8 * Flags.topGap * s
            /**
             * Reserved-band ceiling with auto-hide off. A full-footprint reserve
             * (hover 58, quick-record 76) cost too much window space, so this is
             * just the resting face plus the transient OSD ring (44): the flashes
             * that actually cover windows (workspace/volume/brightness/record)
             * stay clear, while the cursor-driven hover (58) may still dip past
             * the band by a few pixels.
             */
            readonly property real restFaceH: 44 * s

                        /** Trimming the reserved band below the pill's bottom lets windows climb, so App gap sets the pill-to-window air without touching the desktop gaps_out. The strip face docks flush to the screen top (its own topGap is zero), so it never adds the margin. */
            readonly property real reservedH: Flags.mainDisplay === "strip"
                ? Math.max(0, restFaceH - 12 * (1 - Flags.appGap) * s)
                : Math.max(0, restFaceH + topGap - 12 * (1 - Flags.appGap) * s)


            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: Flags.autoHide ? 0 : reservedH
            aboveWindows: true

            anchors { top: true; left: true; right: true }
            implicitHeight: Flags.autoHide ? 0 : reservedH

            mask: emptyReserve
            Region { id: emptyReserve }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlay
            required property var modelData
            readonly property real s: modelData ? (modelData.height / 1080) * Flags.uiScale : 1
            readonly property real topGap: 8 * Flags.topGap * s
            readonly property string surface: root.openMon === modelData.name ? root.openSurface : ""
            readonly property bool surfaceOpen: surface.length > 0
            readonly property bool modal: surfaceOpen || pill.held || pill.expandLatch

            /**
             * True while this monitor's active workspace reports a fullscreen
             * client. The pill then retracts off the top edge and the whole
             * layer becomes click-through so fullscreen content owns the screen.
             */
            readonly property bool monFullscreen: {
                var mons = Hyprland.monitors.values;
                for (var i = 0; i < mons.length; i++) {
                    if (mons[i].name === modelData.name) {
                        var ws = mons[i].activeWorkspace;
                        var o = ws ? ws.lastIpcObject : null;
                        return o ? !!o.hasfullscreen : false;
                    }
                }
                return false;
            }

            onMonFullscreenChanged: if (monFullscreen) {
                if (root.openMon === modelData.name) root.close();
                if (root.peekMon === modelData.name) root.peekMon = "";
                pill.pinned = false;
                pill.expandLatch = false;
            }

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: surfaceOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "island"

            anchors { top: true; left: true; right: true; bottom: true }

            mask: monFullscreen ? hiddenRegion : (modal ? fullRegion : (Flags.autoHide ? (pill.revealSession || pill.transientLive ? revealPillRegion : (pill.expanded ? pillRegion : revealRegion)) : pillRegion))
            Region { id: hiddenRegion }

            /**
             * The only input left alive while the pill is auto-hidden: a thin
             * top-centre edge strip the pointer can always find. Hovering it
             * slides the pill back in, whether it is resting on a focused
             * monitor or retracted off a non-focused one. Kept to a few pixels
             * so the pill only ever appears when the cursor actually touches the
             * screen edge — passing through the top area deeper down triggers
             * nothing, and (because the strip doubles as the reveal input mask)
             * no invisible click-blocking band lingers below the visible pill.
             */
            Region {
                id: revealRegion
                readonly property real revealW: pill.stripBar ? Math.max(420 * pill.s, pill.stripFaceW) : 420 * pill.s
                readonly property real revealH: 10 * pill.s
                x: Math.max(0, overlay.width / 2 - revealW / 2)
                y: 0
                width: revealW
                height: revealH
            }
            Region {
                id: pillRegion
                readonly property real baseW: Math.max(pill.width, pill.targetW)
                x: pill.x + (pill.width - baseW) / 2
                y: pill.y
                width: baseW
                height: Math.max(pill.height, pill.targetH)
            }

            /**
             * Mask while the pill is being pulled in from the reveal strip. The
             * plain pillRegion alone would flicker: it follows the pill's morphing
             * geometry, so a cursor waiting in the strip below the still-growing
             * pill slips out of the mask, drops the hover, and re-triggers the
             * reveal in a loop. Unioning the fixed strip keeps the cursor covered
             * for the whole pull-in; the pill part grows to catch it on the way up.
             */
            Region {
                id: revealPillRegion
                x: revealRegion.x
                y: revealRegion.y
                width: revealRegion.width
                height: revealRegion.height

                Region {
                    x: pillRegion.x
                    y: pillRegion.y
                    width: pillRegion.width
                    height: pillRegion.height
                }
            }
            Region {
                id: fullRegion
                width: overlay.width
                height: overlay.height
            }

            MouseArea {
                anchors.fill: parent
                enabled: overlay.modal
                acceptedButtons: Qt.AllButtons
                onPressed: (mouse) => {
                    if (overlay.surfaceOpen) {
                        var inside = mouse.x >= pillRegion.x && mouse.x <= pillRegion.x + pillRegion.width
                            && mouse.y >= pillRegion.y && mouse.y <= pillRegion.y + pillRegion.height;
                        if (!inside)
                            root.close();
                        else if (mouse.y <= pillRegion.y + 40 * pill.s)
                            pill.surfaceBack();
                    } else {
                        pill.pinned = false;
                        pill.expandLatch = false;
                        root.peekMon = "";
                    }
                }
            }

            Connections {
                target: Flags
                function onAutoHideChanged() {
                    if (!Flags.autoHide) {
                        pill.revealSession = false;
                        pill.hovered = false;
                        pill.hoverLatch = false;
                    } else {
                        pill.pinned = false;
                    }
                }
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: overlay.surfaceOpen

                /**
                 * Pill hover. While a surface is open the mask covers the whole screen,
                 * so after it closes Qt still holds the pointer's last position and
                 * replays it as a hover even though the pointer is nowhere near the
                 * island; that falsely revealed the pill. Only a point over the strip
                 * or the pill counts.
                 */
                HoverHandler {
                    enabled: !overlay.surfaceOpen && !pill.pinned
                    readonly property point p: point.position
                    function over(r) {
                        return p.x >= r.x && p.x <= r.x + r.width && p.y >= r.y && p.y <= r.y + r.height;
                    }
                    readonly property bool overIsland: hovered && (over(revealRegion) || over(pillRegion))
                    onOverIslandChanged: if (enabled) pill.hovered = overIsland
                }
                Keys.onEscapePressed: root.close()
                Keys.onUpPressed: (e) => {
                    e.accepted = pill.mixerStep(1) || pill.settingsMove(-1);
                }
                Keys.onDownPressed: (e) => {
                    e.accepted = pill.mixerStep(-1) || pill.settingsMove(1);
                }
                Keys.onLeftPressed: (e) => {
                    if (pill.mixerOpen) { pill.mixerFocusMove(-1); e.accepted = true; }
                    else if (pill.powerOpen) { pill.powerMove(-1); e.accepted = true; }
                    else if (pill.settingsLike) { pill.settingsAdjust(-1); e.accepted = true; }
                }
                Keys.onRightPressed: (e) => {
                    if (pill.mixerOpen) { pill.mixerFocusMove(1); e.accepted = true; }
                    else if (pill.powerOpen) { pill.powerMove(1); e.accepted = true; }
                    else if (pill.settingsLike) { pill.settingsAdjust(1); e.accepted = true; }
                }

                /**
                 * Return/Enter/Space: the wallpaper strip applies its focused
                 * thumb on every press; the power surface fires a safe tile on
                 * the first press and, for a destructive tile, holds the heat
                 * fill across autorepeat presses (drained on release). Autorepeat
                 * is swallowed for everything else so a held key never re-fires.
                 */
                Keys.onPressed: (e) => {
                    if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space)
                        return;
                    if (pill.powerOpen) {
                        if (!e.isAutoRepeat) pill.powerPress();
                        e.accepted = true;
                    } else if (pill.settingsLike) {
                        if (!e.isAutoRepeat) pill.settingsActivate();
                        e.accepted = true;
                    }
                }
                Keys.onReleased: (e) => {
                    if (e.isAutoRepeat)
                        return;
                    if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                        && pill.powerOpen) {
                        pill.powerRelease();
                        e.accepted = true;
                    }
                }

                /**
                 * Drag-and-drop gateway for the auto-hidden pill. The reveal
                 * strip keeps its input while the pill is retracted, but drops
                 * are routed to drop targets, not to the passive HoverHandler
                 * that opens the strip — so a hidden pill would never see a
                 * dragged file. This target shadows the strip's geometry, pulls
                 * the pill in on drag enter and hands the drop to the same
                 * wallpaper save flow as the resting pill. Sits below the pill in the
                 * scene so drops on the visible pill itself keep winning.
                 */
                DropArea {
                    id: stripDrop
                    width: pill.stripBar ? Math.max(420 * overlay.s, pill.width) : 420 * overlay.s
                    height: 8 * overlay.s
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    enabled: Flags.autoHide && !pill.surfaceOpen && !pill.dropBusy
                    visible: enabled
                    keys: ["text/uri-list"]
                    onEntered: (drag) => {
                        drag.accepted = pill.dropEntered(drag.urls);
                        pill.revealSession = true;
                    }
                    onExited: {
                        pill.dropExited();
                        pill.revealSession = false;
                    }
                    onDropped: (drop) => {
                        if (pill.dropDropped(drop.urls))
                            drop.accept(Qt.CopyAction);
                        else
                            drop.accepted = false;
                        pill.revealSession = false;
                    }
                }

                Pill {
                    id: pill
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    anchors.horizontalCenter: parent.horizontalCenter

                    Behavior on anchors.topMargin {
                        NumberAnimation {
                            duration: Motion.morph
                            easing.type: Motion.easeMorph
                            easing.bezierCurve: Motion.morphCurve
                        }
                    }
                    s: overlay.s
                    screenName: overlay.modelData.name
                    barWindow: overlay
                    surface: overlay.surface
                    forcePinned: root.peekMon === overlay.modelData.name
                    osdActive: osdPopup.active

                    opacity: (overlay.monFullscreen && !pill.transientLive) ? 0 : (osdPopup.active ? 0 : 1)
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.morph
                            easing.type: Motion.easeMorph
                            easing.bezierCurve: Motion.morphCurve
                        }
                    }
                    transform: Translate {
                        y: ((overlay.monFullscreen && !pill.transientLive) || pill.hidden) ? -(pill.height + overlay.topGap) : 0
                        Behavior on y {
                            NumberAnimation {
                                duration: Motion.morph
                                easing.type: Motion.easeMorph
                                easing.bezierCurve: Motion.morphCurve
                            }
                        }
                    }

                    onRequestSurface: (name) => root.navigate(overlay.modelData.name, name)
                    onRequestClose: root.close()
                }

                OsdPopup {
                    id: osdPopup
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    s: overlay.s
                    screenName: overlay.modelData.name
                    expanded: pill.expanded
                    topFlat: 1
                    suppressed: overlay.surfaceOpen || pill.held || (pill.toastActive && Notifs.toastCritical)
                }
            }

            onSurfaceOpenChanged: if (surfaceOpen) focusScope.forceActiveFocus()

        }
    }
}
