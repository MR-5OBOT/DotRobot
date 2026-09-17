pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import "../Singletons"
import "../components"

/**
 * Home surface: the control centre a click on the notch opens, in place of the
 * thin hover row. A left rail of the surfaces the pill already owns, a header,
 * an identity card over the live wallpaper, the now-playing card, the
 * clock/weather card, and a grid of quick actions.
 *
 * Nothing here owns state. Every rail item routes to a surface that already
 * exists, and every tile drives a flag or singleton the island already has
 * (Flags, NightLight, Walls, Cliphist, lock.sh) — so this surface is a new
 * arrangement of the shell, never a second source of truth for it.
 */
PillSurface {
    id: root

    mTop: 12
    mLeft: 12
    mRight: 14
    mBottom: 12

    ameForm: "dock"
    amePoint: Qt.point(23 * root.s, 26 * root.s)

    signal requestSurface(string name)

    /**
     * The pill's own wifi/bluetooth/wallpaper surfaces are superseded by the
     * main shell's panels (see openUserWifi/openUserBt/openUserWallpaper in
     * Pill.qml); the hover row calls those, so the tiles must too, or they open
     * a different-looking copy of the same widget.
     */
    function openShellWidget(target, fn) {
        root.requestClose();
        Quickshell.execDetached(["env", "-u", "QS_CONFIG_PATH", "-u", "QS_CONFIG_NAME", "-u", "QS_MANIFEST",
            "qs", "ipc", "call", target, fn]);
    }

    /** Set by the pill so the workspace dots know which monitor they belong to. */
    property string screenName: ""

    /**
     * Uptime is read directly rather than by holding Sysmon open: that flag arms
     * a 500ms and a 1s poller that spawn a shell per tick for cpu/mem/net, and
     * this card only shows uptime, which moves once a minute. Since a click on
     * the notch now opens this surface, pinning those pollers would have cost a
     * shell spawn every second for the whole time the panel is up.
     */
    onActiveChanged: if (root.active) root.readIdentity()

    /**
     * Radio state for the tile indicators only. The tiles open the real Wi-Fi
     * and Bluetooth surfaces rather than toggling the radios themselves, so the
     * full panels stay the way in.
     */
    readonly property bool wifiOn: (typeof Networking !== "undefined" && Networking) ? Networking.wifiEnabled : false
    readonly property var btAdapter: (typeof Bluetooth !== "undefined" && Bluetooth) ? Bluetooth.defaultAdapter : null
    readonly property bool btOn: root.btAdapter ? root.btAdapter.enabled === true : false

    readonly property real gap: 9 * root.s
    readonly property real railW: 44 * root.s

    // ---- identity ----------------------------------------------------------
    property string userName: ""
    property string hostName: ""
    property string kernel: ""
    property string uptime: ""
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

    /** Rail button: one surface of the pill, lit while it is the open one. */
    component RailBtn: Rectangle {
        id: rb
        required property string glyph
        required property string tip
        property bool current: false
        /** Draw the live charge level inside the glyph, as the hover row does. */
        property bool battery: false
        signal activated()

        width: 34 * root.s
        height: 34 * root.s
        radius: 11 * root.s
        color: rb.current ? Qt.alpha(Theme.onGlow, 0.16)
            : (rbHover.hovered ? Theme.frameBg : "transparent")
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        readonly property color battTint: Battery.low ? Theme.vermLit
            : (Battery.charging ? Theme.flameGlow
            : (rb.current ? Theme.vermLit : (rbHover.hovered ? Theme.cream : Theme.iconDim)))

        GlyphIcon {
            id: rbGlyph
            anchors.centerIn: parent
            width: 20 * root.s
            height: 20 * root.s
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

    /** Header button: settings, power, dismiss. */
    component HeadBtn: Rectangle {
        id: hb
        required property string glyph
        required property string tip
        property bool accent: false
        signal activated()

        width: 26 * root.s
        height: 26 * root.s
        radius: 8 * root.s
        color: hb.accent ? Qt.alpha(Theme.onGlow, 0.18)
            : (hbHover.hovered ? Theme.frameBg : Theme.tileBg)
        border.width: 1
        border.color: hb.accent ? Qt.alpha(Theme.onGlow, 0.5) : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        GlyphIcon {
            anchors.centerIn: parent
            width: 15 * root.s
            height: 15 * root.s
            name: hb.glyph
            color: hb.accent ? Theme.vermLit : (hbHover.hovered ? Theme.cream : Theme.iconDim)
            stroke: 1.7
        }

        HoverHandler { id: hbHover }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: hb.activated()
        }
        Tooltip {
            s: root.s
            placement: "below"
            title: hb.tip
            show: hbHover.hovered
        }
    }

    /**
     * Quick-action tile. `on` is optional: a tile that never sets it reads as a
     * plain action (open a surface, run lock.sh) and never latches.
     */
    component Tile: Rectangle {
        id: tl
        required property string glyph
        required property string label
        property bool on: false
        signal activated()

        radius: 10 * root.s
        color: tl.on ? Qt.alpha(Theme.onGlow, 0.16)
            : (tlHover.hovered ? Theme.frameBg : Theme.tileBg)
        border.width: 1
        border.color: tl.on ? Qt.alpha(Theme.onGlow, 0.45) : Theme.border
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        Column {
            anchors.centerIn: parent
            spacing: 3 * root.s

            GlyphIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 19 * root.s
                height: 19 * root.s
                name: tl.glyph
                color: tl.on ? Theme.vermLit : (tlHover.hovered ? Theme.cream : Theme.iconDim)
                stroke: 1.7
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tl.label
                color: tl.on ? Theme.cream : Theme.subtle
                font.family: Theme.font
                font.pixelSize: 9.5 * root.s
                font.weight: Font.Medium
                renderType: Text.NativeRendering
            }
        }

        HoverHandler { id: tlHover }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tl.activated()
        }
    }

    // ---- left rail ---------------------------------------------------------

    Item {
        id: rail
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.railW

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 2 * root.s
            spacing: 3 * root.s

            RailBtn { glyph: "layers";    tip: "Home";      current: true }
            RailBtn { glyph: "mixer";     tip: "Mixer";     onActivated: root.requestSurface("mixer") }
            RailBtn { glyph: "music";     tip: "Media";     onActivated: root.requestSurface("media") }
            RailBtn { glyph: "clock";     tip: "Calendar";  onActivated: root.requestSurface("calendar") }
            RailBtn { glyph: "cloud";     tip: "Weather";   onActivated: root.requestSurface("weather") }
            RailBtn { glyph: "computer";  tip: "System";    onActivated: root.requestSurface("sysmon") }
            RailBtn { glyph: "inbox";     tip: "Notifications"; onActivated: root.requestSurface("link") }
            RailBtn { glyph: "wifi";      tip: "Wi-Fi";     onActivated: root.requestSurface("wifi") }
            RailBtn { glyph: "bluetooth"; tip: "Bluetooth"; onActivated: root.requestSurface("bt") }
            RailBtn {
                glyph: "battery"
                battery: true
                tip: Battery.present ? Battery.pct + "%  " + Battery.stateLabel : "Battery"
                onActivated: root.requestSurface("battery")
            }
        }
    }

    Rectangle {
        id: railSeam
        anchors.left: rail.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 4 * root.s
        anchors.bottomMargin: 4 * root.s
        width: 1
        color: Theme.hair
    }

    // ---- body --------------------------------------------------------------

    Item {
        id: body
        anchors.left: railSeam.right
        anchors.leftMargin: root.gap + 3 * root.s
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

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Home"
                color: Theme.vermLit
                font.family: Theme.font
                font.pixelSize: 14 * root.s
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
            }

            /** Workspace dots, centred in the header: the same component the pill's hover row uses. */
            Workspaces {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: implicitWidth
                screenName: root.screenName
                s: root.s
                gap: 7 * root.s
                enabled: root.active
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * root.s

                HeadBtn {
                    glyph: "cog"
                    tip: "Appearance"
                    onActivated: root.requestSurface("appearance")
                }
                HeadBtn {
                    glyph: "shutdown"
                    tip: "Power"
                    accent: true
                    onActivated: root.requestSurface("power")
                }
                HeadBtn {
                    glyph: "close"
                    tip: "Close"
                    onActivated: root.requestClose()
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
            height: 78 * root.s
            radius: 12 * root.s
            color: Theme.tileBg

            Image {
                anchors.fill: parent
                source: Walls.current.length > 0 ? "file://" + Walls.current : ""
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
                width: 46 * root.s
                height: 46 * root.s
                radius: width / 2
                color: "#000000"
                border.width: 2 * root.s
                border.color: Theme.vermLit

                Text {
                    anchors.centerIn: parent
                    text: root.userName.length > 0 ? root.userName.charAt(0).toUpperCase() : "?"
                    color: Theme.vermLit
                    font.family: Theme.font
                    font.pixelSize: 20 * root.s
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
                    font.pixelSize: 15 * root.s
                    font.weight: Font.Bold
                    renderType: Text.NativeRendering
                }
                Text {
                    text: root.userName + "@" + root.hostName
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 9.5 * root.s
                    renderType: Text.NativeRendering
                    visible: root.hostName.length > 0
                }
                Text {
                    text: root.uptime
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 9.5 * root.s
                    font.features: ({ "tnum": 1 })
                    renderType: Text.NativeRendering
                    visible: root.uptime.length > 0
                }
                Text {
                    text: root.kernel
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 9.5 * root.s
                    renderType: Text.NativeRendering
                    visible: root.kernel.length > 0
                }
            }
        }

        // lower: cards left, quick actions right --------------------------------
        Item {
            id: lower
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: hero.bottom
            anchors.topMargin: root.gap
            anchors.bottom: parent.bottom

            readonly property real colW: (width - root.gap) * 0.58

            // now playing ------------------------------------------------------
            Rectangle {
                id: mediaCard
                anchors.left: parent.left
                anchors.top: parent.top
                width: lower.colW
                height: 84 * root.s
                radius: 12 * root.s
                color: Theme.tileBg
                border.width: 1
                border.color: Theme.frameBorder

                ClippingRectangle {
                    id: cover
                    anchors.left: parent.left
                    anchors.leftMargin: 10 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 58 * root.s
                    height: 58 * root.s
                    radius: 10 * root.s
                    color: Theme.ghost

                    Image {
                        anchors.fill: parent
                        source: Players.artUrl
                        sourceSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    /** The island's own no-art state: ember bars playing, a note at rest. */
                    Row {
                        anchors.centerIn: parent
                        spacing: 3 * root.s
                        visible: Players.artUrl.length === 0 && Players.playing

                        Repeater {
                            model: 3
                            delegate: Rectangle {
                                required property int index
                                width: 3 * root.s
                                height: 7 * root.s
                                radius: width / 2
                                color: Theme.vermLit

                                SequentialAnimation on height {
                                    /* Gate on the same condition as the parent's `visible`:
                                       with cover art the bars are hidden, and an infinite
                                       animation on an invisible item is pure wasted work. */
                                    running: Players.playing && root.active && Players.artUrl.length === 0
                                    loops: Animation.Infinite
                                    NumberAnimation { to: (6 + index * 3) * root.s; duration: 360 + index * 90; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: (12 - index * 2) * root.s; duration: 400 + index * 90; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 20 * root.s
                        height: 20 * root.s
                        name: "music"
                        color: Theme.subtle
                        visible: Players.artUrl.length === 0 && !Players.playing
                    }
                }

                Column {
                    anchors.left: cover.right
                    anchors.leftMargin: 10 * root.s
                    anchors.right: parent.right
                    anchors.rightMargin: 10 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2 * root.s

                    Marquee {
                        width: parent.width
                        text: Players.has ? Players.title : "Nothing playing"
                        color: Theme.cream
                        pixelSize: 11.5 * root.s
                        weight: Font.DemiBold
                        active: root.active
                    }

                    Marquee {
                        width: parent.width
                        text: Players.artist
                        color: Theme.dim
                        pixelSize: 9 * root.s
                        active: root.active
                        visible: Players.artist.length > 0
                    }

                    Row {
                        spacing: 8 * root.s
                        topPadding: 3 * root.s

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14 * root.s
                            height: 14 * root.s
                            name: "prev-s"
                            color: prevArea.containsMouse ? Theme.cream : Theme.dim
                            stroke: 1.7
                            MouseArea {
                                id: prevArea
                                anchors.fill: parent
                                anchors.margins: -5 * root.s
                                hoverEnabled: true
                                enabled: Players.has
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (Players.active) Players.active.previous()
                            }
                        }

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 15 * root.s
                            height: 15 * root.s
                            name: Players.playing ? "pause-s" : "play-s"
                            color: playArea.containsMouse ? Theme.cream : Theme.vermLit
                            stroke: 1.8
                            MouseArea {
                                id: playArea
                                anchors.fill: parent
                                anchors.margins: -5 * root.s
                                hoverEnabled: true
                                enabled: Players.has
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (Players.active) Players.active.togglePlaying()
                            }
                        }

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14 * root.s
                            height: 14 * root.s
                            name: "next-s"
                            color: nextArea.containsMouse ? Theme.cream : Theme.dim
                            stroke: 1.7
                            MouseArea {
                                id: nextArea
                                anchors.fill: parent
                                anchors.margins: -5 * root.s
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

            // clock + weather, filling what the rail leaves ----------------------
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

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 14 * root.s
                    anchors.right: parent.right
                    anchors.rightMargin: 12 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3 * root.s

                    Text {
                        text: root.hhmm
                        color: Theme.vermLit
                        font.family: Theme.font
                        font.pixelSize: 34 * root.s
                        font.weight: Font.Bold
                        font.features: ({ "tnum": 1 })
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: root.dateLine
                        color: Theme.bright
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    Row {
                        spacing: 5 * root.s
                        visible: Weather.ready

                        GlyphIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14 * root.s
                            height: 14 * root.s
                            name: Weather.glyphFor(Weather.codeNow, Weather.isDay)
                            color: Theme.subtle
                            stroke: 1.8
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.tempNow + "°C · " + Weather.labelFor(Weather.codeNow)
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 9.5 * root.s
                            renderType: Text.NativeRendering
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestSurface("calendar")
                }
            }

            // quick actions ------------------------------------------------------
            Grid {
                id: tiles
                anchors.left: mediaCard.right
                anchors.leftMargin: root.gap
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                columns: 2
                rows: 4
                columnSpacing: root.gap
                rowSpacing: root.gap

                readonly property real cellW: (width - columnSpacing) / 2
                readonly property real cellH: (height - 3 * rowSpacing) / 4

                Tile {
                    width: tiles.cellW; height: tiles.cellH
                    glyph: "wifi"; label: "Wi-Fi"
                    on: root.wifiOn
                    onActivated: root.openShellWidget("wifi", "wifiIsland")
                }
                Tile {
                    width: tiles.cellW; height: tiles.cellH
                    glyph: "bluetooth"; label: "Bluetooth"
                    on: root.btOn
                    onActivated: root.openShellWidget("wifi", "btIsland")
                }
                Tile {
                    width: tiles.cellW; height: tiles.cellH
                    glyph: "dnd"; label: "DND"
                    on: Flags.dnd
                    onActivated: Flags.dnd = !Flags.dnd
                }
                Tile {
                    width: tiles.cellW; height: tiles.cellH
                    glyph: "sun"; label: "Night light"
                    on: Flags.nightLightMode !== "off"
                    onActivated: NightLight.setMode(Flags.nightLightMode === "off" ? "on" : "off")
                }
                Tile {
                    width: tiles.cellW; height: tiles.cellH
                    glyph: "eye-off"; label: "Auto-hide"
                    on: Flags.autoHide
                    onActivated: Flags.autoHide = !Flags.autoHide
                }
                Tile {
                    width: tiles.cellW; height: tiles.cellH
                    glyph: "wallpaper"; label: "Wallpaper"
                    onActivated: root.openShellWidget("wallpicker", "toggle")
                }
                Tile {
                    width: tiles.cellW; height: tiles.cellH
                    glyph: "clipboard"; label: "Clipboard"
                    onActivated: root.requestSurface("clipboard")
                }
                Tile {
                    width: tiles.cellW; height: tiles.cellH
                    glyph: "lock-round"; label: "Lock"
                    onActivated: {
                        root.requestClose();
                        Quickshell.execDetached(["bash", Config.hyprPath("scripts", "lock.sh")]);
                    }
                }
            }
        }
    }
}
