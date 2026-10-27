pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

/**
 * Laptop-battery state for the pill, sourced from UPower's display device and
 * gated so a desktop without a battery reports `present` false (the hover
 * cluster and 蓄 surface stay hidden). Exposes percentage, charge state, a
 * signed draw/charge wattage, capacity and optional health, plus a formatted
 * time-to-empty/full string. `low` flags a discharging battery at or below 20%.
 * With UPower lacking cycle counts and design energy, those two are read from
 * /sys/class/power_supply (BAT* or battery) so the surface can show charge
 * cycles and a design-derived health even when UPower's own health is missing.
 */
Singleton {
    id: root

    readonly property var dev: UPower.displayDevice

    readonly property bool present: dev !== null && dev.ready && dev.isLaptopBattery && dev.isPresent
    readonly property real frac: dev ? Math.max(0, Math.min(1, dev.percentage)) : 0
    readonly property int pct: Math.round(frac * 100)
    readonly property int state: dev ? dev.state : UPowerDeviceState.Unknown

    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full: state === UPowerDeviceState.FullyCharged || pct >= 100
    readonly property bool discharging: state === UPowerDeviceState.Discharging
    readonly property bool low: !charging && pct <= 20

    readonly property real rateW: !dev ? 0
        : (discharging ? -dev.changeRate : (charging ? dev.changeRate : 0))
    readonly property real capacityWh: dev ? dev.energyCapacity : 0

    /** Factory full-charge energy in Wh from sysfs; -1 when unreadable. */
    readonly property real energyFullDesign: root._energyFullDesign
    readonly property bool designSupported: root.energyFullDesign > 0

    readonly property bool hasTime: !dev ? false
        : (charging ? dev.timeToFull > 0 : (discharging ? dev.timeToEmpty > 0 : false))
    readonly property string timeStr: !dev ? ""
        : (charging ? fmt(dev.timeToFull) : (discharging ? fmt(dev.timeToEmpty) : ""))

    readonly property string stateLabel: charging ? "Charging"
        : (full ? "On AC · Full"
        : (discharging ? "Discharging" : "On AC"))

    property real _energyFullDesign: -1
    /** Charge cycles from sysfs; -1 when the battery doesn't report them. */
    property int cycles: -1

    function fmt(sec) {
        var s = Math.max(0, Math.round(sec));
        var h = Math.floor(s / 3600);
        var m = Math.floor((s % 3600) / 60);
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }

    /**
     * Read the battery's health fields once. Batteries report energy_* (uWh) or
     * charge_* (uAh, the Dell); charge is scaled by the design voltage to Wh.
     */
    Process {
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/power_supply/BAT* /sys/class/power_supply/battery; do [ -d \"$d\" ] && break; done; "
            + "for f in energy_full_design charge_full_design voltage_min_design cycle_count; do "
            + "printf '%s=%s\\n' \"$f\" \"$(cat \"$d/$f\" 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = {};
                this.text.split("\n").forEach(function(l) {
                    var i = l.indexOf("=");
                    if (i > 0)
                        v[l.slice(0, i)] = parseFloat(l.slice(i + 1));
                });
                root._energyFullDesign = v.energy_full_design > 0 ? v.energy_full_design / 1e6
                    : (v.charge_full_design > 0 && v.voltage_min_design > 0
                        ? v.charge_full_design * v.voltage_min_design / 1e12 : -1);
                root.cycles = v.cycle_count > 0 ? v.cycle_count : -1;
            }
        }
    }
}
