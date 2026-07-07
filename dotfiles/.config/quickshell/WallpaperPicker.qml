import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Wallpaper grid, square/dark style, soft shadow (no border). Spans the
// maximized-window area: anchored top, full width, inset by the same gap a
// tiled window leaves. Toggle: qs ipc call wallpaper toggle (Super+W).
// Click or Enter applies via hyprpaper; not persisted to hyprpaper.conf.
PanelWindow {
    id: win

    property bool open: false
    property var files: []
    property int sel: 0
    onSelChanged: grid.positionViewAtIndex(sel, GridView.Contain)

    function apply() {
        const p = files[sel];
        if (p) {
            Quickshell.execDetached(["hyprctl", "hyprpaper", "reload", "," + p]);
            win.open = false;
        }
    }

    onOpenChanged: {
        if (open) {
            sel = 0;
            lister.running = true;
        }
    }

    visible: open
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
        anchors.horizontalCenter: parent.horizontalCenter
        y: 48                       // float near the top
        width: card.width
        height: card.height

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

                GridView {
                    id: grid
                    readonly property int cols: 3
                    readonly property int rows: Math.ceil(win.files.length / cols)
                    cellWidth: 160
                    cellHeight: 100
                    Layout.preferredWidth: cellWidth * cols
                    Layout.preferredHeight: cellHeight * Math.min(rows, 3)
                    clip: true
                    focus: true
                    model: win.files

                    Keys.onEscapePressed: win.open = false
                    Keys.onReturnPressed: win.apply()
                    Keys.onEnterPressed: win.apply()
                    Keys.onLeftPressed: win.sel = Math.max(win.sel - 1, 0)
                    Keys.onRightPressed: win.sel = Math.min(win.sel + 1, win.files.length - 1)
                    Keys.onUpPressed: win.sel = Math.max(win.sel - cols, 0)
                    Keys.onDownPressed: win.sel = Math.min(win.sel + cols, win.files.length - 1)

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool current: index === win.sel
                        width: grid.cellWidth
                        height: grid.cellHeight

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
