pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland's QML monitor model can stay empty in Lua sessions; share one IPC snapshot.
Singleton {
    id: root
    property var list: []
    property string focusedName: ""
    property bool refreshAgain: false
    readonly property var focused: list.find(m => m.name === focusedName) || null
    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === focusedName)
        || Quickshell.screens[0] || null

    function refresh() {
        if (proc.running) root.refreshAgain = true;
        else proc.running = true;
    }

    Process {
        id: proc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!Array.isArray(data)) throw new Error("Expected monitor list");
                    root.list = data;
                    const focused = data.find(m => m.name === root.focusedName)
                        || data.find(m => m.focused) || data[0];
                    root.focusedName = focused ? focused.name : "";
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
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "focusedmon" || event.name === "focusedmonv2")
                root.focusedName = event.data.split(",")[0];
            if (/^(focusedmon|workspace|activespecial|moveworkspace|monitoradded|monitorremoved|configreloaded)/.test(event.name))
                refreshSoon.restart();
        }
    }
    Timer { id: refreshSoon; interval: 40; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
