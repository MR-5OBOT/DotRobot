pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * One logind PrepareForSleep watcher for the whole shell: `woke` fires on resume
 * so the pills can re-read the wall clock (SystemClock's timer is monotonic, so
 * the time stays frozen at the pre-sleep minute otherwise). setpriv ties
 * dbus-monitor to qs, so a killed or crashed shell never leaves it behind, and a
 * watcher that dies retries after a pause instead of respawning in a tight loop.
 */
Singleton {
    id: root

    signal woke()

    Process {
        id: watcher
        running: true
        command: ["setpriv", "--pdeathsig", "TERM", "dbus-monitor", "--system",
            "type='signal',sender='org.freedesktop.login1',member='PrepareForSleep'"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("boolean false") >= 0)
                    root.woke();
            }
        }
        onExited: retry.start()
    }

    Timer {
        id: retry
        interval: 5000
        onTriggered: watcher.running = true
    }
}
