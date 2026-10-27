pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Persistent workspace→monitor map from Hyprland's workspace rules
 * (`hyprctl workspacerules`). This is the single source for the split that
 * monitors.lua declares, so the pill's dots show every assigned workspace on a
 * monitor even before it has been visited, instead of hardcoding monitor
 * names. Empty when a setup has no rules (the usual single-monitor case) and
 * the dots fall back to live workspaces. Keyed by connector name: a rule's
 * `desc:` selector is resolved to the connected monitor it matches. Re-read on
 * config reload, since editing monitors.lua rewrites the rules, and on monitor
 * hotplug, since a `desc:` rule only resolves while its monitor is connected.
 */
Singleton {
    id: root

    property var byMonitor: ({})
    /** Raw `hyprctl workspacerules -j`, resolved against Monitors' shared monitor list. */
    property var rules: []

    function refresh() {
        proc.running = true;
    }

    /** Rebuild the map; reassigned only when it really changed, so the dots don't rebuild for nothing. */
    function resolve() {
        var map = {};
        var mons = Monitors.list;
        for (var i = 0; i < root.rules.length; i++) {
            var ws = parseInt(root.rules[i].workspaceString);
            var mon = root.rules[i].monitor ? root.connectorFor(root.rules[i].monitor, mons) : "";
            if (!mon || isNaN(ws))
                continue;
            if (!map[mon])
                map[mon] = [];
            map[mon].push(ws);
        }
        for (var k in map)
            map[k].sort(function (a, b) { return a - b; });
        if (JSON.stringify(map) !== JSON.stringify(root.byMonitor))
            root.byMonitor = map;
    }

    /**
     * Connector name for a rule's monitor selector, "" when it is not connected.
     * Mirrors Hyprland's CMonitor::matchesStaticSelector: `desc:` prefix-matches
     * the description or the trimmed "make model serial"; anything else is a name.
     */
    function connectorFor(sel, mons) {
        if (sel.indexOf("desc:") !== 0)
            return sel;
        var want = sel.slice(5).trim();
        for (var i = 0; i < mons.length; i++) {
            var m = mons[i];
            var shortDesc = [m.make, m.model, m.serial].join(" ").trim();
            if ((m.description || "").indexOf(want) === 0 || shortDesc.indexOf(want) === 0)
                return m.name;
        }
        return "";
    }

    Process {
        id: proc
        command: ["hyprctl", "workspacerules", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var rules = JSON.parse(this.text);
                    root.rules = Array.isArray(rules) ? rules : [];
                } catch (e) {
                    return;
                }
                root.resolve();
            }
        }
    }

    // A desc: rule only resolves while its monitor is in the shared list.
    Connections {
        target: Monitors
        function onUpdated() { root.resolve() }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" || /^monitor(added|removed)/.test(event.name))
                root.refresh();
        }
    }

    Component.onCompleted: refresh()
}
