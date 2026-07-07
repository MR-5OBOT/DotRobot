import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// cliphist-backed clipboard history, styled like the bar (dark, 0-radius,
// pink accent). Keyboard-driven like the launcher. Toggle: qs ipc call
// clipboard toggle (Super+V). Enter/click copies the entry via wl-copy.
// Backend: `wl-paste --watch cliphist store` (see autostart/cliphist.sh).
PanelWindow {
    id: win

    property bool open: false
    property string query: ""
    property int sel: 0
    property var items: []       // [{ id, raw, image, label, size }]
    readonly property string cacheDir: "/tmp/qs-cliphist"  // decoded thumbnails, wiped per session
    onSelChanged: list.positionViewAtIndex(sel, ListView.Contain)

    // fresh thumbnail cache each shell session (cliphist ids reset after a wipe)
    Component.onCompleted: Quickshell.execDetached(["sh", "-c", "rm -rf \"$1\" && mkdir -p \"$1\"", "_", cacheDir])

    // empty query shows the whole history (a clipboard manager, not a launcher)
    readonly property var matches: {
        const q = query.toLowerCase().trim();
        if (!q)
            return items;
        return items.filter(e => e.label.toLowerCase().includes(q) || e.size.toLowerCase().includes(q));
    }
    onMatchesChanged: if (sel >= matches.length) sel = Math.max(0, matches.length - 1)

    function copy() {
        const e = matches[sel];
        if (!e)
            return;
        // id passed as argv ($1), never interpolated into the shell string
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "_", String(e.id)]);
        win.open = false;
    }

    function remove() {
        const e = matches[sel];
        if (!e)
            return;
        // documented cliphist delete recipe: pipe the exact list line to `delete`
        actor.command = ["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "_", e.raw];
        actor.running = true;
    }

    function wipe() {
        Quickshell.execDetached(["sh", "-c", "rm -f \"$1\"/*", "_", cacheDir]);
        actor.command = ["cliphist", "wipe"];
        actor.running = true;
    }

    onOpenChanged: {
        if (open) {
            query = "";
            sel = 0;
            input.text = "";
            lister.running = true;
        }
    }

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "clipboard"
        function toggle(): void { win.open = !win.open; }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: win.open = false
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                win.items = text.split("\n").filter(l => l.length > 0).map(line => {
                    const tab = line.indexOf("\t");
                    const id = line.slice(0, tab);
                    const preview = line.slice(tab + 1);
                    // [[ binary data 128 KiB png 397x354 ]]
                    const m = preview.match(/^\[\[ binary data ([\d.]+ \w+) (\w+) (\d+x\d+) \]\]$/);
                    if (m)
                        return { id, raw: line, image: true, label: m[2] + " " + m[3].replace("x", "×"), size: m[1] };
                    return { id, raw: line, image: false, label: preview, size: "" };
                });
            }
        }
    }

    // reused for delete + wipe; refresh the list once the mutation exits.
    // ponytail: user-paced clicks won't overlap a running mutation.
    Process {
        id: actor
        onExited: lister.running = true
    }

    MouseArea {  // click-outside catcher
        anchors.fill: parent
        onClicked: win.open = false
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.12)
        width: 380
        height: col.implicitHeight + 2
        color: Theme.bg

        MouseArea { anchors.fill: parent }  // swallow clicks on the card

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
            spacing: 0

            RowLayout {  // header: paste icon · search · count · clear
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.leftMargin: 14
                Layout.rightMargin: 12
                spacing: 10

                Icon { text: "content_paste"; size: 17; color: Theme.dim }

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    focus: true
                    font.family: Theme.font
                    font.pixelSize: 14
                    color: Theme.text
                    clip: true

                    Text {  // placeholder
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text.length === 0
                        text: "Search clipboard"
                        font.family: Theme.font
                        font.pixelSize: 14
                        color: Theme.dim
                    }
                    onTextChanged: { win.query = text; win.sel = 0; }
                    Keys.onEscapePressed: win.open = false
                    Keys.onReturnPressed: win.copy()
                    Keys.onEnterPressed: win.copy()
                    Keys.onDownPressed: win.sel = Math.min(win.sel + 1, win.matches.length - 1)
                    Keys.onUpPressed: win.sel = Math.max(win.sel - 1, 0)
                    Keys.onTabPressed: win.sel = (win.sel + 1) % Math.max(1, win.matches.length)
                    Keys.onDeletePressed: win.remove()
                }

                Text {
                    text: win.matches.length + " / " + win.items.length
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.dim
                }

                Icon {  // wipe all history
                    text: "delete_sweep"
                    size: 18
                    color: sweepMA.containsMouse ? Theme.pink : Theme.dim
                    Behavior on color { ColorAnimation { duration: 120 } }
                    MouseArea {
                        id: sweepMA
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: win.wipe()
                    }
                }
            }

            Rectangle {  // separator
                Layout.fillWidth: true
                visible: win.matches.length > 0
                height: 1
                color: Theme.border
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(win.matches.length, 8) * 38
                visible: win.matches.length > 0
                clip: true
                model: win.matches

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: index === win.sel

                    width: list.width
                    height: 38
                    color: current ? Theme.pink : (rowHover.hovered ? Theme.surface : "transparent")

                    RowLayout {
                        anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                        spacing: 10

                        Rectangle {  // decoded image thumbnail, lazily cached in /tmp
                            id: thumbBox
                            visible: row.modelData.image
                            implicitWidth: 46
                            implicitHeight: 30
                            color: Theme.surface
                            clip: true

                            readonly property string decodePath: win.cacheDir + "/" + row.modelData.id
                            Image {
                                id: thumb
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.height: 60   // downscale; don't load full-res
                                asynchronous: true
                                cache: false
                            }
                            // ponytail: decode-on-view; `[ -f ]` skips already-cached ids
                            Process {
                                id: dec
                                command: ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\"; [ -f \"$1\" ] || cliphist decode \"$2\" > \"$1\"", "_", thumbBox.decodePath, String(row.modelData.id)]
                                onExited: code => { if (code === 0) thumb.source = "file://" + thumbBox.decodePath; }
                            }
                            Component.onCompleted: if (row.modelData.image) dec.running = true;
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.label
                            elide: Text.ElideRight
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.bold: row.current
                            color: row.current ? "#ffffff" : Theme.text
                        }
                        Text {  // size, images only
                            visible: row.modelData.size.length > 0
                            text: row.modelData.size
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: row.current ? "#ffffff" : Theme.dim
                        }
                        Icon {  // enter hint on the selected row
                            visible: row.current
                            text: "keyboard_return"
                            size: 15
                            color: "#ffffff"
                        }
                    }

                    HoverHandler { id: rowHover }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { win.sel = row.index; win.copy(); }
                    }
                }
            }
        }
    }
}
