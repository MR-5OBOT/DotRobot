pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Playback spectrum for the notch's music wave. One cava for the whole shell,
 * run only while something plays and at least one pill shows the wave
 * (`viewers` is a refcount the pills keep). `levels` is the spectrum mirrored
 * around the centre (bass in the middle), each 0..1; empty when stopped.
 * setpriv ties cava to qs so a crashed shell never leaves it behind.
 */
Singleton {
    id: root

    readonly property int bars: 16
    property int viewers: 0
    property var levels: []

    Process {
        running: Players.playing && root.viewers > 0
        command: ["bash", "-c", "exec setpriv --pdeathsig TERM cava -p <(printf '"
            + "[general]\\nbars = " + root.bars + "\\nframerate = 30\\n"
            + "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\nchannels = mono\\n"
            + "data_format = ascii\\nascii_max_range = 1000\\nbar_delimiter = 59\\n')"]
        stdout: SplitParser {
            onRead: (line) => {
                const half = line.split(";", root.bars).map(v => (parseInt(v) || 0) / 1000);
                root.levels = half.slice().reverse().concat(half);
            }
        }
        onRunningChanged: if (!running) root.levels = []
    }
}
