pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Single owner of external-monitor brightness (ddcutil) for the mixer. DDC
 * monitors come from `ddcutil detect` (one brightness fader each); the
 * setvcp/getvcp wire format lives here so every caller speaks it the same.
 * The internal laptop backlight (eDP, no DDC/CI) is driven separately via
 * brightnessctl and gated on /sys/class/backlight being present, so a desktop
 * exposes nothing.
 */
Singleton {
    id: root

    /**
     * DDC-capable monitors from MonitorBrightness singleton: [{ bus, label, connector }]
     */
    readonly property var ddcMonitors: MonitorBrightness.monitors

    /** True once an internal backlight has been found under /sys/class/backlight. */
    property bool backlightPresent: false

    /** Current internal-backlight level, 0..100. */
    property int backlightPct: 75

    /**
     * Probes for brightness controls when the mixer opens. External monitor
     * detection is handled by the dedicated MonitorBrightness singleton;
     * the internal backlight is probed separately.
     */
    function detect() {
        MonitorBrightness.detect();
        blDetect.running = true;
    }

    function setBrightness(bus, pct) {
        MonitorBrightness.setBrightness(bus, pct);
    }

    /**
     * Sets the internal laptop backlight to `pct` percent via brightnessctl.
     * No-op effect on machines without /sys/class/backlight (brightnessctl
     * simply finds no device), and inert when brightnessctl is absent.
     */
    function setBacklight(pct) {
        root.backlightPct = Math.round(Math.max(1, Math.min(100, pct)));
        Quickshell.execDetached(["brightnessctl", "set", root.backlightPct + "%"]);
    }

    /**
     * Parses a `ddcutil getvcp --brief` line, returning the current brightness
     * percent or -1 when no value is present.
     */
    function parseBrightness(text) {
        return MonitorBrightness.parseBrightness(text);
    }

    Process {
        id: blDetect
        command: ["sh", "-c", "dev=$(ls /sys/class/backlight 2>/dev/null | head -n1); [ -n \"$dev\" ] || exit 0; max=$(cat /sys/class/backlight/$dev/max_brightness); cur=$(cat /sys/class/backlight/$dev/brightness); echo \"$(( cur * 100 / max ))\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(this.text.trim(), 10);
                if (!isNaN(v)) {
                    root.backlightPct = Math.max(1, Math.min(100, v));
                    root.backlightPresent = true;
                }
            }
        }
    }
}
