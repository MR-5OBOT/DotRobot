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

    function refresh() {
        proc.running = true;
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
        command: ["sh", "-c", "hyprctl workspacerules -j; printf '@@@'; hyprctl monitors -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                var map = {};
                try {
                    var parts = this.text.split("@@@");
                    var rules = JSON.parse(parts[0]);
                    var mons = JSON.parse(parts[1] || "[]");
                    for (var i = 0; i < rules.length; i++) {
                        var ws = parseInt(rules[i].workspaceString);
                        var mon = rules[i].monitor ? root.connectorFor(rules[i].monitor, mons) : "";
                        if (!mon || isNaN(ws))
                            continue;
                        if (!map[mon])
                            map[mon] = [];
                        map[mon].push(ws);
                    }
                } catch (e) {
                    return;
                }
                for (var k in map)
                    map[k].sort(function (a, b) { return a - b; });
                root.byMonitor = map;
            }
        }
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
