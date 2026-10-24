import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: test
    property int phase: 0
    property var captures: []

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }
    function findCapture(item) {
        if (item.frozenReady !== undefined && item.captureBackend !== undefined) return item;
        for (const child of item.children || []) {
            const found = findCapture(child);
            if (found) return found;
        }
        return null;
    }

    Loader {
        id: shot
        onStatusChanged: if (status === Loader.Error) Qt.quit()
        onLoaded: {
            item.dialogMode = true;
            item.captureBackend = "image"; // Supply frame readiness ourselves without capturing the real desktop.
        }
    }
    Component.onCompleted: shot.setSource("Rishot.qml", { dialogMode: true })

    Timer {
        interval: 150
        running: shot.status === Loader.Ready
        repeat: true
        onTriggered: {
            try {
                const window = shot.item.overlays[0];
                if (test.phase === 0) {
                    test.check(!shot.item.captureReady, "Wait for a captured frame");
                    test.check(window.mask.item === null, "Do not steal hover before capture");
                    test.check(window.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None, "Do not steal focus before capture");
                    test.captures = shot.item.overlays.map(w => test.findCapture(w.contentItem));
                    test.check(test.captures.every(c => c !== null), "Find each real capture view");
                    test.captures[0].ready = true;
                } else if (test.phase === 1) {
                    if (test.captures.length > 1) {
                        test.check(!shot.item.captureReady, "One captured monitor must not steal focus from the others");
                        test.check(window.mask.item === null, "Keep pointer input disabled while other monitors capture");
                    }
                    test.captures.forEach(c => c.ready = true);
                } else if (test.phase === 2) {
                    test.check(shot.item.captureReady, "Enable input after every output is frozen");
                    test.check(window.mask.item !== null, "Enable region selection after capture");
                    test.check(window.WlrLayershell.keyboardFocus === WlrKeyboardFocus.Exclusive, "Enable shortcuts after capture");
                    test.captures[test.captures.length - 1].ready = false;
                } else {
                    test.check(!shot.item.captureReady && window.mask.item === null, "Disable input when a frame is no longer ready");
                    shot.item.overlays = [];
                    test.check(!shot.item.captureReady, "An empty output list is never ready");
                    console.log("Rishot capture-before-focus and pointer-input checks passed.");
                    Qt.quit();
                }
                test.phase++;
            } catch (error) {
                console.error("Rishot startup checks failed:", error);
                Qt.quit();
            }
        }
    }
}
