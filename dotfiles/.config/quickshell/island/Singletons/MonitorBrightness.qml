pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Dedicated external monitor brightness singleton (DDC/CI).
 * Detects connected monitors automatically on startup and on Hyprland monitor
 * hotplug events (monitoradded/monitorremoved), providing non-blocking hardware
 * backlight control for external displays.
 */
Singleton {
    id: root

    /**
     * List of detected external DDC monitors: [{ bus, label, connector }]
     */
    property var monitors: []
    property bool busy: false

    function detect() {
        if (!ddcDetect.running)
            ddcDetect.running = true;
    }

    function setBrightness(bus, pct) {
        var clamped = Math.max(0, Math.min(100, Math.round(pct)));
        Quickshell.execDetached(["timeout", "3", "ddcutil", "setvcp", "10",
            String(clamped), "--bus", String(bus), "--noverify"]);
    }

    function parseBrightness(text) {
        var m = text.match(/C\s+(\d+)\s+/);
        return m ? parseInt(m[1], 10) : -1;
    }

    // Auto-detect on Hyprland monitor hotplug events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (/^(monitoradded|monitorremoved)/.test(event.name))
                hotplugTimer.restart();
        }
    }

    Timer {
        id: hotplugTimer
        interval: 1200 // Give the kernel / display hardware a moment to settle
        onTriggered: root.detect()
    }

    Process {
        id: ddcDetect
        command: ["sh", "-c", "command -v ddcutil >/dev/null 2>&1 || exit 0; ddcutil detect --brief"]
        running: false
        onStarted: root.busy = true
        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                var mons = [];
                var blocks = this.text.split(/\bDisplay \d+/);
                for (var i = 0; i < blocks.length; i++) {
                    var bus = /I2C bus:\s+\/dev\/i2c-(\d+)/.exec(blocks[i]);
                    var conn = /DRM connector:\s+card\d+-(\S+)/.exec(blocks[i]);
                    var monModel = /Monitor:[^:\n]*:([^:\n]+)/.exec(blocks[i]);
                    if (!bus)
                        continue;
                    var connName = conn ? conn[1] : "";
                    if (/^eDP/i.test(connName))
                        continue;

                    var displayLabel = (monModel && monModel[1].trim().length > 0)
                        ? monModel[1].trim()
                        : (connName ? connName : "BUS " + bus[1]);

                    mons.push({
                        bus: bus[1],
                        label: displayLabel,
                        connector: connName
                    });
                }
                root.monitors = mons;
            }
        }
        onExited: root.busy = false
    }

    Component.onCompleted: detect()
}
