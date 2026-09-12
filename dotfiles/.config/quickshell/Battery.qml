import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Bar: battery glyph tinted by level. Hover -> %, state, time remaining.
// Display only — the low-battery nag is a separate autostart script.
// Reads sysfs directly (Quickshell UPower service is unpopulated on this box)
// and energy-weights across every BAT. Kernels expose one of two unit families:
// energy_*/power_now (µWh/µW, the ThinkPad) or charge_*/current_now (µAh/µA,
// this Dell) — charge units are scaled by voltage so both reach QML as energy.
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
    // Charging has its own glyph set, graded 20/30/50/60/80/90 + full — coarser
    // than the 0-6 bar ramp and with nothing below 20, so take the highest tier
    // at or under pct and let the sub-20% case borrow the 20 glyph.
    readonly property var chargeSteps: [90, 80, 60, 50, 30, 20]
    function levelIcon() {
        if (!charging)
            return levels[Math.round(pct / 100 * 7)];
        if (pct >= 95)
            return "battery_charging_full";
        for (const s of chargeSteps)
            if (pct >= s)
                return "battery_charging_" + s;
        return "battery_charging_20";
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
        command: ["bash", "-c", "for b in /sys/class/power_supply/BAT*; do v=$(cat $b/voltage_now 2>/dev/null||echo 0); [ \"$v\" = 0 ] && v=$(cat $b/voltage_min_design 2>/dev/null||echo 0); n=$(cat $b/energy_now 2>/dev/null||echo 0); f=$(cat $b/energy_full 2>/dev/null||echo 0); p=$(cat $b/power_now 2>/dev/null||echo 0); if [ \"$f\" = 0 ]; then n=$(( $(cat $b/charge_now 2>/dev/null||echo 0)*v/1000000 )); f=$(( $(cat $b/charge_full 2>/dev/null||echo 0)*v/1000000 )); p=$(( $(cat $b/current_now 2>/dev/null||echo 0)*v/1000000 )); fi; echo \"$n:$f:$(cat $b/status 2>/dev/null):$p\"; done"]
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

    // Low-battery warnings moved to hypr/scripts/autostart/battery-notify.sh
    // so they survive a qs restart. lowPct is kept purely to tint the glyph.
    readonly property int lowPct: 20

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Icon {
        anchors.centerIn: parent
        size: 17
        color: root.pct <= root.lowPct && !root.charging ? Theme.pink : Theme.text
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
