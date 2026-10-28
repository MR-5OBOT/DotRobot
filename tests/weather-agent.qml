import QtQuick
import Quickshell
import "island/Singletons" as Island

ShellRoot {
    Timer { interval: 100; running: true; onTriggered: Island.Weather.needed = true }
    Timer { interval: 3000; running: true; onTriggered: Qt.quit() }
}
