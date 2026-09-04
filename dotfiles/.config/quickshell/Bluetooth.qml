import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Bar: bluetooth glyph. Hover -> power state + connected devices.
// Uses bluetoothctl (Quickshell.Bluetooth adapter is unpopulated on this box).
Item {
    id: root
    implicitWidth: parent.width
    implicitHeight: 22

    property bool powered: false
    property var devices: []
    readonly property bool connected: devices.length > 0
    readonly property string icon: !powered ? "bluetooth_disabled" : connected ? "bluetooth_connected" : "bluetooth"

    function refresh() {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["bash", "-c", "echo PWR:$(bluetoothctl show | grep -c 'Powered: yes'); bluetoothctl devices Connected"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0);
                root.powered = lines.some(l => l === "PWR:1");
                // "Device AA:BB:CC:DD:EE:FF Name here" -> "Name here"
                root.devices = lines.filter(l => l.startsWith("Device ")).map(l => l.split(" ").slice(2).join(" "));
            }
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Icon {
        anchors.centerIn: parent
        size: 17
        color: root.connected ? Theme.pink : (root.powered ? Theme.text : Theme.dim)
        text: root.icon
    }

    HoverHandler {
        onHoveredChanged: {
            pop.itemHovered = hovered;
            if (hovered)
                root.refresh();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Quickshell.execDetached(["blueman-manager"])
    }

    Popout {
        id: pop
        anchorItem: root
        contentComponent: Component {
            ColumnLayout {
                spacing: 8

                RowLayout {
                    spacing: 10
                    Icon {
                        size: 20
                        color: root.connected ? Theme.pink : Theme.dim
                        text: root.icon
                    }
                    Text {
                        text: !root.powered ? "Bluetooth off" : root.connected ? "Connected" : "No devices"
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.text
                    }
                }

                Repeater {
                    model: root.devices
                    delegate: RowLayout {
                        required property string modelData
                        spacing: 6
                        Icon {
                            size: 13
                            color: Theme.dim
                            text: "bluetooth_connected"
                        }
                        Text {
                            text: parent.modelData
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: Theme.dim
                        }
                    }
                }
            }
        }
    }
}
