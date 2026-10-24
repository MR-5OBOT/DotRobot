import QtQuick
import Quickshell
import QtTest
import "island/Singletons" as Island
import "island/surfaces" as Surfaces

// tests/notifications.sh stages the shell on a private bus with isolated state.
ShellRoot {
    id: test
    property int phase: 0
    property real collapsedHeight: 0
    property var whatsapp: null

    function check(condition, message) {
        if (!condition) throw new Error(message);
    }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const found = find(child, name);
            if (found) return found;
        }
        return null;
    }
    function capture(name) {
        const dir = Quickshell.env("NOTIFICATION_TEST_SCREENSHOTS");
        if (dir) view.grabToImage(image => image.saveToFile(dir + "/" + name + ".png"));
    }
    TestEvent { id: mouse }

    FloatingWindow {
        visible: true
        implicitWidth: 400
        implicitHeight: 720
        Surfaces.Link { id: view; anchors.fill: parent; anchors.margins: 20; open: true }
    }

    Component.onCompleted: {
        const now = Date.now();
        Island.Notifs.history = [
            { id: "wa1", app: "WhatsApp", summary: "Alex", body: "See you at 6", ts: now, urgency: 1 },
            { id: "wa2", app: "WhatsApp", summary: "Sam", body: "The photos are ready", ts: now - 1000, urgency: 1 },
            { id: "wa3", app: "WhatsApp", summary: "Family", body: "A longer notification that wraps across multiple lines in the expanded notification stack.", ts: now - 2000, urgency: 1 },
            { id: "wa4", app: "WhatsApp", summary: "Team", body: "The review is ready", ts: now - 2100, urgency: 1 },
            { id: "wa5", app: "WhatsApp", summary: "Alex", body: "Sent the updated documents", ts: now - 2200, urgency: 1 },
            { id: "wa6", app: "WhatsApp", summary: "Sam", body: "More photos to review in the shared folder", ts: now - 2300, urgency: 1 },
            { id: "wa7", app: "WhatsApp", summary: "Team", body: "New documents uploaded", ts: now - 2400, urgency: 1 },
            { id: "term1", app: "Terminal", summary: "Build complete", body: "All checks passed", ts: now - 3000, urgency: 1 },
            { id: "term2", app: "Terminal", summary: "Build complete", body: "All checks passed", ts: now - 4000, urgency: 1 },
            { id: "cal1", app: "Calendar", summary: "Meeting", body: "Starts in five minutes", ts: now - 5000, urgency: 2 }
        ];
    }

    Timer {
        interval: 450
        running: true
        repeat: true
        onTriggered: {
            try {
                if (test.phase === 0) {
                    test.check(Island.Notifs.groups.length === 3, "Group notifications by app");
                    test.check(Island.Notifs.groups[1].entries[0].count === 2, "Coalesce duplicate notifications");
                    test.check(Island.Notifs.groups[2].criticals.length === 1, "Preserve critical notifications");
                    test.whatsapp = test.find(view, "notificationGroup-WhatsApp");
                    test.check(test.whatsapp && !test.whatsapp.expanded, "Stacks start collapsed");
                    test.check(test.whatsapp.layers === 2, "Show layered cards behind the preview");
                    test.collapsedHeight = test.whatsapp.height;
                    test.capture("notifications-collapsed");
                    test.check(mouse.mouseMove(test.whatsapp, test.whatsapp.width / 2, 16, 0, Qt.NoButton, Qt.NoModifier), "Move pointer onto an app stack");
                } else if (test.phase === 1) {
                    test.check(test.whatsapp.expanded, "Hover expands the stack");
                    test.check(test.whatsapp.height > test.collapsedHeight + 100, "Expand the full stack");
                    test.capture("notifications-expanded");
                    mouse.mouseMove(view, 1, 1, 0, Qt.NoButton, Qt.NoModifier);
                } else if (test.phase === 2) {
                    test.check(!test.whatsapp.expanded, "Leaving a stack collapses it");
                    const icon = test.find(test.whatsapp, "notificationAppIcon");
                    test.check(icon !== null, "Keep the app icon in the notification row");
                    mouse.mouseClick(icon, icon.width / 2, icon.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
                    mouse.mouseMove(view, 1, 1, 0, Qt.NoButton, Qt.NoModifier);
                } else if (test.phase === 3) {
                    test.check(test.whatsapp.pinned, "Click pins a group open");
                    test.check(test.whatsapp.expanded, "Keep clicked groups expanded after hover ends");
                    const list = test.find(view, "notificationList");
                    test.check(list.contentHeight > list.height, "Scroll expanded groups within the panel");
                    Island.Notifs.history = [{ id: "arrival", app: "WhatsApp", summary: "New arrival", body: "Keep the group open", ts: Date.now(), urgency: 1 }].concat(Island.Notifs.history);
                } else if (test.phase === 4) {
                    test.whatsapp = test.find(view, "notificationGroup-WhatsApp");
                    test.check(test.whatsapp.pinned && test.whatsapp.expanded, "Keep a pinned group open when new notifications arrive");
                    view.open = false;
                } else if (test.phase === 5) {
                    test.check(!test.whatsapp.expanded, "Reset expansion when the panel closes");
                    test.check(Math.abs(test.whatsapp.height - test.collapsedHeight) < 1, "Collapse back to the stack height");
                    Island.Notifs.dismissApp("WhatsApp");
                    test.check(Island.Notifs.groups.length === 2, "Clear one app without clearing other apps");
                    Island.Notifs.clearAll();
                    test.check(Island.Notifs.count === 0, "Clear the inbox");
                    console.log("Notification grouping, stack layout, expansion, criticals and clearing checks passed.");
                    Qt.quit();
                }
                test.phase++;
            } catch (error) {
                console.error("Notification checks failed:", error);
                Qt.quit();
            }
        }
    }
}
