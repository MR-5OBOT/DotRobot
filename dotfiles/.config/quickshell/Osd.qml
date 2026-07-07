import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Volume / brightness OSD island: icon + progress bar that rises from the
// bottom when a level changes, then auto-hides. Triggered by the control
// scripts and reads the current level itself (qs 0.3.0 ipc call takes no
// arguments):  qs ipc call osd volume | mic | brightness
PanelWindow {
    id: osd

    property bool shown: false
    property string kind: "volume"   // volume | muted | mic | mic-muted | brightness
    property int value: 0

    function reveal(k, v) {
        kind = k;
        value = Math.max(0, Math.min(100, v));
        shown = true;
        hideTimer.restart();
    }

    IpcHandler {
        target: "osd"
        function volume(): void { volReader.running = true; }
        function mic(): void { micReader.running = true; }
        function brightness(): void { briReader.running = true; }
    }
    Timer { id: hideTimer; interval: 1200; onTriggered: osd.shown = false }

    // readers: "<muted> <volume>" for audio, a bare percent for brightness.
    // rapid key-spam converges — an in-flight read reflects the latest state.
    Process {
        id: volReader
        command: ["sh", "-c", "echo $(pamixer --get-mute) $(pamixer --get-volume)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = text.trim().split(/\s+/);
                osd.reveal(o[0] === "true" ? "muted" : "volume", parseInt(o[1]) || 0);
            }
        }
    }
    Process {
        id: micReader
        command: ["sh", "-c", "echo $(pamixer --default-source --get-mute) $(pamixer --default-source --get-volume)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = text.trim().split(/\s+/);
                osd.reveal(o[0] === "true" ? "mic-muted" : "mic", parseInt(o[1]) || 0);
            }
        }
    }
    Process {
        id: briReader
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: osd.reveal("brightness", parseInt(text.trim()) || 0)
        }
    }

    readonly property bool muted: kind === "muted" || kind === "mic-muted"
    readonly property string icon: {
        switch (kind) {
        case "muted": return "volume_off";
        case "mic": return "mic";
        case "mic-muted": return "mic_off";
        case "brightness": return value <= 33 ? "brightness_low" : value <= 66 ? "brightness_medium" : "brightness_high";
        default: return value <= 0 ? "volume_mute" : value <= 50 ? "volume_down" : "volume_up";
        }
    }

    anchors.bottom: true
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-osd"
    mask: Region {}   // click-through

    visible: shown || island.opacity > 0.01
    implicitWidth: island.implicitWidth
    implicitHeight: island.implicitHeight + 76

    Rectangle {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: osd.shown ? 60 : 46   // float ~60px up, subtle rise on show
        implicitWidth: 280
        implicitHeight: content.implicitHeight + 20
        color: Theme.bg

        opacity: osd.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        RowLayout {
            id: content
            anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 10; bottomMargin: 10 }
            spacing: 14

            Icon {
                text: osd.icon
                size: 22
                color: osd.muted ? Theme.dim : Theme.text
            }

            Rectangle {  // progress track
                Layout.fillWidth: true
                implicitHeight: 6
                color: Theme.surface

                Rectangle {  // fill
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: parent.width * (osd.value / 100)
                    color: osd.muted ? Theme.dim : Theme.pink
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                text: osd.value + "%"
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.dim
                Layout.preferredWidth: 34
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
