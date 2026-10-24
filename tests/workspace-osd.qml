import QtQuick
import Quickshell
import "island" as Desktop
import "island/Singletons" as Island

ShellRoot {
    id: test
    property int phase: 0
    property var popup: null
    property var osd: null
    property var dots: null

    Region { id: emptyInput }
    Desktop.Island {
        id: desktop
        onWindowsChanged: windows.forEach(window => {
            window.contentItem.opacity = 0;
            window.mask = emptyInput;
        })
    }

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }
    function find(item, matches) {
        if (matches(item)) return item;
        for (const child of item.children || []) {
            const found = find(child, matches);
            if (found) return found;
        }
        return null;
    }

    // Let the initial Hyprland snapshot retries finish before supplying fixture dots.
    Timer { interval: 2200; running: true; onTriggered: checks.start() }

    Timer {
        id: checks
        interval: 650
        repeat: true
        onTriggered: {
            try {
                if (test.phase === 0) {
                    const window = desktop.windows[0];
                    test.check(!!window, "Create a monitor overlay");
                    test.popup = test.find(window.contentItem, item => item.workspace !== undefined && item.topFlat !== undefined);
                    test.check(!!test.popup, "Load the real OSD popup");
                    test.osd = test.find(test.popup, item => typeof item.flash === "function");
                    test.dots = test.find(test.popup, item => item.activeName !== undefined);
                    test.dots.range = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
                    test.dots.activeName = "5";
                    test.dots.occupied = { 1: true, 2: true, 5: true, 10: true };
                    Island.Monitors.focusedName = test.popup.screenName;
                    test.check(!test.popup.active, "Avoid flashing on startup");
                    Island.Monitors.list = [{ name: test.popup.screenName, activeWorkspace: { name: "5" } }];
                    test.check(test.popup.active, "Flash when the monitor changes workspace");
                    test.check(test.popup.reveal < 0.01, "Start the slide outside the screen");
                } else if (test.phase === 1) {
                    test.check(test.popup.active && test.popup.visible, "Show the workspace popup");
                    test.check(test.popup.height > test.popup.width * 4, "Use a vertical capsule: " + test.popup.width + "x" + test.popup.height + ", dots=" + test.dots.implicitWidth + ", range=" + test.dots.range);
                    test.check(Math.abs(test.popup.x) < 1, "Dock at the left edge");
                    test.check(Math.abs(test.popup.y + test.popup.height / 2 - test.popup.parent.height / 2) < 1, "Center vertically");
                    test.check(test.dots.rotation === 90 && test.dots.activeIndex === 4, "Rotate the existing dots and active pill");
                    const pill = test.find(desktop.windows[0].contentItem, item => item.osdActive !== undefined);
                    test.check(pill && !pill.osdActive && pill.opacity === 1, "Keep the top island visible during workspace flashes");
                    Island.Monitors.list = [{ name: test.popup.screenName, activeWorkspace: { name: "6" } }];
                } else if (test.phase === 3) {
                    test.check(test.popup.active, "Extend the timeout when switching again");
                } else if (test.phase === 5) {
                    test.check(!test.popup.active && !test.popup.visible, "Retract after the workspace timeout");
                    test.osd.flash("volume");
                } else if (test.phase === 6) {
                    test.check(test.popup.active && !test.popup.workspace && test.popup.reveal > 0.99, "Keep other OSD flashes working");
                    test.check(test.popup.width > test.popup.height * 4, "Keep volume horizontal");
                    test.check(Math.abs(test.popup.y) < 1, "Keep volume at the top");
                    test.check(Math.abs(test.popup.x + test.popup.width / 2 - test.popup.parent.width / 2) < 1, "Center volume horizontally");
                    console.log("Workspace OSD placement, orientation, timeout and volume checks passed.");
                    Qt.quit();
                }
                test.phase++;
            } catch (error) {
                console.error("Workspace OSD checks failed:", error);
                Qt.quit();
            }
        }
    }
}
