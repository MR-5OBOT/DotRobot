import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Bar: wifi glyph by signal. Hover -> SSID, signal, frequency, rate.
// Uses nmcli (native Networking module is unpopulated on this box).
Item {
    id: root
    implicitWidth: parent.width
    implicitHeight: 22

    property string ssid: ""
    property int signal: 0
    property string freq: ""
    property string rate: ""
    readonly property bool connected: ssid.length > 0

    readonly property var bars: ["network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "wifi"]
    readonly property string icon: connected ? bars[Math.min(3, Math.floor(signal / 25))] : "wifi_off"

    function refresh() {
        proc.running = true;
    }

    Process {
        id: proc
        // SSID last so ':' inside it can't shift the numeric/text columns.
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,FREQ,RATE,SSID", "dev", "wifi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const row = text.split("\n").find(l => l.startsWith("yes:"));
                if (!row) {
                    root.ssid = "";
                    return;
                }
                const f = row.split(":");
                root.signal = parseInt(f[1] ?? "0") || 0;
                root.freq = f[2] ?? "";
                root.rate = f[3] ?? "";
                root.ssid = f.slice(4).join(":").replace(/\\/g, "");
            }
        }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Icon {
        anchors.centerIn: parent
        size: 17
        color: root.connected ? Theme.text : Theme.dim
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
        onClicked: Quickshell.execDetached(["kitty", "-e", "nmtui"])
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
                        text: root.connected ? root.ssid : "Disconnected"
                        font.family: Theme.font
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.text
                    }
                }

                GridLayout {
                    visible: root.connected
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 4

                    Text { text: "Strength"; font.family: Theme.font; font.pixelSize: 11; color: Theme.dim }
                    Text { text: root.signal + " / 100"; font.family: Theme.font; font.pixelSize: 11; color: Theme.text }
                    Text { text: "Frequency"; font.family: Theme.font; font.pixelSize: 11; color: Theme.dim }
                    Text { text: root.freq; font.family: Theme.font; font.pixelSize: 11; color: Theme.text }
                    Text { text: "Rate"; font.family: Theme.font; font.pixelSize: 11; color: Theme.dim }
                    Text { text: root.rate; font.family: Theme.font; font.pixelSize: 11; color: Theme.text }
                }
            }
        }
    }
}
