import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

// Bar: speaker glyph. Scroll to adjust. Hover -> output + mic sliders.
Item {
    id: root
    implicitWidth: parent.width
    implicitHeight: 22

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    function setSink(f) {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, f));
        }
    }

    function setSource(f) {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1, f));
        }
    }

    function bump(delta) {
        setSink(vol + delta);
    }

    Icon {
        anchors.centerIn: parent
        size: 17
        color: root.muted ? Theme.dim : Theme.text
        text: root.muted ? "volume_off" : (root.vol < 0.01 ? "volume_mute" : root.vol < 0.5 ? "volume_down" : "volume_up")
    }

    HoverHandler {
        onHoveredChanged: pop.itemHovered = hovered
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton && root.sink?.audio)
                root.sink.audio.muted = !root.muted;
            else
                Quickshell.execDetached(["pavucontrol"]);
        }
        onWheel: wheel => root.bump(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
    }

    Popout {
        id: pop
        anchorItem: root
        contentComponent: Component {
            ColumnLayout {
                spacing: 12

                // Output
                RowLayout {
                    spacing: 10
                    Icon {
                        size: 17
                        color: Theme.text
                        text: root.muted ? "volume_off" : "volume_up"
                    }
                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: (root.sink?.description ?? "Output").slice(0, 26)
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: Theme.text
                        }
                        Rectangle {
                            Layout.preferredWidth: 180
                            height: 4
                            color: Theme.surface
                            Rectangle {
                                width: parent.width * root.vol
                                height: parent.height
                                color: Theme.pink
                            }
                            MouseArea {  // drag/click to set; invisible taller hit area
                                anchors.fill: parent
                                anchors.topMargin: -8
                                anchors.bottomMargin: -8
                                onPressed: mouse => root.setSink(mouse.x / width)
                                onPositionChanged: mouse => {
                                    if (pressed)
                                        root.setSink(mouse.x / width);
                                }
                            }
                        }
                    }
                    Text {
                        text: Math.round(root.vol * 100) + "%"
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Theme.dim
                    }
                }

                // Input / mic
                RowLayout {
                    spacing: 10
                    visible: !!root.source
                    Icon {
                        size: 17
                        color: Theme.text
                        text: (root.source?.audio?.muted ?? false) ? "mic_off" : "mic"
                    }
                    Rectangle {
                        Layout.preferredWidth: 180
                        height: 4
                        color: Theme.surface
                        Rectangle {
                            width: parent.width * (root.source?.audio?.volume ?? 0)
                            height: parent.height
                            color: Theme.pinkDim
                        }
                        MouseArea {  // drag/click to set; invisible taller hit area
                            anchors.fill: parent
                            anchors.topMargin: -8
                            anchors.bottomMargin: -8
                            onPressed: mouse => root.setSource(mouse.x / width)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    root.setSource(mouse.x / width);
                            }
                        }
                    }
                    Text {
                        text: Math.round((root.source?.audio?.volume ?? 0) * 100) + "%"
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Theme.dim
                    }
                }
            }
        }
    }
}
