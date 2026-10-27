import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "widgets"
import "island/Singletons" as Island
import "island/components" as IslandUi

// Power-profile picker: `qs ipc call powerprofile cycle` (SUPER+SHIFT+P via
// `powerprofile menu`) opens the card on the active profile, and each further
// press moves the highlight on. Nothing switches until you pick — Enter or a
// click applies, Esc cancels. Rows are MenuRow.qml;
// the card is a top-edge notch in the island's style, also opened from its battery panel.
PanelWindow {
    id: win

    readonly property var meta: ({
        "power-saver": { icon: "eco", label: "Power saver" },
        "balanced": { icon: "balance", label: "Balanced" },
        "performance": { icon: "bolt", label: "Performance" }
    })

    property bool open: false
    readonly property real drop: open ? card.height : 0  // island drops toasts below the card
    readonly property var profiles: Island.Battery.profiles     // ids this machine offers, saver -> performance
    readonly property string active: Island.Battery.profile
    readonly property string degraded: Island.Battery.degraded  // why ppd holds performance back, "" if it doesn't
    property int sel: -1

    function cycle() {
        if (!open) {
            sel = Math.max(0, profiles.indexOf(active));   // the first press only opens, on the active profile
            open = true;
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
            Island.Battery.setProfile(p);
        open = false;
    }

    IpcHandler {
        target: "powerprofile"
        function cycle(): void { win.cycle(); }
    }

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    mask: BarState.widgetMask
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-powerprofile"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        active: win.open
        windows: [win].concat(BarState.islandWindows)
        onCleared: win.open = false
    }

    MouseArea { anchors.fill: parent; onClicked: win.open = false }  // click-outside

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: win.open ? 0 : -height   // hangs flush from the top edge and slides out of it
        width: 260
        height: col.implicitHeight + 16
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Theme.notchRadius
        bottomRightRadius: Theme.notchRadius
        color: Theme.notchBg

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }  // swallow clicks on the card

        IslandUi.NotchEars {
            anchors.top: parent.top
            width: parent.width
        }

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
                    accent: Theme.notchAccent
                    onHoveredChanged: if (hovered) win.sel = row.index
                    onClicked: { win.sel = row.index; win.apply(); }
                }
            }
        }
    }
}
