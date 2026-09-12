import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "serp"

// Power-profile picker: `qs ipc call powerprofile cycle` (SUPER+SHIFT+P via
// `powerprofile menu`) opens the card on the active profile, and each further
// press moves the highlight on. Nothing switches until you pick — Enter or a
// click applies, Esc cancels. Same drop-in card and rows as ActionMenu, both
// drawn to match serpantinum's Wi-Fi/Bluetooth panel (see MenuRow.qml).
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

    function cycle() {
        if (!open) {
            sel = -1;
            queued = 0;   // the first press only opens; it must not move off the active profile
            open = true;
            reader.running = true;
        } else if (reader.running) {
            queued++;
        } else if (profiles.length > 0) {
            sel = (sel + 1) % profiles.length;
        }
    }

    function move(d) {
        if (profiles.length === 0)
            return;
        sel = (sel + d + profiles.length) % profiles.length;
    }

    function apply() {
        const p = profiles[sel];
        if (p && p !== active)
            Quickshell.execDetached(["powerprofilesctl", "set", p]);
        open = false;
    }

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
            }
        }
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
        width: 260
        height: col.implicitHeight + 16
        radius: ThemeBackend.borderRadius
        color: ThemeBackend.base
        border.color: ThemeBackend.surface0
        border.width: 1

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
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 4

            RowLayout {  // header
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 2
                spacing: 8
                Icon { text: "speed"; size: 14; color: ThemeBackend.overlay1 }
                Text {
                    Layout.fillWidth: true
                    text: "Power profile"
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: 11
                    color: ThemeBackend.overlay1
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.bottomMargin: 4; color: ThemeBackend.surface0 }

            Repeater {
                model: win.profiles
                delegate: MenuRow {
                    id: row
                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight

                    icon: win.meta[modelData].icon
                    label: win.meta[modelData].label
                    // a degraded reason matters more than the active marker
                    tag: modelData === "performance" && win.degraded !== "" ? win.degraded : modelData === win.active ? "active" : ""
                    selected: index === win.sel
                    onHoveredChanged: if (hovered) win.sel = row.index
                    onClicked: { win.sel = row.index; win.apply(); }
                }
            }

            Text {  // ppd missing or not answering
                visible: win.profiles.length === 0 && !reader.running
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                Layout.leftMargin: 12
                verticalAlignment: Text.AlignVCenter
                text: "power-profiles-daemon not running"
                font.family: ThemeBackend.fontFamily
                font.pixelSize: 11
                color: ThemeBackend.overlay1
            }
        }
    }
}
