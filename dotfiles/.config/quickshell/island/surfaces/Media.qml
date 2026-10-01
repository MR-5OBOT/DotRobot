pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../Singletons"
import "../components"

/**
 * Now-playing card, embedded in Home. A square cover on the left; to its right
 * the source line, title, artist·album, the wave seek seam with the loop chip,
 * and the transport (skip, the play/pause seal, skip). Now-playing data comes
 * from [[Players]]; with several players running the source token glows into a
 * bubble that opens a picker. The host draws the card frame.
 */
Item {
    id: root

    property real s: 1
    property bool active: false

    readonly property var player: Players.active
    readonly property bool hasPlayer: player !== null
    readonly property bool playing: Players.playing
    readonly property string title: Players.has && Players.title ? Players.title : "Nothing playing"
    readonly property string artist: Players.artist
    readonly property string album: Players.album
    readonly property bool live: Players.live
    readonly property string serviceLabel: Players.serviceLabel

    /** artist · album, whichever of the two exists */
    readonly property string sub: {
        var parts = [];
        if (root.artist.length > 0) parts.push(root.artist);
        if (root.album.length > 0) parts.push(root.album);
        return parts.join(" · ");
    }

    /** Loop toggle. MprisLoopState walks None -> Track -> Playlist -> None. */
    readonly property bool loopOk: hasPlayer && root.player.loopSupported && root.player.canControl
    readonly property bool loopNone: !hasPlayer || !root.loopOk || root.player.loopState === MprisLoopState.None
    readonly property bool loopTrack: hasPlayer && root.loopOk && root.player.loopState === MprisLoopState.Track
    function nextLoop() {
        if (!root.player)
            return;
        if (root.player.loopState === MprisLoopState.None)
            root.player.loopState = MprisLoopState.Track;
        else if (root.player.loopState === MprisLoopState.Track)
            root.player.loopState = MprisLoopState.Playlist;
        else
            root.player.loopState = MprisLoopState.None;
    }

    /**
     * Art only decodes while Home is open on this monitor, keyed on the track
     * so a browser reusing one file path still reloads on a new song. The shared
     * url means every monitor shows the same cover, never a stale neighbour.
     */
    readonly property string coverSource: {
        if (!root.active)
            return "";
        var u = Players.artUrl;
        if (u)
            return u.indexOf("file:") === 0 ? u + "#" + Players.trackKey : u;
        return Players.appIconFor(root.player);
    }
    /** Latched on first decode so the fallback glyph doesn't flash back while a track change reloads behind the retained cover. */
    property bool everReady: false
    onCoverSourceChanged: if (coverSource.length === 0) everReady = false

    readonly property real lengthSec: Players.lengthSec
    readonly property real positionSec: hasPlayer ? player.position : 0
    readonly property real playFrac: lengthSec > 0 ? Math.max(0, Math.min(1, positionSec / lengthSec)) : 0
    property real dragFrac: 0
    property bool dragging: false
    readonly property real frac: dragging ? dragFrac : playFrac

    /** Source picker is open; only reachable when more than one player runs. */
    property bool picking: false
    readonly property bool canPick: Players.pickable.length > 1
    onCanPickChanged: if (!canPick) picking = false
    onPickingChanged: if (picking) pickFlick.contentX = 0

    /** Card geometry tokens, all scaled to the monitor. */
    readonly property real pad: 12 * s
    readonly property real artSize: 80 * s
    readonly property real artMargin: 14 * s
    readonly property real gapArt: 12 * s
    readonly property real textX: root.artMargin + root.artSize + root.gapArt

    property real sealPulse: 0

    function fmt(sec) {
        if (!(sec > 0))
            return "0:00";
        var t = Math.floor(sec);
        var m = Math.floor(t / 60);
        var ss = t % 60;
        return m + ":" + (ss < 10 ? "0" + ss : ss);
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    onTitleChanged: if (playing && active) pulseAnim.restart()

    Timer {
        interval: 500
        running: root.active && root.playing
        repeat: true
        onTriggered: if (root.player) root.player.positionChanged();
    }

    onActiveChanged: if (!active) picking = false

    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: root; property: "sealPulse"; to: 1; duration: Motion.fast; easing.type: Motion.easeStandard }
        NumberAnimation { target: root; property: "sealPulse"; to: 0; duration: Motion.standard; easing.type: Motion.easeStandard }
    }

    component SkipButton: Item {
        id: skip

        property bool can: false
        property string icon: ""
        signal activated()

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 15 * root.s
        implicitHeight: 15 * root.s
        opacity: skip.can ? 1 : 0.4
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }

        GlyphIcon {
            anchors.centerIn: parent
            width: 14 * root.s
            height: 14 * root.s
            name: skip.icon
            color: skipArea.containsMouse ? Theme.cream : Theme.dim
            Behavior on color { ColorAnimation { duration: Motion.fast } }
        }

        MouseArea {
            id: skipArea
            anchors.fill: parent
            anchors.margins: -7 * root.s
            hoverEnabled: true
            enabled: skip.can
            cursorShape: Qt.PointingHandCursor
            onClicked: skip.activated()
        }
    }

    component ArtDot: ClippingRectangle {
        id: dot
        property string url: ""
        width: 10 * root.s
        height: 10 * root.s
        radius: width / 2
        color: Theme.tileBg
        Image {
            anchors.fill: parent
            source: dot.url
            sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }
    }

    /** Square cover floating detached from every edge. */
    Item {
        id: art
        anchors.left: parent.left
        anchors.leftMargin: root.artMargin
        anchors.verticalCenter: parent.verticalCenter
        width: root.artSize
        height: root.artSize

        ClippingRectangle {
            anchors.fill: parent
            radius: 18 * root.s
            color: Theme.tileBg
            border.width: 1
            border.color: Theme.frameBorder

            Rectangle {
                anchors.fill: parent
                color: Theme.tileBg
                visible: !root.everReady
            }

            Image {
                id: cover
                anchors.fill: parent
                source: root.coverSource
                sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                retainWhileLoading: true
                cache: String(source).indexOf("file:") !== 0
                onStatusChanged: {
                    if (status === Image.Ready)
                        root.everReady = true;
                    else if (status === Image.Error && cover.source !== "")
                        root.everReady = false;
                }
            }
        }

        /** No art yet: a small equalizer while playing, a note glyph otherwise. */
        Item {
            anchors.fill: parent
            visible: !root.everReady

            Row {
                id: eq
                anchors.centerIn: parent
                spacing: 3 * root.s
                visible: root.playing

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        width: 3 * root.s
                        height: 7 * root.s
                        radius: width / 2
                        color: Theme.vermLit

                        SequentialAnimation on height {
                            running: eq.visible && root.playing
                            loops: Animation.Infinite
                            NumberAnimation { to: (6 + index * 3) * root.s; duration: 360 + index * 90; easing.type: Easing.InOutSine }
                            NumberAnimation { to: (12 - index * 2) * root.s; duration: 400 + index * 90; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            GlyphIcon {
                anchors.centerIn: parent
                width: 24 * root.s
                height: 24 * root.s
                name: "music"
                color: Theme.subtle
                visible: !root.playing
            }
        }
    }

    Column {
        id: textCol
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.textX
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        spacing: 3 * root.s

        /** Source line: plain service, or the glowing picker bubble when several players run. */
        Item {
            id: srcHeader
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.picking ? 22 * root.s : 12 * root.s

            readonly property string tail: root.live
                ? " - Live"
                : " / " + root.fmt(root.dragging ? root.dragFrac * root.lengthSec : root.positionSec)
                    + " - " + root.fmt(root.lengthSec)

            Item {
                id: infoRow
                anchors.fill: parent
                visible: opacity > 0.01
                opacity: root.picking ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                Text {
                    id: plainSource
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.canPick && root.serviceLabel.length > 0
                    text: root.serviceLabel
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 8.5 * root.s
                }

                Rectangle {
                    id: srcBubble
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.canPick
                    height: 14 * root.s
                    width: bubbleRow.width + 12 * root.s
                    radius: height / 2
                    color: Qt.alpha(Theme.verm, 0.16)
                    border.width: 1
                    border.color: Qt.alpha(Theme.vermLit, 0.45 + 0.35 * glow)

                    property real glow: 0
                    SequentialAnimation on glow {
                        running: srcBubble.visible && !root.picking
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 1300; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0; duration: 1300; easing.type: Easing.InOutSine }
                    }

                    Row {
                        id: bubbleRow
                        anchors.centerIn: parent
                        spacing: 4 * root.s
                        ArtDot {
                            anchors.verticalCenter: parent.verticalCenter
                            url: Players.artUrlFor(root.player)
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.serviceLabel
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 9 * root.s
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "▾"
                            color: Theme.vermLit
                            font.pixelSize: 7 * root.s
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5 * root.s
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.picking = true
                    }
                }

                Text {
                    anchors.left: root.canPick ? srcBubble.right : plainSource.right
                    anchors.leftMargin: 3 * root.s
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: srcHeader.tail
                    elide: Text.ElideRight
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 8.5 * root.s
                    font.features: { "tnum": 1 }
                }
            }

            Flickable {
                id: pickFlick
                anchors.fill: parent
                clip: true
                visible: opacity > 0.01
                opacity: root.picking ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                contentWidth: pickRow.width
                contentHeight: height
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (e) => {
                        var step = e.angleDelta.y !== 0 ? e.angleDelta.y : e.angleDelta.x;
                        var max = Math.max(0, pickFlick.contentWidth - pickFlick.width);
                        pickFlick.contentX = Math.max(0, Math.min(max, pickFlick.contentX - step));
                    }
                }

                Row {
                    id: pickRow
                    height: pickFlick.height
                    spacing: 7 * root.s

                    Repeater {
                        model: root.picking ? Players.pickable : []
                        delegate: Rectangle {
                            id: bub
                            required property var modelData
                            readonly property bool isActive: modelData === Players.active
                            anchors.verticalCenter: parent.verticalCenter
                            height: 20 * root.s
                            width: bubInner.width + 14 * root.s
                            radius: 8 * root.s
                            color: isActive ? Qt.alpha(Theme.verm, 0.2) : Qt.alpha(Theme.cream, 0.045)
                            border.width: 1
                            border.color: isActive ? Theme.vermLit : Qt.alpha(Theme.cream, 0.12)

                            Row {
                                id: bubInner
                                anchors.centerIn: parent
                                spacing: 5 * root.s
                                ArtDot {
                                    anchors.verticalCenter: parent.verticalCenter
                                    url: Players.artUrlFor(bub.modelData)
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Players.labelOf(bub.modelData)
                                    color: bub.isActive ? Theme.bright : Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: 9 * root.s
                                    font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Players.select(bub.modelData);
                                    root.picking = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        Marquee {
            id: titleLbl
            anchors.left: parent.left
            anchors.right: parent.right
            text: root.title
            color: Theme.cream
            pixelSize: 12.5 * root.s
            weight: Font.DemiBold
            active: root.active
        }

        Marquee {
            id: subLbl
            anchors.left: parent.left
            anchors.right: parent.right
            text: root.sub
            color: Theme.dim
            pixelSize: 9.5 * root.s
            active: root.active
            visible: text.length > 0
        }

        /** Seek row: position, the wave seam, duration, loop toggle. */
        Item {
            id: seekRow
            anchors.left: parent.left
            anchors.right: parent.right
            height: 12 * root.s

            Text {
                id: posLbl
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmt(root.dragging ? root.dragFrac * root.lengthSec : root.positionSec)
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 8.5 * root.s
                font.features: { "tnum": 1 }
            }

            /** Loop chip: Off / Track (single-repeat / Playlist. */
            Item {
                id: loopBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 15 * root.s
                height: 15 * root.s
                visible: root.loopOk
                opacity: root.loopNone ? 0.5 : 1
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                Rectangle {
                    anchors.fill: parent
                    radius: 5 * root.s
                    color: loopArea.containsMouse ? Theme.frameBg : "transparent"
                    border.width: 1
                    border.color: loopArea.containsMouse
                        ? Theme.frameBorder
                        : (root.loopNone ? "transparent" : Qt.alpha(Theme.vermLit, root.loopTrack ? 0.5 : 0.8))
                }

                GlyphIcon {
                    anchors.centerIn: parent
                    width: 11 * root.s
                    height: 11 * root.s
                    name: "refresh"
                    color: root.loopNone ? Theme.dim : Theme.vermLit
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                Rectangle {
                    id: oneBadge
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -2 * root.s
                    anchors.rightMargin: -2 * root.s
                    width: 5 * root.s
                    height: 5 * root.s
                    radius: width / 2
                    color: Theme.vermDeep
                    border.width: 1
                    border.color: Theme.cardTop
                    visible: root.loopTrack
                }

                MouseArea {
                    id: loopArea
                    anchors.fill: parent
                    anchors.margins: -5 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextLoop()
                }
            }

            Text {
                id: durLbl
                anchors.right: loopBtn.visible ? loopBtn.left : parent.right
                anchors.rightMargin: loopBtn.visible ? 7 * root.s : 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmt(root.lengthSec)
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 8.5 * root.s
                font.features: { "tnum": 1 }
            }

            Canvas {
                id: stroke
                anchors.left: posLbl.right
                anchors.leftMargin: 7 * root.s
                anchors.right: durLbl.left
                anchors.rightMargin: 7 * root.s
                anchors.verticalCenter: parent.verticalCenter
                height: 11 * root.s

                readonly property real inset: 3 * root.s
                readonly property real usable: Math.max(1, width - 2 * inset)
                property real targetF: root.frac
                property real lastFrac: 0
                property real drawF: targetF
                readonly property real headX: inset + drawF * usable
                readonly property real headY: waveY(drawF)

                Behavior on drawF {
                    enabled: Math.abs(root.frac - stroke.lastFrac) < 0.02
                    NumberAnimation { duration: Math.round(500 * Motion.mult); easing.type: Easing.Linear }
                }
                onTargetFChanged: Qt.callLater(() => { stroke.lastFrac = root.frac; })

                onDrawFChanged: requestPaint()
                onWidthChanged: requestPaint()
                onVisibleChanged: if (visible) requestPaint()

                function waveY(u) {
                    return height / 2 - 2.6 * Math.sin(3 * Math.PI * u) * Math.exp(-2.5 * u) * root.s;
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    if (width <= 0 || height <= 0)
                        return;
                    const n = 48;
                    ctx.strokeStyle = Theme.border;
                    ctx.lineWidth = 2.5 * root.s;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(inset, waveY(0));
                    for (let i = 1; i <= n; i++)
                        ctx.lineTo(inset + (i / n) * usable, waveY(i / n));
                    ctx.stroke();

                    if (drawF <= 0.002)
                        return;
                    const hTail = 2.5 * root.s;
                    const hHead = 1.75 * root.s;
                    const m = Math.max(2, Math.ceil(n * drawF));
                    ctx.fillStyle = Theme.verm;
                    ctx.beginPath();
                    ctx.arc(inset, waveY(0), hTail, Math.PI / 2, 3 * Math.PI / 2);
                    for (let i = 0; i <= m; i++) {
                        const u = (i / m) * drawF;
                        ctx.lineTo(inset + u * usable, waveY(u) - (hTail + (hHead - hTail) * (i / m)));
                    }
                    ctx.arc(headX, headY, hHead, -Math.PI / 2, Math.PI / 2);
                    for (let i = m; i >= 0; i--) {
                        const u = (i / m) * drawF;
                        ctx.lineTo(inset + u * usable, waveY(u) + (hTail + (hHead - hTail) * (i / m)));
                    }
                    ctx.closePath();
                    ctx.fill();
                }

                MouseArea {
                    id: seekArea
                    anchors.fill: parent
                    anchors.margins: -8 * root.s
                    enabled: root.hasPlayer && root.player.canSeek && root.player.positionSupported && root.lengthSec > 0 && !root.live
                    cursorShape: Qt.PointingHandCursor
                    function fracAt(mx) {
                        return Math.max(0, Math.min(1, (mx - 8 * root.s - stroke.inset) / stroke.usable));
                    }
                    onPressed: (e) => {
                        root.dragFrac = fracAt(e.x);
                        root.dragging = true;
                    }
                    onPositionChanged: (e) => { if (pressed) root.dragFrac = fracAt(e.x); }
                    onReleased: {
                        if (root.player)
                            root.player.position = root.dragFrac * root.lengthSec;
                        root.dragging = false;
                    }
                }
            }
        }

        /** Transport: skip back, the play/pause seal, skip next. */
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12 * root.s
            height: 20 * root.s

            SkipButton {
                icon: "prev"
                can: root.hasPlayer && root.player.canGoPrevious
                onActivated: if (root.player) root.player.previous()
            }

            Rectangle {
                id: seal
                anchors.verticalCenter: parent.verticalCenter
                width: 18 * root.s
                height: 18 * root.s
                radius: 5 * root.s
                rotation: -1.5
                scale: 1 + 0.08 * root.sealPulse

                property real sat: root.playing ? 1 : 0
                Behavior on sat { NumberAnimation { duration: Motion.fast; easing.type: Motion.easeStandard } }

                opacity: (sealArea.enabled ? 1 : 0.4) * (0.75 + 0.25 * sat)
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                border.width: 1
                border.color: Qt.alpha(Theme.vermLit, 0.4 + 0.4 * root.sealPulse)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.mix(Theme.verm, Theme.tileBg, 0.55 - 0.27 * seal.sat) }
                    GradientStop { position: 1.0; color: root.mix(Theme.vermDeep, Theme.tileBg, 0.55 - 0.27 * seal.sat) }
                }

                GlyphIcon {
                    anchors.centerIn: parent
                    width: 11 * root.s
                    height: 11 * root.s
                    name: root.playing ? "pause" : "play"
                    color: Theme.bright
                }

                MouseArea {
                    id: sealArea
                    anchors.fill: parent
                    anchors.margins: -4 * root.s
                    hoverEnabled: true
                    enabled: root.hasPlayer && root.player.canTogglePlaying
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.player) root.player.togglePlaying()
                }
            }

            SkipButton {
                icon: "next"
                can: root.hasPlayer && root.player.canGoNext
                onActivated: if (root.player) root.player.next()
            }
        }
    }
}
