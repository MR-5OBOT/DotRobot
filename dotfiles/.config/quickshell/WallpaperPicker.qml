import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Wallpaper picker: a horizontal filmstrip of thumbnails, flat/dark, drops in
// from the top-center. Toggle: qs ipc call wallpaper toggle (Super+W).
// Click or Enter applies via swww; not persisted across reboots.
PanelWindow {
    id: win

    property bool open: false
    property var files: []
    property int sel: 0   // unbounded step counter; wraps via cur
    readonly property int cur: files.length ? ((sel % files.length) + files.length) % files.length : 0

    function apply() {
        const p = files[cur];
        if (p) {
            // awww animates the new wall in (grows from center), hiding the
            // decode — no fallback flash. swap --transition-type for a different
            // animation: wipe | wave | outer | fade | any | random.
            Quickshell.execDetached(["awww", "img", p,
                "--transition-type", "grow",
                "--transition-pos", "center",
                "--transition-fps", "60",
                "--transition-duration", "0.8"]);
            win.open = false;
        }
    }

    // list once at startup so thumbs decode ahead of the first open (esp. the
    // large focused one); re-list on open only to catch newly-added walls.
    Component.onCompleted: lister.running = true

    onOpenChanged: {
        if (open) {
            sel = 0;
            carousel.pos = 0;
            lister.running = true;
        }
    }

    visible: open || cardWrap.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { win.open = !win.open; }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: win.open = false
    }

    Process {
        id: lister
        // -L: ~/Pictures/wallpapers is a symlink; find won't descend it otherwise.
        command: ["bash", "-c", "find -L \"$HOME/Pictures/wallpapers\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                const next = text.split("\n").filter(l => l.length > 0);
                // only swap the model when it actually changed — otherwise the
                // Repeater rebuilds every tile and redecodes every image on open.
                if (next.join("\n") !== win.files.join("\n"))
                    win.files = next;
            }
        }
    }

    MouseArea {  // click-outside catcher
        anchors.fill: parent
        onClicked: win.open = false
    }

    Item {
        id: cardWrap
        // top-center, drops in from the top edge (matches the workspace island)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: win.open ? 5 : -height   // match the window gap
        width: card.width
        height: card.height
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Rectangle {
            id: card
            width: win.width - 10   // full width minus the 5px window gap each side
            height: 150
            color: Theme.bg

            MouseArea { anchors.fill: parent }  // clicking the panel bg shouldn't close it

            // coverflow: focused thumb centered + large, neighbours shrink and
            // dim as they slide out (ported from ref/pill/Wallpaper.qml, flat).
            Item {
                id: carousel
                anchors.fill: parent
                clip: true
                focus: true

                property real pos: 0
                readonly property var slotW:  [196, 126, 104, 88, 74]
                readonly property var slotH:  [110, 71, 59, 50, 42]
                readonly property var slotCX: [0, 143, 244, 326, 393]
                readonly property var slotB:  [1, 0.56, 0.42, 0.30, 0.22]
                function lerp(a, ao) {
                    if (ao >= 4)
                        return a[4];
                    var i = Math.floor(ao), f = ao - i;
                    return a[i] + (a[i + 1] - a[i]) * f;
                }
                function offX(off) {
                    var ao = Math.abs(off);
                    var cx = ao <= 4 ? lerp(slotCX, ao) : slotCX[4] + (ao - 4) * 60;
                    return off < 0 ? -cx : cx;
                }
                // shortest signed offset on the wrapped ring, so both sides stay full.
                // ponytail: needs ~12+ wallpapers or the far seam peeks in on-screen.
                function woff(off) {
                    var n = win.files.length;
                    if (n <= 0) return off;
                    var o = off % n;
                    if (o > n / 2) o -= n;
                    else if (o < -n / 2) o += n;
                    return o;
                }

                // pos chases sel with an exponential ease, so any input rate stays smooth
                FrameAnimation {
                    running: win.open && carousel.pos !== win.sel
                    onTriggered: {
                        var k = 1 - Math.exp(-frameTime / 0.07);
                        var next = carousel.pos + (win.sel - carousel.pos) * k;
                        carousel.pos = Math.abs(next - win.sel) < 0.001 ? win.sel : next;
                    }
                }

                Keys.onEscapePressed: win.open = false
                Keys.onReturnPressed: win.apply()
                Keys.onEnterPressed: win.apply()
                Keys.onLeftPressed: win.sel -= 1
                Keys.onRightPressed: win.sel += 1
                Keys.onTabPressed: win.sel += 1        // Tab: next (wraps via cur)
                Keys.onBacktabPressed: win.sel -= 1    // Shift+Tab: previous

                Repeater {
                    model: win.files
                    delegate: Item {
                        id: tile
                        required property int index
                        required property var modelData
                        readonly property real off: carousel.woff(index - carousel.pos)
                        readonly property real ao: Math.abs(off)
                        readonly property bool focused: index === win.cur
                        readonly property real bright: carousel.lerp(carousel.slotB, ao)

                        width: carousel.lerp(carousel.slotW, ao)
                        height: carousel.lerp(carousel.slotH, ao)
                        x: carousel.width / 2 + carousel.offX(off) - width / 2
                        y: (carousel.height - height) / 2
                        z: 10 - ao
                        visible: ao <= 5
                        opacity: ao <= 4 ? 1 : Math.max(0, 5 - ao)

                        Image {
                            anchors.fill: parent
                            source: tile.ao <= 6 ? "file://" + tile.modelData : ""
                            sourceSize.width: 400
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                        }
                        Rectangle {  // depth dimming for neighbours
                            anchors.fill: parent
                            color: "black"
                            opacity: 1 - tile.bright
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: tile.focused ? win.apply() : (win.sel += carousel.woff(tile.index - win.cur))
                        }
                    }
                }
            }

            MouseArea {  // wheel scroll (NoButton: clicks fall through to tiles)
                anchors.fill: parent
                z: 15
                acceptedButtons: Qt.NoButton
                property real acc: 0
                onWheel: e => {
                    acc += e.angleDelta.y / 120;
                    const n = Math.trunc(acc);
                    if (n !== 0) {
                        win.sel -= n;
                        acc -= n;
                    }
                    e.accepted = true;
                }
            }
        }
    }
}
