pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland's QML monitor/workspace models can stay empty in Lua sessions, so
// the whole shell shares one hyprctl snapshot of monitors and workspaces,
// refreshed (debounced) on the events that can change it. `updated` fires
// after each fresh snapshot; the workspace dots re-sync on it.
Singleton {
    id: root
    property var list: []
    /** Every workspace from `hyprctl workspaces -j` (id, name, monitor, windows, ...). */
    property var workspaces: []
    property string focusedName: ""
    property bool refreshAgain: false
    property int bootTries: 0
    readonly property var focused: list.find(m => m.name === focusedName) || null
    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === focusedName)
        || Quickshell.screens[0] || null

    signal updated()

    function refresh() {
        if (proc.running) root.refreshAgain = true;
        else proc.running = true;
    }

    Process {
        id: proc
        command: ["sh", "-c", "hyprctl monitors -j; printf '@@@'; hyprctl workspaces -j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parts = text.split("@@@");
                    const data = JSON.parse(parts[0]);
                    if (!Array.isArray(data)) throw new Error("Expected monitor list");
                    const wss = JSON.parse(parts[1] || "[]");
                    root.workspaces = Array.isArray(wss) ? wss : [];
                    root.list = data;
                    const focused = data.find(m => m.name === root.focusedName)
                        || data.find(m => m.focused) || data[0];
                    root.focusedName = focused ? focused.name : "";
                    root.updated();
                } catch (e) {
                    console.warn("Could not refresh monitors:", e);
                }
            }
        }
        onExited: code => {
            if (code !== 0) console.warn("hyprctl monitors failed:", code);
            if (root.refreshAgain) {
                root.refreshAgain = false;
                root.refresh();
            } else if (root.list.length === 0 && root.bootTries < 8) {
                // A slow compositor reply at startup: retry briefly until the first snapshot lands.
                root.bootTries++;
                bootRetry.start();
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "focusedmon" || event.name === "focusedmonv2")
                root.focusedName = event.data.split(",")[0];
            if (/^(focusedmon|workspace|createworkspace|destroyworkspace|renameworkspace|activespecial|moveworkspace|monitoradded|monitorremoved|configreloaded|openwindow|closewindow|movewindow)/.test(event.name))
                refreshSoon.restart();
        }
    }
    Timer { id: refreshSoon; interval: 40; onTriggered: root.refresh() }
    Timer { id: bootRetry; interval: 250; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
