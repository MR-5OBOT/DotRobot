import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import "../../../reusables"
import "../../../"

Rectangle {
    id: sideVolRoot

    property var barWindow
    property bool isSolid: false
    property bool distinctPills: barWindow ? (barWindow.distinctPills !== undefined ? barWindow.distinctPills : false) : false
    property bool moduleActive: true
    property bool isGrouped: false
    property bool isCompact: isGrouped || (isSolid && distinctPills)
    property real targetY: 0
    property bool showLayout: false
    property alias volPill: volBtn

    readonly property real sysVolume: Audio.defaultSink && Audio.defaultSink.audio ? Math.round(Audio.defaultSink.audio.volume * 100) : 0
    readonly property bool isMuted: Audio.defaultSink && Audio.defaultSink.audio ? Audio.defaultSink.audio.muted : false
    property bool isSoundActive: !isMuted && sysVolume > 0

    readonly property bool micMuted: Audio.defaultSource && Audio.defaultSource.audio ? Audio.defaultSource.audio.muted : false
    readonly property real micVolume: Audio.defaultSource && Audio.defaultSource.audio ? Math.round(Audio.defaultSource.audio.volume * 100) : 0

    function sc(v) { return barWindow ? barWindow.s(v) : v; }
    function bump(delta) {
        const node = Audio.defaultSink;
        if (!node || !node.audio)
            return;
        node.audio.muted = false;
        Audio.setVolume(node, Math.round(node.audio.volume * 100) + delta);
    }

    // A track that sets its node's volume on click or drag. `dragging` is lifted
    // out so the popout can hold itself open while the pointer runs off the card.
    component VolSlider: Rectangle {
        id: sl
        property var node: null
        property color fill: ThemeBackend.mauve
        property bool dragging: false
        readonly property real value: node && node.audio ? Math.max(0, Math.min(1, node.audio.volume)) : 0
        readonly property bool nodeMuted: node && node.audio ? node.audio.muted : false

        function setFromX(x) {
            if (!node || !node.audio)
                return;
            node.audio.muted = false;
            Audio.setVolume(node, Math.max(0, Math.min(1, x / width)) * 100);
        }

        implicitWidth: 168
        implicitHeight: 5
        radius: height / 2
        color: ThemeBackend.surface1

        Rectangle {
            width: Math.max(parent.radius * 2, sl.value * parent.width)
            height: parent.height
            radius: parent.radius
            color: sl.nodeMuted ? ThemeBackend.overlay1 : sl.fill
        }

        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -9     // the track is 5px; the grab isn't
            anchors.bottomMargin: -9
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => sl.setFromX(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    sl.setFromX(mouse.x);
            }
            onPressedChanged: sl.dragging = pressed
        }
    }

    property real targetWidth: barWindow ? (isGrouped ? barWindow.barHeight - 8 : ((isSolid && distinctPills) ? barWindow.barHeight - 6 : barWindow.barHeight)) : (isGrouped ? 22 : ((isSolid && distinctPills) ? 24 : 30))
    property real targetHeight: (moduleActive && volBtn.height > 0) ? (volBtn.height + (barWindow ? barWindow.s(isCompact ? 8 : 10) : (isCompact ? 8 : 10))) : 0

    width: targetWidth
    height: targetHeight

    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    x: barWindow ? ((barWindow.baseOffsetX !== undefined ? barWindow.baseOffsetX : 0) + (barWindow.barHeight - width) / 2) : 0
    y: targetY
    Behavior on y {
        enabled: barWindow && barWindow.startupCascadeFinished
        NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
    }

    radius: ThemeBackend.borderRadius
    border.width: 0
    color: isGrouped ? "transparent" : (isSolid ? (distinctPills ? Qt.darker(ThemeBackend.surface0, 1.15) : "transparent") : ThemeBackend.base)
    clip: true

    opacity: (showLayout && moduleActive) ? ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : 1.0) : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Timer {
        running: sideVolRoot.moduleActive && barWindow && barWindow.isStartupReady && barWindow.isDataReady
        interval: 100
        onTriggered: sideVolRoot.showLayout = true
    }

    IconButton {
        id: volBtn
        anchors.centerIn: parent
        width: barWindow ? barWindow.s(sideVolRoot.isCompact ? 28 : 30) : (sideVolRoot.isCompact ? 28 : 30)
        height: barWindow ? barWindow.s(sideVolRoot.isCompact ? 28 : 30) : (sideVolRoot.isCompact ? 28 : 30)
        cornerRadius: Math.max(0, ThemeBackend.borderRadius - (barWindow ? barWindow.s(2) : 2))
        buttonIcon: isMuted || sysVolume === 0 ? "󰖁" : (sysVolume > 50 ? "󰕾" : "󰖀")
        iconFontSize: barWindow ? barWindow.s(sideVolRoot.isCompact ? 14 : 15) : (sideVolRoot.isCompact ? 14 : 15)
        accentColor: sideVolRoot.isSoundActive ? (sideVolRoot.isCompact ? Qt.lighter(ThemeBackend.mauve, 1.08) : ThemeBackend.mauve) : (sideVolRoot.isCompact ? Qt.lighter(ThemeBackend.surface1, 1.12) : ThemeBackend.surface1)
        textColor: sideVolRoot.isSoundActive ? ThemeBackend.base : (sideVolRoot.isCompact ? ThemeBackend.text : ThemeBackend.subtext0)
        onClicked: Quickshell.execDetached(["pavucontrol"])

        // scroll the pill to nudge the output, as the old bar did
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => sideVolRoot.bump(event.angleDelta.y > 0 ? 5 : -5)
        }
    }

    // ---- hover controls ---------------------------------------------------
    // Output and mic, each a mute toggle plus a slider — the old bar's popout.

    PillPopout {
        id: volPop
        anchorItem: volBtn
        host: sideVolRoot.barWindow
        // IconButton drives this off its own MouseArea — the same hover that
        // lightens the pill
        itemHovered: volBtn.isHoveredOrHighlighted && sideVolRoot.showLayout && sideVolRoot.moduleActive

        contentComponent: Component {
            Column {
                spacing: sideVolRoot.sc(11)

                Binding {
                    target: volPop
                    property: "keepOpen"
                    value: outSlider.dragging || micSlider.dragging
                }

                // Output
                Column {
                    spacing: sideVolRoot.sc(6)

                    Row {
                        id: outRow
                        spacing: sideVolRoot.sc(8)

                        Text {
                            id: outIcon
                            anchors.verticalCenter: parent.verticalCenter
                            text: sideVolRoot.isMuted || sideVolRoot.sysVolume === 0 ? "󰖁" : (sideVolRoot.sysVolume > 50 ? "󰕾" : "󰖀")
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: sideVolRoot.sc(15)
                            color: sideVolRoot.isMuted ? ThemeBackend.overlay1 : ThemeBackend.mauve

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -sideVolRoot.sc(4)
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Audio.toggleMute(Audio.defaultSink)
                            }
                        }
                        Text {
                            // the row is pinned to the slider's width, so the
                            // device name takes whatever the glyph and the
                            // percentage leave and elides the rest
                            anchors.verticalCenter: parent.verticalCenter
                            width: outSlider.width - outIcon.width - outPct.width - outRow.spacing * 2
                            elide: Text.ElideRight
                            text: Audio.getNodeName(Audio.defaultSink)
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: sideVolRoot.sc(11.5)
                            color: ThemeBackend.subtext1
                        }
                        Text {
                            id: outPct
                            anchors.verticalCenter: parent.verticalCenter
                            text: sideVolRoot.sysVolume + "%"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: sideVolRoot.sc(11.5)
                            font.bold: true
                            color: sideVolRoot.isMuted ? ThemeBackend.overlay1 : ThemeBackend.text
                        }
                    }

                    VolSlider {
                        id: outSlider
                        node: Audio.defaultSink
                        fill: ThemeBackend.mauve
                    }
                }

                // Microphone
                Column {
                    spacing: sideVolRoot.sc(6)
                    visible: !!Audio.defaultSource

                    Row {
                        id: micRow
                        spacing: sideVolRoot.sc(8)

                        Text {
                            id: micIcon
                            anchors.verticalCenter: parent.verticalCenter
                            text: sideVolRoot.micMuted ? "󰍭" : "󰍬"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: sideVolRoot.sc(15)
                            color: sideVolRoot.micMuted ? ThemeBackend.overlay1 : ThemeBackend.teal

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -sideVolRoot.sc(4)
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Audio.toggleMute(Audio.defaultSource)
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: micSlider.width - micIcon.width - micPct.width - micRow.spacing * 2
                            elide: Text.ElideRight
                            text: Audio.getNodeName(Audio.defaultSource)
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: sideVolRoot.sc(11.5)
                            color: ThemeBackend.subtext1
                        }
                        Text {
                            id: micPct
                            anchors.verticalCenter: parent.verticalCenter
                            text: sideVolRoot.micVolume + "%"
                            font.family: ThemeBackend.fontFamily
                            font.pixelSize: sideVolRoot.sc(11.5)
                            font.bold: true
                            color: sideVolRoot.micMuted ? ThemeBackend.overlay1 : ThemeBackend.text
                        }
                    }

                    VolSlider {
                        id: micSlider
                        node: Audio.defaultSource
                        fill: ThemeBackend.teal
                    }
                }
            }
        }
    }
}
