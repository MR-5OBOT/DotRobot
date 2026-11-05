import QtQuick
import Quickshell
import Quickshell.Io
import "lib/providers.js" as Providers

/**
 * Enumerates Hyprland's windows in global coordinates for region-mode
 * window-snap. A query failure emits an empty list, so region and monitor
 * selection keep working. The result arrives through `windowsReady` after
 * `refresh()` completes the queries.
 */
Item {
    id: provider

    /**
     * Emitted once window enumeration finishes.
     * @param {Array<{x,y,w,h,z}>} rects Window rects in global coordinates.
     */
    signal windowsReady(var rects)

    function refresh() {
        hyprMonitorsProc.running = true;
    }

    Process {
        id: hyprMonitorsProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector { id: hyprMonitorsOut }
        onExited: (code) => {
            if (code !== 0) { provider.windowsReady([]); return; }
            hyprClientsProc.running = true;
        }
    }

    Process {
        id: hyprClientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector { id: hyprClientsOut }
        onExited: (code) => {
            if (code !== 0) { provider.windowsReady([]); return; }
            provider.windowsReady(Providers.parseHyprland(hyprMonitorsOut.text, hyprClientsOut.text));
        }
    }
}
