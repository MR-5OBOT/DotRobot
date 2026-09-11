import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Power-profile picker, alt-tab style: each `qs ipc call powerprofile cycle`
// (SUPER+SHIFT+P via `powerprofile menu`) opens the card on the next profile
// or moves the highlight on, and the pick applies once the presses stop.
// Arrows / Tab / j k switch to manual (Enter applies, Esc cancels).
// Same drop-in card as ActionMenu.
PanelWindow {
    id: win

    readonly property var order: ["power-saver", "balanced", "performance"]
    readonly property var meta: ({
        "power-saver": { icon: "eco", label: "Power saver" },
        "balanced": { icon: "balance", label: "Balanced" },
        "performance": { icon: "bolt", label: "Performance" }
    })

    property bool open: false
    property var profiles: []      // ids this machine offers, in `order`
    property string active: ""
    property string degraded: ""   // why ppd holds performance back, "" if it doesn't
    property int sel: -1
    property int queued: 0         // cycle presses that landed while the list was loading
    property real remaining: 0     // auto-apply countdown, 1 -> 0

    function cycle() {
        if (!open) {
            sel = -1;
            queued = 1;
            open = true;
            reader.running = true;
        } else if (reader.running) {
            queued++;
        } else if (profiles.length > 0) {
            sel = (sel + 1) % profiles.length;
            countdown.restart();
        }
    }

    function move(d) {   // manual nav: drop the auto-apply, wait for Enter
        if (profiles.length === 0)
            return;
        countdown.stop();
        sel = (sel + d + profiles.length) % profiles.length;
    }

    function apply() {
        countdown.stop();
        const p = profiles[sel];
        if (p && p !== active)
            Quickshell.execDetached(["powerprofilesctl", "set", p]);
        open = false;
    }

    onOpenChanged: if (!open) countdown.stop()
    Component.onCompleted: reader.running = true   // warm the list so the first open has rows

    IpcHandler {
        target: "powerprofile"
        function cycle(): void { win.cycle(); }
    }

    // `powerprofilesctl list`: a "* name:" header per profile (* = active)
    // followed by indented details; performance's include "Degraded: yes (why)".
    Process {
        id: reader
        command: ["powerprofilesctl", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = [];
                let act = "", deg = "", cur = "";
                for (const line of text.split("\n")) {
                    const h = line.match(/^([* ]) ([a-z-]+):$/);
                    if (h) {
                        cur = h[2];
                        seen.push(cur);
                        if (h[1] === "*")
                            act = cur;
                        continue;
                    }
                    const d = line.match(/^\s+Degraded:\s+yes \((.*)\)/);
                    if (d && cur === "performance")
                        deg = d[1];
                }
                win.profiles = win.order.filter(p => seen.includes(p));
                win.active = act;
                win.degraded = deg;
                if (!win.open || win.profiles.length === 0)
                    return;
                const i = Math.max(0, win.profiles.indexOf(act));
                win.sel = (i + win.queued) % win.profiles.length;
                win.queued = 0;
                countdown.restart();
            }
        }
    }

    NumberAnimation {
        id: countdown
        target: win
        property: "remaining"
        from: 1
        to: 0
        duration: 1500
        onFinished: win.apply()
    }

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-powerprofile"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: win.open = false
    }

    MouseArea { anchors.fill: parent; onClicked: win.open = false }  // click-outside

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: win.open ? 8 : -height   // drops in from the top edge
        width: 240
        height: col.implicitHeight + 2
        color: Theme.bg

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // swallow clicks on the card

        Item {  // key sink — no text input in this menu
            focus: true
            Keys.onEscapePressed: win.open = false
            Keys.onReturnPressed: win.apply()
            Keys.onEnterPressed: win.apply()
            Keys.onDownPressed: win.move(1)
            Keys.onUpPressed: win.move(-1)
            Keys.onTabPressed: win.move(1)
            Keys.onBacktabPressed: win.move(-1)
            Keys.onPressed: e => {
                if (e.key === Qt.Key_J)
                    win.move(1);
                else if (e.key === Qt.Key_K)
                    win.move(-1);
            }
        }

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
            spacing: 0

            RowLayout {  // header
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                spacing: 10
                Icon { text: "speed"; size: 16; color: Theme.dim }
                Text {
                    Layout.fillWidth: true
                    text: "Power profile"
                    font.family: Theme.font
                    font.pixelSize: 12
                    color: Theme.dim
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            Repeater {
                model: win.profiles
                delegate: Rectangle {
                    id: row
                    required property string modelData
                    required property int index
                    readonly property bool current: index === win.sel
                    // a degraded reason matters more than the active marker
                    readonly property string tag: modelData === "performance" && win.degraded !== "" ? win.degraded : modelData === win.active ? "active" : ""

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    color: current ? Theme.pink : (hover.hovered ? Theme.surface : "transparent")

                    RowLayout {
                        anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        spacing: 12
                        Icon { text: win.meta[row.modelData].icon; size: 17; color: row.current ? "#ffffff" : Theme.text }
                        Text {
                            Layout.fillWidth: true
                            text: win.meta[row.modelData].label
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: row.current
                            color: row.current ? "#ffffff" : Theme.text
                        }
                        Text {
                            visible: text !== ""
                            text: row.tag
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: row.current ? "#ffffff" : Theme.dim
                        }
                    }

                    HoverHandler { id: hover }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { win.sel = row.index; win.apply(); }
                    }
                }
            }

            Text {  // ppd missing or not answering
                visible: win.profiles.length === 0 && !reader.running
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                Layout.leftMargin: 14
                verticalAlignment: Text.AlignVCenter
                text: "power-profiles-daemon not running"
                font.family: Theme.font
                font.pixelSize: 12
                color: Theme.dim
            }
        }

        Rectangle {  // drains until the highlighted profile auto-applies
            anchors { left: parent.left; bottom: parent.bottom }
            height: 2
            width: parent.width * win.remaining
            color: Theme.text
            visible: countdown.running
        }
    }
}
