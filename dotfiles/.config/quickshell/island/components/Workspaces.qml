pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../Singletons"

/**
 * Workspace dots for one monitor. No numbers, no icons. Active one is a larger
 * filled vermillion dot; ones holding windows are a deeper flame, empty ones
 * small and dim, brightening on hover.
 * Clicking a dot focuses that workspace (Hyprland workspace dispatcher). Active
 * marker tracks the monitor's live active workspace name.
 *
 * The dot range unions this monitor's workspace rules ([[Workspacerules]]) with
 * the workspaces Hyprland currently has on it, so a rule-driven setup (e.g.
 * monitors.lua splitting 1-5 / 6-10 across two screens) always shows every
 * assigned dot while a workspace outside the rules (r+1 past the last ruled
 * one) still appears instead of vanishing from the strip.
 *
 * The workspace list and active workspace come from the shared hyprctl
 * snapshot in [[Monitors]] (monitors -j / workspaces -j) rather than the
 * Quickshell Hyprland models: on a fresh launch `Hyprland.monitors.values`
 * stays empty, workspace entries carry a null monitor, and `focusedWorkspace`
 * is null — so the dots would only appear after the first switch re-populates
 * the models. Every copy of the dots (hover pill, Home, OSD) reads that one
 * snapshot instead of running its own hyprctl.
 */
Item {
    id: workspaces

    property string screenName: ""
    property real s: 1
    // One size everywhere (hover card and Home header), big enough to hit easily.
    property real stickW: 36 * s
    property real dotW: 14 * s
    property real gap: 12 * s

    /**
     * The dot range and active marker are plain properties, recomputed
     * imperatively by rebuild() from the last hyprctl snapshot rather than
     * chained computed bindings. A switch onto an already-created workspace
     * only changes the active workspace — the list itself stays untouched —
     * so a computed binding could be left empty or stale, which is the "dots
     * missing until the next switch" glitch. rebuild always includes this
     * monitor's active workspace, so the strip never sits empty once the
     * monitor's data is known.
     */
    property var range: []
    property string activeName: ""

    property string activeWs: ""
    property var wsList: []
    /** Workspace id -> true when it holds at least one window. */
    property var occupied: ({})

    /** Pull this monitor's active workspace, workspace list and occupancy from the shared snapshot. */
    function sync() {
        var act = "";
        var mons = Monitors.list;
        for (var m = 0; m < mons.length; m++) {
            if (mons[m] && mons[m].name === workspaces.screenName && mons[m].activeWorkspace)
                act = String(mons[m].activeWorkspace.name);
        }
        var list = [];
        var occ = ({});
        var arr = Monitors.workspaces;
        for (var w = 0; w < arr.length; w++) {
            list.push({ id: arr[w].id, monitor: arr[w].monitor || "" });
            if (arr[w].windows > 0)
                occ[arr[w].id] = true;
        }
        workspaces.occupied = occ;
        workspaces.activeWs = act;
        workspaces.wsList = list;
        workspaces.rebuild();
    }

    function rebuild() {
        var out = [];
        var seen = ({});
        var ruled = Workspacerules.byMonitor[screenName];
        if (ruled && ruled.length) {
            for (var r = 0; r < ruled.length; r++) {
                if (!seen[ruled[r]]) {
                    seen[ruled[r]] = true;
                    out.push(ruled[r]);
                }
            }
        }

        var wss = workspaces.wsList;
        for (var i = 0; i < wss.length; i++) {
            var w = wss[i];
            if (w && w.id >= 1 && w.monitor === screenName && !seen[w.id]) {
                seen[w.id] = true;
                out.push(w.id);
            }
        }
        var a = parseInt(workspaces.activeWs);
        if (a >= 1 && !seen[a])
            out.push(a);
        out.sort(function (x, y) { return x - y; });
        activeName = workspaces.activeWs;
        if (!rangesEqual(range, out))
            range = out;
        if (hoverIndex >= range.length)
            hoverIndex = -1;
    }

    function rangesEqual(a, b) {
        if (a.length !== b.length)
            return false;
        for (var i = 0; i < a.length; i++)
            if (a[i] !== b[i])
                return false;
        return true;
    }

    property int hoverIndex: -1

    readonly property int activeIndex: range.indexOf(parseInt(activeName))

    /**
     * Centre x of a dot slot from target layout widths (active stick is wider).
     * Uses the animation end values, so a focus marker aimed here lands where
     * the dot settles and doesn't chase the width Behavior.
     */
    function slotCenterX(idx) {
        let x = 0;
        for (let i = 0; i < idx; i++)
            x += (i === activeIndex ? stickW : dotW) + gap;
        return x + (idx === activeIndex ? stickW : dotW) / 2;
    }

    readonly property point activeDotPoint: {
        void workspaces.activeName;
        void workspaces.width;
        return Qt.point(slotCenterX(Math.max(0, activeIndex)), height / 2);
    }

    Component.onCompleted: sync()
    onScreenNameChanged: sync()

    Connections {
        target: Monitors
        function onUpdated() { workspaces.sync() }
    }

    Connections {
        target: Workspacerules
        function onByMonitorChanged() { workspaces.rebuild() }
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: workspaces.gap

        Repeater {
            model: workspaces.range

            delegate: Item {
                id: slot

                required property var modelData
                required property int index

                readonly property string wsName: String(modelData)
                readonly property bool isActive: workspaces.activeName === wsName
                readonly property bool isOccupied: !!workspaces.occupied[slot.modelData]

                Layout.preferredWidth: slot.isActive ? workspaces.stickW : workspaces.dotW
                Layout.preferredHeight: 22 * workspaces.s
                Behavior on Layout.preferredWidth { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: workspaces.dotW
                    radius: height / 2
                    /* active: bright pill; has windows: deep flame; empty: dim cream */
                    color: slot.isActive ? Theme.vermLit
                        : (slot.isOccupied ? (area.containsMouse ? Theme.vermLit : Theme.vermDim) : Theme.cream)
                    opacity: slot.isActive || slot.isOccupied ? 1.0 : (area.containsMouse ? 0.7 : 0.3)
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.leftMargin: -workspaces.gap / 2
                    anchors.rightMargin: -workspaces.gap / 2
                    anchors.topMargin: -8 * workspaces.s
                    anchors.bottomMargin: -8 * workspaces.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + slot.wsName + " })")
                    onContainsMouseChanged: {
                        if (containsMouse)
                            workspaces.hoverIndex = slot.index;
                        else if (workspaces.hoverIndex === slot.index)
                            workspaces.hoverIndex = -1;
                    }
                }
            }
        }
    }

    /**
     * Wheel cycles through the dots, wrapping at either end: down/right = next.
     * Touchpads send small deltas, so they are summed into whole notches. The
     * active marker moves ahead of the hyprctl refresh, so fast scrolling steps
     * from where it just went instead of the stale snapshot. Button-less and
     * hover-less, so clicks and dot hovers still reach the slots underneath.
     */
    MouseArea {
        anchors.fill: row
        anchors.topMargin: -8 * workspaces.s
        anchors.bottomMargin: -8 * workspaces.s
        acceptedButtons: Qt.NoButton
        property real acc: 0
        onWheel: (e) => {
            e.accepted = true;
            acc += e.angleDelta.y || e.angleDelta.x;
            var n = workspaces.range.length;
            if (Math.abs(acc) < 120 || n < 2)
                return;
            var next = (Math.max(0, workspaces.activeIndex) + (acc < 0 ? 1 : -1) + n) % n;
            acc = 0;
            workspaces.activeName = String(workspaces.range[next]);
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspaces.range[next] + " })");
        }
    }
}
