import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

// Bar: music glyph (only when a player exists). Hover -> art + controls.
Item {
    id: root
    implicitWidth: parent.width
    implicitHeight: player ? 22 : 0
    visible: !!player

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.playbackState === MprisPlaybackState.Playing) ?? players[0] ?? null
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing

    // position isn't reactive; poll it for the progress bar
    property real pos: 0
    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        onTriggered: root.pos = root.player?.position ?? 0
    }
    onPlayerChanged: pos = player?.position ?? 0

    Icon {
        anchors.centerIn: parent
        size: 16
        color: root.playing ? Theme.pink : Theme.dim
        text: root.playing ? "music_note" : "play_arrow"
    }

    HoverHandler {
        onHoveredChanged: pop.itemHovered = hovered
    }

    Popout {
        id: pop
        anchorItem: root
        contentComponent: Component {
            RowLayout {
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    color: Theme.surface
                    radius: Theme.radius
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Icon {
                        anchors.centerIn: parent
                        visible: !root.player?.trackArtUrl
                        size: 30
                        color: Theme.dim
                        text: "music_note"
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 200
                    spacing: 5

                    Text {
                        Layout.fillWidth: true
                        text: root.player?.trackTitle || "Nothing playing"
                        elide: Text.ElideRight
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.text
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.player?.trackArtist || ""
                        elide: Text.ElideRight
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Theme.dim
                    }

                    // progress
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 2
                        height: 3
                        color: Theme.surface
                        Rectangle {
                            width: parent.width * (root.player?.length ? root.pos / root.player.length : 0)
                            height: parent.height
                            color: Theme.pink
                        }
                    }

                    RowLayout {
                        Layout.topMargin: 2
                        spacing: 18
                        Layout.alignment: Qt.AlignHCenter

                        Icon {
                            size: 18
                            color: Theme.text
                            text: "skip_previous"
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                onClicked: root.player?.previous()
                            }
                        }
                        Icon {
                            size: 22
                            color: Theme.pink
                            text: root.playing ? "pause" : "play_arrow"
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                onClicked: root.player?.togglePlaying()
                            }
                        }
                        Icon {
                            size: 18
                            color: Theme.text
                            text: "skip_next"
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                onClicked: root.player?.next()
                            }
                        }
                    }
                }
            }
        }
    }
}
