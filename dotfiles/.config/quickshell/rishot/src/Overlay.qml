import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland
import "Singletons"
import "lib/coords.js" as Coords

Item {
    id: overlay
    anchors.fill: parent

    required property var screenData
    property string captureBackend: "screencopy"
    property real captureScale: 1
    property string frozenSource: ""

    /** Whichever frozen source is live, and its readiness, so the effects and
     *  capture timer treat both backends the same. */
    readonly property Item frozenItem: captureBackend === "image" ? frozenPng : frozenWlr
    readonly property bool frozenReady: captureBackend === "image"
        ? frozenPng.status === Image.Ready
        : frozenWlr.hasContent
    onFrozenReadyChanged: if (frozenReady) ready = true

    property var globalSel: null
    property bool capturing: false
    property bool ready: false
    property string phase: ""

    property var model: null
    property var draft: null
    property int annRevision: 0
    property int commitRevision: 0
    property bool textEditing: false
    property var hoverWindow: null

    signal pressedAt(real gx, real gy)
    signal movedTo(real gx, real gy)
    signal hovered(real gx, real gy)
    signal released()
    signal wheelStep(int dir)
    signal captureTimedOut()
    signal textChanged(string t)
    signal textCommitted()
    signal resizeStarted(string role, real gx, real gy)
    signal resizeMoved(real gx, real gy)
    signal resizeEnded()

    readonly property int sx: screenData.x
    readonly property int sy: screenData.y

    readonly property var localSel: globalSel
        ? Coords.intersectRect(globalSel, { x: sx, y: sy, width: width, height: height })
        : null

    readonly property color dimColor: Theme.dim
    readonly property color vermilion: Theme.vermilion

    Item {
        id: scene
        anchors.fill: parent
        opacity: overlay.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        /**
         * The frozen screen image every effect and the export sample from. A ScreencopyView grabs this output directly. The fallback uses a full-desktop PNG
         * from grim and frozenPng shows this output's slice of it (the
         * sourceClipRect in device pixels is the logical geometry times the
         * capture scale). Only one is live per session; both fill the overlay,
         * so blur, loupe and export sample the same coordinates.
         */
        ScreencopyView {
            id: frozenWlr
            anchors.fill: parent
            visible: overlay.captureBackend !== "image"
            captureSource: overlay.captureBackend !== "image" ? overlay.screenData : null
            live: false
            paintCursor: false
        }

        Image {
            id: frozenPng
            anchors.fill: parent
            visible: overlay.captureBackend === "image"
            source: overlay.captureBackend === "image" ? overlay.frozenSource : ""
            sourceClipRect: Qt.rect(overlay.sx * overlay.captureScale,
                                    overlay.sy * overlay.captureScale,
                                    overlay.width * overlay.captureScale,
                                    overlay.height * overlay.captureScale)
            fillMode: Image.Stretch
            cache: false
            smooth: true
            asynchronous: true
            onStatusChanged: {
                if (status === Image.Error) overlay.captureTimedOut();
            }
        }

        function committedOfType(t) {
            var src = overlay.model ? overlay.model.items : [];
            var out = [];
            for (var i = 0; i < src.length; i++)
                if (src[i] && src[i].type === t) out.push(src[i]);
            return out;
        }

        function draftOfType(t) {
            return (overlay.draft && overlay.draft.type === t) ? [overlay.draft] : [];
        }

        Component {
            id: blurDelegate

            Item {
                required property var modelData
                readonly property var a: modelData
                readonly property bool valid: a !== undefined && a !== null && a.points !== undefined && a.points.length >= 2
                readonly property real rx: valid ? Math.min(a.points[0].x, a.points[1].x) - overlay.sx : 0
                readonly property real ry: valid ? Math.min(a.points[0].y, a.points[1].y) - overlay.sy : 0
                readonly property real rw: valid ? Math.abs(a.points[1].x - a.points[0].x) : 0
                readonly property real rh: valid ? Math.abs(a.points[1].y - a.points[0].y) : 0
                x: rx
                y: ry
                width: rw
                height: rh
                visible: valid && rw > 0 && rh > 0
                clip: true

                ShaderEffectSource {
                    id: blurSrc
                    sourceItem: overlay.frozenItem
                    anchors.fill: parent
                    live: false
                    recursive: false
                    sourceRect: Qt.rect(parent.rx, parent.ry, parent.rw, parent.rh)
                    visible: false
                }

                FastBlur {
                    anchors.fill: parent
                    source: blurSrc
                    radius: 64
                }
            }
        }

        Repeater {
            model: { overlay.commitRevision; return scene.committedOfType("blur"); }
            delegate: blurDelegate
        }
        Repeater {
            model: { overlay.annRevision; return scene.draftOfType("blur"); }
            delegate: blurDelegate
        }

        AnnLayer {
            id: annCanvas
            anchors.fill: parent
            sx: overlay.sx
            sy: overlay.sy
            model: overlay.model
            draft: overlay.draft
            revision: overlay.annRevision
            commitRevision: overlay.commitRevision
        }
    }

    Timer {
        id: capTimer
        interval: 50
        repeat: true
        triggeredOnStart: true
        running: overlay.captureBackend !== "image" && !overlay.ready
        property int tries: 0
        onTriggered: {
            tries += 1;
            if (tries > 60) {
                running = false;
                console.warn("rishot: screen capture timed out after 3s, no frame from compositor");
                overlay.captureTimedOut();
            } else {
                frozenWlr.captureFrame();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: overlay.dimColor
        visible: overlay.ready && overlay.localSel === null
        opacity: overlay.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Item {
        anchors.fill: parent
        visible: overlay.ready && overlay.localSel !== null
        opacity: overlay.ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Rectangle {
            color: overlay.dimColor
            x: 0; y: 0; width: parent.width
            height: overlay.localSel ? overlay.localSel.y : 0
        }
        Rectangle {
            color: overlay.dimColor
            x: 0; width: parent.width
            y: overlay.localSel ? overlay.localSel.y + overlay.localSel.h : 0
            height: overlay.localSel ? parent.height - (overlay.localSel.y + overlay.localSel.h) : 0
        }
        Rectangle {
            color: overlay.dimColor
            x: 0
            y: overlay.localSel ? overlay.localSel.y : 0
            width: overlay.localSel ? overlay.localSel.x : 0
            height: overlay.localSel ? overlay.localSel.h : 0
        }
        Rectangle {
            color: overlay.dimColor
            x: overlay.localSel ? overlay.localSel.x + overlay.localSel.w : 0
            y: overlay.localSel ? overlay.localSel.y : 0
            width: overlay.localSel ? parent.width - (overlay.localSel.x + overlay.localSel.w) : 0
            height: overlay.localSel ? overlay.localSel.h : 0
        }
    }

    Item {
        id: chrome
        visible: overlay.ready && overlay.localSel !== null
        x: overlay.localSel ? overlay.localSel.x : 0
        y: overlay.localSel ? overlay.localSel.y : 0
        width: overlay.localSel ? overlay.localSel.w : 0
        height: overlay.localSel ? overlay.localSel.h : 0

        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.985
        transformOrigin: Item.Center
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.4)
            border.width: 1
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: overlay.vermilion
            border.width: 1.5
        }

        Text {
            text: overlay.globalSel
                ? "⛩ rishot · " + Math.round(overlay.globalSel.w) + "×" + Math.round(overlay.globalSel.h)
                : ""
            color: overlay.vermilion
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.7)
            font.family: Theme.monoFamily
            font.pixelSize: 13
            x: 0
            y: -height - 4
        }
    }

    Item {
        id: winHighlight
        readonly property var hw: overlay.hoverWindow
            ? Coords.intersectRect(overlay.hoverWindow, { x: overlay.sx, y: overlay.sy, width: overlay.width, height: overlay.height })
            : null
        visible: overlay.ready && overlay.globalSel === null && hw !== null
        x: hw ? hw.x : 0
        y: hw ? hw.y : 0
        width: hw ? hw.w : 0
        height: hw ? hw.h : 0

        Rectangle {
            anchors.fill: parent
            color: Theme.winFill
            border.color: overlay.vermilion
            border.width: 2.5
            antialiasing: true
        }
    }

    Item {
        id: exportClip
        clip: true
        visible: false
        width: overlay.localSel ? overlay.localSel.w : 0
        height: overlay.localSel ? overlay.localSel.h : 0

        ShaderEffectSource {
            id: exportSrc
            sourceItem: scene
            anchors.fill: parent
            sourceRect: overlay.localSel
                ? Qt.rect(overlay.localSel.x, overlay.localSel.y, overlay.localSel.w, overlay.localSel.h)
                : Qt.rect(0, 0, 0, 0)
            live: false
            recursive: false
        }
    }

    function grabExport(path, cb) {
        if (!overlay.localSel) { cb(false); return; }
        exportSrc.scheduleUpdate();
        var scheduled = exportClip.grabToImage(function (result) {
            var ok = false;
            try { ok = result ? result.saveToFile(path) : false; }
            catch (e) { console.log("rishot: saveToFile failed: " + e); }
            if (cb) cb(ok);
        });
        if (!scheduled && cb) cb(false);
    }

    MouseArea {
        id: drawArea
        anchors.fill: parent
        enabled: overlay.ready
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.CrossCursor
        onPressed: (m) => overlay.pressedAt(m.x + overlay.sx, m.y + overlay.sy)
        onPositionChanged: (m) => {
            if (overlay.capturing) overlay.movedTo(m.x + overlay.sx, m.y + overlay.sy);
            else overlay.hovered(m.x + overlay.sx, m.y + overlay.sy);
        }
        onReleased: overlay.released()
        onWheel: (w) => { if (w.angleDelta.y !== 0) overlay.wheelStep(w.angleDelta.y > 0 ? 1 : -1); w.accepted = true; }
    }

    /**
     * True when the named global edge of the selection lies on this screen
     * rather than being a clip artifact of intersectRect. A handle that drags
     * an off-screen edge would otherwise sit pinned at the monitor seam and,
     * once dragged, collapse that edge onto the seam; gating on the real edge
     * keeps each edge grabbable on exactly one screen.
     *
     * Edge handles ("t", "b", "l", "r") name a single shared edge that can span
     * several monitors. Their handle sits at the global midpoint of that edge,
     * so gating only on edge presence would draw a duplicate, grabbable handle
     * on every monitor the edge crosses. The perpendicular midpoint check below
     * pins each edge handle to the one monitor that actually contains it.
     */
    function edgeOnScreen(role) {
        if (!globalSel) return false;
        var eps = 0.5;
        if (role.indexOf("l") >= 0 && globalSel.x < sx - eps) return false;
        if (role.indexOf("r") >= 0 && globalSel.x + globalSel.w > sx + width + eps) return false;
        if (role.indexOf("t") >= 0 && globalSel.y < sy - eps) return false;
        if (role.indexOf("b") >= 0 && globalSel.y + globalSel.h > sy + height + eps) return false;
        if (role === "t" || role === "b") {
            var mx = globalSel.x + globalSel.w / 2;
            if (mx < sx - eps || mx >= sx + width + eps) return false;
        }
        if (role === "l" || role === "r") {
            var my = globalSel.y + globalSel.h / 2;
            if (my < sy - eps || my >= sy + height + eps) return false;
        }
        return true;
    }

    Item {
        id: resizeHandles
        anchors.fill: parent
        visible: overlay.ready && overlay.phase === "editing" && overlay.localSel !== null

        Repeater {
            model: [
                { role: "tl", ax: 0,   ay: 0,   corner: true,  cur: Qt.SizeFDiagCursor },
                { role: "t",  ax: 0.5, ay: 0,   corner: false, cur: Qt.SizeVerCursor },
                { role: "tr", ax: 1,   ay: 0,   corner: true,  cur: Qt.SizeBDiagCursor },
                { role: "r",  ax: 1,   ay: 0.5, corner: false, cur: Qt.SizeHorCursor },
                { role: "br", ax: 1,   ay: 1,   corner: true,  cur: Qt.SizeFDiagCursor },
                { role: "b",  ax: 0.5, ay: 1,   corner: false, cur: Qt.SizeVerCursor },
                { role: "bl", ax: 0,   ay: 1,   corner: true,  cur: Qt.SizeBDiagCursor },
                { role: "l",  ax: 0,   ay: 0.5, corner: false, cur: Qt.SizeHorCursor }
            ]

            Item {
                id: handle
                required property var modelData
                readonly property real cx: overlay.localSel
                    ? overlay.localSel.x + modelData.ax * overlay.localSel.w : 0
                readonly property real cy: overlay.localSel
                    ? overlay.localSel.y + modelData.ay * overlay.localSel.h : 0
                readonly property real visSize: modelData.corner ? 10 : 8
                readonly property bool real: { overlay.globalSel; return overlay.edgeOnScreen(modelData.role); }

                x: cx - 9
                y: cy - 9
                width: 18
                height: 18
                visible: real

                Rectangle {
                    anchors.centerIn: parent
                    width: handle.visSize
                    height: handle.visSize
                    radius: 1
                    color: overlay.vermilion
                    border.color: Qt.rgba(1, 1, 1, 0.85)
                    border.width: 1
                    antialiasing: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: handle.real
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: handle.modelData.cur
                    onPressed: overlay.resizeStarted(handle.modelData.role,
                        handle.cx + overlay.sx, handle.cy + overlay.sy)
                    onPositionChanged: (m) => {
                        if (pressed) overlay.resizeMoved(m.x + handle.x + overlay.sx,
                                                         m.y + handle.y + overlay.sy);
                    }
                    onReleased: overlay.resizeEnded()
                }
            }
        }
    }

    Item {
        id: loupe
        enabled: false

        readonly property int box: 110
        readonly property real zoom: 8
        readonly property real sampleR: box / (2 * zoom)
        readonly property real margin: 24

        readonly property real cux: drawArea.mouseX
        readonly property real cuy: drawArea.mouseY
        readonly property bool flipX: cux + margin + box > overlay.width
        readonly property bool flipY: cuy + margin + box > overlay.height

        /**
         * Preferred offset places the loupe down-right of the cursor, flipping
         * to up/left near the far edges. The clamp is a floor for the flipped
         * branch: on a monitor narrower or shorter than the loupe plus margins
         * (e.g. a slim portrait secondary) the flipped offset would otherwise
         * run off the near edge. It never moves the loupe on a normally sized
         * screen, where the flip alone already keeps it inside.
         */
        function place(flip, cursor, extent) {
            var pos = flip ? cursor - margin - box : cursor + margin;
            return Math.max(0, Math.min(pos, extent - box));
        }

        width: box
        height: box
        x: place(flipX, cux, overlay.width)
        y: place(flipY, cuy, overlay.height)

        visible: overlay.ready && overlay.phase === "selecting" && drawArea.containsMouse
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Item {
            id: loupeClip
            anchors.fill: parent
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: loupe.box
                    height: loupe.box
                    radius: 12
                    antialiasing: true
                }
            }

            Rectangle {
                anchors.fill: parent
                color: overlay.dimColor
            }

            ShaderEffectSource {
                anchors.fill: parent
                sourceItem: overlay.frozenItem
                live: loupe.visible
                recursive: false
                smooth: false
                sourceRect: Qt.rect(loupe.cux - loupe.sampleR,
                                     loupe.cuy - loupe.sampleR,
                                     loupe.sampleR * 2,
                                     loupe.sampleR * 2)
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0
                width: 1
                height: parent.height
                color: Qt.rgba(overlay.vermilion.r, overlay.vermilion.g, overlay.vermilion.b, 0.7)
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: 0
                height: 1
                width: parent.width
                color: Qt.rgba(overlay.vermilion.r, overlay.vermilion.g, overlay.vermilion.b, 0.7)
            }

            Rectangle {
                anchors.centerIn: parent
                width: loupe.zoom
                height: loupe.zoom
                color: "transparent"
                border.color: overlay.vermilion
                border.width: 1
                antialiasing: true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "transparent"
            border.color: overlay.vermilion
            border.width: 1.5
            antialiasing: true
        }

        Rectangle {
            anchors.horizontalCenter: loupeClip.horizontalCenter
            anchors.top: loupeClip.bottom
            anchors.topMargin: 6
            width: coordText.implicitWidth + 12
            height: coordText.implicitHeight + 6
            radius: 5
            color: Theme.glassBg
            border.color: Theme.glassBorder
            border.width: 1

            Text {
                id: coordText
                anchors.centerIn: parent
                text: Math.round(loupe.cux + overlay.sx) + ", " + Math.round(loupe.cuy + overlay.sy)
                color: overlay.vermilion
                font.family: Theme.monoFamily
                font.pixelSize: 11
            }
        }
    }

    TextInput {
        id: textEdit
        readonly property bool mine: overlay.textEditing && overlay.draft
            && overlay.draft.type === "text" && overlay.localSel !== null
            && (overlay.draft.points[0].x >= overlay.sx) && (overlay.draft.points[0].x < overlay.sx + overlay.width)
            && (overlay.draft.points[0].y >= overlay.sy) && (overlay.draft.points[0].y < overlay.sy + overlay.height)
        visible: mine
        enabled: mine
        x: mine ? overlay.draft.points[0].x - overlay.sx : 0
        y: mine ? overlay.draft.points[0].y - overlay.sy : 0
        color: mine ? overlay.draft.color : "transparent"
        font.family: Theme.sansFamily
        font.pixelSize: mine ? overlay.draft.size : 16
        renderType: Text.NativeRendering
        cursorVisible: mine
        autoScroll: false
        onTextEdited: overlay.textChanged(text)
        onMineChanged: if (mine) { text = overlay.draft.text || ""; forceActiveFocus(); }
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { overlay.textCommitted(); e.accepted = true; }
            else if (e.key === Qt.Key_Escape) { e.accepted = false; }
        }
    }
}
