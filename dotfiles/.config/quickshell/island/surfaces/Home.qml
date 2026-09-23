pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../Singletons"
import "../components"

/**
 * Home surface: the control centre a click on the notch opens, in place of the
 * thin hover row. A header carrying the surfaces the pill already owns,
 * an identity card over the live wallpaper, the now-playing card, the
 * clock/weather card, and live system vitals.
 *
 * Nothing here owns state. Every nav button routes to a surface that already
 * exists, and the vitals card is the System surface itself on the Sysmon
 * singleton — so this surface is a new arrangement of the shell, never a
 * second source of truth for it.
 */
PillSurface {
    id: root

    mTop: 12
    mLeft: 12
    mRight: 14
    mBottom: 12

    ameForm: "dock"
    amePoint: Qt.point(headRow.x + 13 * root.s, 20 * root.s)

    signal requestSurface(string name)

    /**
     * The pill's own wifi/wallpaper surfaces are superseded by the
     * main shell's panels (see openUserWifi/openUserWallpaper in
     * Pill.qml); the hover row calls those, so the nav buttons must too, or they open
     * a different-looking copy of the same widget.
     */
    function openShellWidget(target, fn) {
        root.requestClose();
        Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
            "qs", "ipc", "call", target, fn]);
    }

    /** Set by the pill so the workspace dots know which monitor they belong to. */
    property string screenName: ""

    /** Set by the pill: the tray's native menus open on this window's screen. */
    property var barWindow: null

    /**
     * Uptime is read directly rather than by holding Sysmon open: that flag arms
     * two 1s pollers that spawn a shell per tick for cpu/mem/net, and
     * this card only shows uptime, which moves once a minute. Since a click on
     * the notch now opens this surface, pinning those pollers would have cost a
     * shell spawn every second for the whole time the panel is up.
     */
    onActiveChanged: if (root.active) root.readIdentity()


    readonly property real gap: 9 * root.s

    // ---- identity ----------------------------------------------------------
    property string userName: ""
    property string hostName: ""
    property string kernel: ""
    property string uptime: ""

    /**
     * Walls.current only fills in after Walls.warm() runs and nothing here asks
     * for it, so the hero was binding to an empty string and showed plain black.
     * The shell persists the live wallpaper to qs-wallpaper (Dyn watches the
     * same file), which is always current.
     */
    property string wallPath: ""

    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/qs-wallpaper"
        watchChanges: true
        printErrors: false
        onLoaded: root.wallPath = text().trim()
        onFileChanged: reload()
    }
    property int idLine: 0

    /**
     * One shot per open: user, host, kernel and uptime in four lines. A Process
     * rather than a FileView because `id -un` is the only honest source for the
     * name and the rest come free in the same call. Re-run on open so uptime is
     * fresh each time, which is far cheaper than holding Sysmon's pollers on.
     */
    function readIdentity() {
        root.idLine = 0;
        idProc.running = true;
    }

    Process {
        id: idProc
        running: true
        command: ["sh", "-c", "id -un; uname -n; uname -r; awk '{print int($1)}' /proc/uptime"]
        stdout: SplitParser {
            onRead: (line) => {
                const t = String(line).trim();
                if (t.length === 0)
                    return;
                if (root.idLine === 0)
                    root.userName = t;
                else if (root.idLine === 1)
                    root.hostName = t;
                else if (root.idLine === 2)
                    root.kernel = t;
                else if (root.idLine === 3)
                    root.uptime = Sysmon.fmtUptime(parseInt(t, 10) || 0);
                root.idLine++;
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string hhmm: Qt.formatDateTime(clock.date, Flags.time12h ? "h:mm AP" : "HH:mm")
    readonly property string dateLine: Qt.formatDateTime(clock.date, "dddd, yyyy-MM-dd")

    // ---- shared leaf components -------------------------------------------

    /** Header nav button: one surface of the pill, lit while it is the open one. */
    component RailBtn: Rectangle {
        id: rb
        required property string glyph
        required property string tip
        property bool current: false
        /** Draw the live charge level inside the glyph, as the hover row does. */
        property bool battery: false
        signal activated()

        width: 26 * root.s
        height: 26 * root.s
        radius: 8 * root.s
        color: rb.current ? Qt.alpha(Theme.onGlow, 0.16)
            : (rbHover.hovered ? Theme.frameBg : "transparent")
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        readonly property color battTint: Battery.low ? Theme.vermLit
            : (Battery.charging ? Theme.flameGlow
            : (rb.current ? Theme.vermLit : (rbHover.hovered ? Theme.cream : Theme.iconDim)))

        GlyphIcon {
            id: rbGlyph
            anchors.centerIn: parent
            width: 17.5 * root.s
            height: 17.5 * root.s
            name: rb.glyph
            color: rb.battery ? rb.battTint
                : (rb.current ? Theme.vermLit : (rbHover.hovered ? Theme.cream : Theme.iconDim))
            stroke: 1.7
            Behavior on color { ColorAnimation { duration: Motion.fast } }

            /* Charge level inside the glyph body: x 4..17, y 9..15 of its
               24-unit grid, the same geometry the pill's hover row uses. */
            Rectangle {
                visible: rb.battery && Battery.present
                x: 4 * rbGlyph.u
                y: 9 * rbGlyph.u
                width: Math.max(rbGlyph.u, 13 * rbGlyph.u * Battery.frac)
                height: 6 * rbGlyph.u
                radius: 0.8 * rbGlyph.u
                color: rb.battTint
                Behavior on width { NumberAnimation { duration: Motion.standard } }
            }
        }

        HoverHandler { id: rbHover }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: rb.activated()
        }
        Tooltip {
            s: root.s
            placement: "below"
            title: rb.tip
            show: rbHover.hovered
        }
    }

    // ---- body --------------------------------------------------------------

    Item {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        // header ------------------------------------------------------------
        Item {
            id: head
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 26 * root.s

            /** Workspace dots — only the workspaces that exist: the same component the pill's hover row uses. */
            Workspaces {
                id: dots
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                screenName: root.screenName
                s: root.s
                /* Dot height follows dotW with radius height/2, so these scale
                   together to keep the circle round and the active pill's
                   proportion; the defaults (8 / 24) are sized for the thin
                   hover row, which is too small for this header. */
                dotW: 12 * root.s
                stickW: 40 * root.s
                gap: 11 * root.s
                enabled: root.active
            }

            /**
             * System tray, right of the dots: every app that registers a
             * StatusNotifier item (OBS, Telegram, Steam...). It used to ride the
             * pill's hover row, which no longer opens, so Home is where it lives.
             * Empty tray = zero width, and nothing shifts.
             */
            Tray {
                anchors.left: dots.right
                anchors.leftMargin: 16 * root.s
                anchors.verticalCenter: parent.verticalCenter
                s: root.s
                barWindow: root.barWindow
                enabled: root.active
            }

            Row {
                id: headRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * root.s

                RailBtn { glyph: "home";      tip: "Home";      current: true }
                RailBtn { glyph: "mixer";     tip: "Mixer";     onActivated: root.requestSurface("mixer") }
                RailBtn { glyph: "calendar";  tip: "Calendar";  onActivated: root.requestSurface("calendar") }
                RailBtn { glyph: "inbox";     tip: "Notifications"; onActivated: root.requestSurface("link") }
                RailBtn { glyph: "wifi";      tip: "Wi-Fi";     onActivated: root.openShellWidget("wifi", "wifiIsland") }
                RailBtn { glyph: "bluetooth"; tip: "Bluetooth"; onActivated: { root.requestClose(); Quickshell.execDetached(["blueman-manager"]); } }
                RailBtn {
                    glyph: "battery"
                    battery: true
                    tip: "Battery"
                    onActivated: root.requestSurface("battery")
                }

                RailBtn {
                    glyph: "cog"
                    tip: "Appearance"
                    onActivated: root.requestSurface("appearance")
                }
                RailBtn {
                    glyph: "shutdown"
                    tip: "Power"
                    onActivated: root.requestSurface("power")
                }
            }
        }

        // identity card over the live wallpaper -------------------------------
        ClippingRectangle {
            id: hero
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: head.bottom
            anchors.topMargin: root.gap
            height: 94 * root.s
            radius: 12 * root.s
            color: Theme.tileBg

            Image {
                anchors.fill: parent
                source: root.wallPath.length > 0 ? "file://" + root.wallPath : ""
                sourceSize: Qt.size(Math.ceil(width * 1.5), Math.ceil(height * 1.5))
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            /** Copy needs its contrast whatever the wallpaper is doing behind it. */
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.92) }
                    GradientStop { position: 0.42; color: Qt.rgba(0, 0, 0, 0.62) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.06) }
                }
            }

            Rectangle {
                id: avatar
                anchors.left: parent.left
                anchors.leftMargin: 14 * root.s
                anchors.verticalCenter: parent.verticalCenter
                width: 56 * root.s
                height: 56 * root.s
                radius: width / 2
                color: "#000000"
                border.width: 2 * root.s
                border.color: Theme.vermLit

                Text {
                    anchors.centerIn: parent
                    text: root.userName.length > 0 ? root.userName.charAt(0).toUpperCase() : "?"
                    color: Theme.vermLit
                    font.family: Theme.font
                    font.pixelSize: 25 * root.s
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }
            }

            Column {
                anchors.left: avatar.right
                anchors.leftMargin: 12 * root.s
                anchors.right: parent.right
                anchors.rightMargin: 12 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1 * root.s

                Text {
                    text: root.userName
                    color: Theme.bright
                    font.family: Theme.font
                    font.pixelSize: 19 * root.s
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }
                Text {
                    text: root.userName + "@" + root.hostName
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    renderType: Text.NativeRendering
                    visible: root.hostName.length > 0
                }
                Text {
                    text: root.uptime
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    font.features: ({ "tnum": 1 })
                    renderType: Text.NativeRendering
                    visible: root.uptime.length > 0
                }
                Text {
                    text: root.kernel
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    renderType: Text.NativeRendering
                    visible: root.kernel.length > 0
                }
            }
        }

        // lower: cards left, system vitals right --------------------------------
        Item {
            id: lower
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: hero.bottom
            anchors.topMargin: root.gap
            anchors.bottom: parent.bottom

            readonly property real colW: (width - root.gap) * 0.48

            // now playing ------------------------------------------------------
            Rectangle {
                id: mediaCard
                anchors.left: parent.left
                anchors.top: parent.top
                width: lower.colW
                height: 118 * root.s
                radius: 12 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.frameBorder

                readonly property real lenSec: Players.lengthSec
                readonly property real posSec: (Players.has && Players.active) ? Players.active.position : 0
                readonly property real frac: lenSec > 0 ? Math.max(0, Math.min(1, posSec / lenSec)) : 0

                function fmt(sec) {
                    if (!(sec > 0))
                        return "0:00";
                    const t2 = Math.floor(sec), m = Math.floor(t2 / 60), ss = t2 % 60;
                    return m + ":" + (ss < 10 ? "0" + ss : ss);
                }

                /** Only while this card is up and actually playing. */
                Timer {
                    interval: 1000
                    repeat: true
                    running: root.active && Players.playing && mediaCard.lenSec > 0
                    onTriggered: mediaCard.posSecChanged()
                }

                ClippingRectangle {
                    id: cover
                    anchors.left: parent.left
                    anchors.leftMargin: 12 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 78 * root.s
                    height: 78 * root.s
                    radius: 14 * root.s
                    color: Theme.ghost

                    Image {
                        anchors.fill: parent
                        source: Players.artUrl
                        sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 26 * root.s
                        height: 26 * root.s
                        name: "music"
                        color: Theme.subtle
                        visible: Players.artUrl.length === 0
                    }
                }

                Column {
                    anchors.left: cover.right
                    anchors.leftMargin: 13 * root.s
                    anchors.right: parent.right
                    anchors.rightMargin: 13 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4 * root.s

                    /** app · elapsed - total, the way the media surface heads it. */
                    Text {
                        width: parent.width
                        text: {
                            const svc = Players.serviceLabel;
                            if (!Players.has)
                                return "";
                            if (Players.live)
                                return svc;
                            return (svc.length > 0 ? svc + "   /   " : "")
                                + mediaCard.fmt(mediaCard.posSec) + " - " + mediaCard.fmt(mediaCard.lenSec);
                        }
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 9.5 * root.s
                        font.features: ({ "tnum": 1 })
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        visible: text.length > 0
                    }

                    Marquee {
                        width: parent.width
                        text: Players.has ? Players.title : "Nothing playing"
                        color: Theme.cream
                        pixelSize: 14 * root.s
                        weight: Font.DemiBold
                        active: root.active
                    }

                    /** elapsed ---- total */
                    Row {
                        width: parent.width
                        spacing: 8 * root.s
                        visible: Players.has && !Players.live && mediaCard.lenSec > 0

                        Text {
                            id: posLbl
                            anchors.verticalCenter: parent.verticalCenter
                            text: mediaCard.fmt(mediaCard.posSec)
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 9 * root.s
                            font.features: ({ "tnum": 1 })
                            renderType: Text.NativeRendering
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, parent.width - posLbl.width - durLbl.width - 16 * root.s)
                            height: 4 * root.s
                            radius: height / 2
                            color: Theme.threadBg

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * mediaCard.frac
                                height: parent.height
                                radius: parent.radius
                                color: Theme.vermLit
                                Behavior on width { NumberAnimation { duration: Motion.standard } }
                            }
                        }

                        Text {
                            id: durLbl
                            anchors.verticalCenter: parent.verticalCenter
                            text: mediaCard.fmt(mediaCard.lenSec)
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 9 * root.s
                            font.features: ({ "tnum": 1 })
                            renderType: Text.NativeRendering
                        }
                    }

                    /** prev · play · next, centred under the track. */
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16 * root.s
                        topPadding: 2 * root.s

                        GlyphIcon {
                            width: 15 * root.s
                            height: 15 * root.s
                            name: "prev-s"
                            color: prevArea.containsMouse ? Theme.cream : Theme.dim
                            stroke: 1.7
                            MouseArea {
                                id: prevArea
                                anchors.fill: parent
                                anchors.margins: -6 * root.s
                                hoverEnabled: true
                                enabled: Players.has
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (Players.active) Players.active.previous()
                            }
                        }

                        Rectangle {
                            width: 24 * root.s
                            height: 24 * root.s
                            radius: width / 2
                            color: Players.playing ? Theme.vermLit : Theme.frameBg
                            border.width: 1
                            border.color: Players.playing ? "transparent" : Theme.border
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            GlyphIcon {
                                anchors.centerIn: parent
                                width: 12 * root.s
                                height: 12 * root.s
                                name: Players.playing ? "pause-s" : "play-s"
                                color: Players.playing ? Theme.cardTop : Theme.cream
                                stroke: 1.8
                            }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4 * root.s
                                enabled: Players.has
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (Players.active) Players.active.togglePlaying()
                            }
                        }

                        GlyphIcon {
                            width: 15 * root.s
                            height: 15 * root.s
                            name: "next-s"
                            color: nextArea.containsMouse ? Theme.cream : Theme.dim
                            stroke: 1.7
                            MouseArea {
                                id: nextArea
                                anchors.fill: parent
                                anchors.margins: -6 * root.s
                                hoverEnabled: true
                                enabled: Players.has
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (Players.active) Players.active.next()
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestSurface("media")
                }
            }

            // clock + weather ----------------------
            Rectangle {
                anchors.left: parent.left
                anchors.right: mediaCard.right
                anchors.top: mediaCard.bottom
                anchors.topMargin: root.gap
                anchors.bottom: parent.bottom
                radius: 12 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.frameBorder

                /* Clock left, outlook right. Stacked vertically the content
                   outgrew the card and spilled past its bottom edge while the
                   right half sat empty; side by side it fits and fills. */

                Column {
                    id: clockCol
                    anchors.left: parent.left
                    anchors.leftMargin: 15 * root.s
                    anchors.top: parent.top
                    anchors.topMargin: 13 * root.s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 13 * root.s
                    width: parent.width * 0.52
                    spacing: 4 * root.s

                    Text {
                        text: root.hhmm
                        color: Theme.vermLit
                        font.family: Theme.font
                        font.pixelSize: 40 * root.s
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        renderType: Text.NativeRendering
                    }

                    Text {
                        width: parent.width
                        text: root.dateLine
                        color: Theme.bright
                        font.family: Theme.font
                        font.pixelSize: 11.5 * root.s
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                    }

                    Row {
                        spacing: 6 * root.s
                        visible: Weather.ready

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 15 * root.s
                            height: 15 * root.s
                            name: Weather.glyphFor(Weather.codeNow, Weather.isDay)
                            color: Theme.subtle
                            stroke: 1.8
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.tempNow + "°C · " + Weather.labelFor(Weather.codeNow)
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 10.5 * root.s
                            renderType: Text.NativeRendering
                        }
                    }

                    Text {
                        width: parent.width
                        text: Weather.city
                        color: Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        elide: Text.ElideRight
                        renderType: Text.NativeRendering
                        visible: Weather.ready && Weather.city.length > 0
                    }
                }

                /** Hairline between the two halves. */
                Rectangle {
                    anchors.left: clockCol.right
                    anchors.leftMargin: 12 * root.s
                    anchors.top: parent.top
                    anchors.topMargin: 16 * root.s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 16 * root.s
                    width: 1
                    color: Theme.hair
                    visible: Weather.ready && Weather.daily.length > 0
                }

                /** Four-day outlook down the right half: day, sky, high. */
                Column {
                    anchors.left: clockCol.right
                    anchors.leftMargin: 25 * root.s
                    anchors.right: parent.right
                    anchors.rightMargin: 14 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7 * root.s
                    visible: Weather.ready && Weather.daily.length > 0

                    Repeater {
                        model: Math.min(4, Weather.daily.length)

                        delegate: Item {
                            required property int index
                            readonly property var d: Weather.daily[index]
                            width: parent.width
                            height: 20 * root.s

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.d ? parent.d.day : ""
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 10 * root.s
                                font.weight: Font.DemiBold
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 0.9 * root.s
                                renderType: Text.NativeRendering
                            }

                            GlyphIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                width: 17 * root.s
                                height: 17 * root.s
                                name: parent.d ? Weather.glyphFor(parent.d.code, true) : "cloud"
                                color: Theme.iconDim
                                stroke: 1.7
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.d ? parent.d.temp + "°" : ""
                                color: Theme.subtle
                                font.family: Theme.font
                                font.pixelSize: 12 * root.s
                                font.weight: Font.DemiBold
                                font.features: ({ "tnum": 1 })
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestSurface("calendar")
                }
            }

            // live system vitals: the System surface itself, minus its header --
            Rectangle {
                anchors.left: mediaCard.right
                anchors.leftMargin: root.gap
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 12 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.frameBorder

                SysmonSurface {
                    embedded: true
                    s: root.s
                    open: root.open
                    morphCloseness: root.morphCloseness
                    mTop: 14
                    mLeft: 12
                    mRight: 12
                    mBottom: 12
                }
            }
        }
    }
}
