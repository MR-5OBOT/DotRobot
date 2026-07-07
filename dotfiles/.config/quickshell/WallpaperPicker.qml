import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Wallpaper picker: a horizontal filmstrip of thumbnails, flat/dark, drops in
// from the top-center. Toggle: qs ipc call wallpaper toggle (Super+W).
// Click or Enter applies via hyprpaper; not persisted to hyprpaper.conf.
PanelWindow {
    id: win

    property bool open: false
    property var files: []
    property int sel: 0
    onSelChanged: strip.positionViewAtIndex(sel, ListView.Contain)

    function apply() {
        const p = files[sel];
        if (p) {
            // hyprpaper 0.8: `wallpaper` auto-preloads; `reload` is rejected here
            Quickshell.execDetached(["hyprctl", "hyprpaper", "wallpaper", "," + p]);
            win.open = false;
        }
    }

    onOpenChanged: {
        if (open) {
            sel = 0;
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
            onStreamFinished: win.files = text.split("\n").filter(l => l.length > 0)
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
        anchors.topMargin: win.open ? 8 : -height
        width: card.width
        height: card.height
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Rectangle {
            id: card
            width: col.implicitWidth + 24
            height: col.implicitHeight + 24
            color: Theme.bg

            MouseArea { anchors.fill: parent }  // swallow clicks on the card

            ColumnLayout {
                id: col
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "Wallpaper"
                    font.family: Theme.font
                    font.pixelSize: 13
                    color: Theme.text
                }

                ListView {
                    id: strip
                    readonly property int cellW: 160
                    orientation: ListView.Horizontal
                    // show up to 6 at once; scroll (arrows follow selection) for more
                    Layout.preferredWidth: Math.min(win.files.length, 6) * cellW
                    Layout.preferredHeight: 100
                    clip: true
                    focus: true
                    model: win.files
                    boundsBehavior: Flickable.StopAtBounds

                    Keys.onEscapePressed: win.open = false
                    Keys.onReturnPressed: win.apply()
                    Keys.onEnterPressed: win.apply()
                    Keys.onLeftPressed: win.sel = Math.max(win.sel - 1, 0)
                    Keys.onRightPressed: win.sel = Math.min(win.sel + 1, win.files.length - 1)

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool current: index === win.sel
                        width: strip.cellW
                        height: strip.height

                        Rectangle {
                            anchors { fill: parent; margins: 6 }
                            color: Theme.surface

                            Image {
                                anchors.fill: parent
                                source: "file://" + cell.modelData
                                fillMode: Image.PreserveAspectCrop
                                sourceSize.width: 400
                                asynchronous: true
                                clip: true
                            }

                            HoverHandler { id: hov }

                            Rectangle {  // selection / hover outline, on top of the image
                                anchors.fill: parent
                                visible: cell.current || hov.hovered
                                color: "transparent"
                                border.width: 2
                                border.color: cell.current ? Theme.pink : Theme.dim
                            }

                            Rectangle {  // label strip
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                height: 20
                                color: "#cc101010"
                                Text {
                                    anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                    verticalAlignment: Text.AlignVCenter
                                    text: cell.modelData.split("/").pop()
                                    elide: Text.ElideRight
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    color: (cell.current || hov.hovered) ? "#ffffff" : Theme.dim
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: { win.sel = cell.index; win.apply(); }
                            }
                        }
                    }
                }
            }
        }
    }
}
