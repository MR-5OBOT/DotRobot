import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Bar: battery glyph tinted by level. Hover -> %, state, time remaining.
// Reads sysfs directly (Quickshell UPower service is unpopulated on this box)
// and energy-weights across both batteries. ponytail: assumes energy_* units;
// this ThinkPad has energy_now/full on both BATs.
Item {
    id: root
    implicitWidth: parent.width
    implicitHeight: 22
    visible: full > 0

    property int pct: 0
    property real now: 0        // summed energy_now (µWh)
    property real full: 0       // summed energy_full (µWh)
    property real power: 0      // summed power_now (µW)
    property bool charging: false
    property bool discharging: false

    readonly property var levels: ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar", "battery_4_bar", "battery_5_bar", "battery_6_bar", "battery_full"]
    function levelIcon() {
        return charging ? "battery_charging_full" : levels[Math.round(pct / 100 * 7)];
    }

    function fmtTime(hours) {
        if (!hours || hours <= 0 || !isFinite(hours))
            return "";
        const h = Math.floor(hours);
        const m = Math.floor((hours - h) * 60);
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    function refresh() {
        proc.running = true;
    }

    Process {
        id: proc
        command: ["bash", "-c", "for b in /sys/class/power_supply/BAT*; do echo \"$(cat $b/energy_now 2>/dev/null||echo 0):$(cat $b/energy_full 2>/dev/null||echo 0):$(cat $b/status 2>/dev/null):$(cat $b/power_now 2>/dev/null||echo 0)\"; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let n = 0, f = 0, p = 0, chg = false, dis = false;
                for (const line of text.split("\n")) {
                    if (!line)
                        continue;
                    const c = line.split(":");
                    n += parseInt(c[0]) || 0;
                    f += parseInt(c[1]) || 0;
                    p += parseInt(c[3]) || 0;
                    if (c[2] === "Charging")
                        chg = true;
                    if (c[2] === "Discharging")
                        dis = true;
                }
                root.now = n;
                root.full = f;
                root.power = p;
                root.charging = chg;
                root.discharging = dis;
                root.pct = f > 0 ? Math.round(n / f * 100) : 0;
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Icon {
        anchors.centerIn: parent
        size: 17
        color: root.pct <= 20 && !root.charging ? Theme.pink : Theme.text
        text: root.levelIcon()
    }

    HoverHandler {
        onHoveredChanged: {
            pop.itemHovered = hovered;
            if (hovered)
                root.refresh();
        }
    }

    Popout {
        id: pop
        anchorItem: root
        contentComponent: Component {
            RowLayout {
                spacing: 12
                Icon {
                    size: 24
                    color: root.charging ? Theme.pink : Theme.text
                    text: root.levelIcon()
                }
                ColumnLayout {
                    spacing: 3
                    Text {
                        text: root.pct + "%  " + (root.charging ? "Charging" : root.discharging ? "Discharging" : "Plugged in")
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.text
                    }
                    Text {
                        // time = remaining energy / current power draw (hours)
                        readonly property string t: root.power <= 0 ? "" : root.charging ? root.fmtTime((root.full - root.now) / root.power) : root.discharging ? root.fmtTime(root.now / root.power) : ""
                        visible: t.length > 0
                        text: (root.charging ? "Full in " : "Empty in ") + t
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Theme.dim
                    }
                }
            }
        }
    }
}
