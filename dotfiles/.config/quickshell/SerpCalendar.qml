import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "serp"
import "serp/calendar"

// Host window for serpantinum's calendar + clock dashboard
// (serp/calendar/CalendarPopup.qml, AGPL-3.0 — see serp/README.md). That file
// is a bare 1360x510 Item: it draws itself and nothing else, so opening,
// closing, Escape, the click-outside and the scaling all live here.
// Toggle with:  qs ipc call serpcalendar toggle
PanelWindow {
    id: win
    property bool open: false

    visible: open
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-serpcalendar"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    IpcHandler {
        target: "serpcalendar"
        function toggle(): void { win.open = !win.open; }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: win.open = false
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: win.open = false

        MouseArea {   // click outside the panel closes it
            anchors.fill: parent
            onClicked: win.open = false
        }

        // Serpantinum draws this at a fixed 1360x510 — wider than this screen
        // (1280x720 logical at 1.5x). Keep it to a share of the screen instead
        // of merely fitting it: serp/settings.json -> calendar.screenFraction.
        Item {
            id: holder
            anchors.centerIn: parent
            readonly property real fraction: Config.rawSettings.calendar?.screenFraction ?? 0.78
            readonly property real f: Math.min(1, win.width * fraction / popup.implicitWidth, win.height * fraction / popup.implicitHeight)
            width: popup.implicitWidth * f
            height: popup.implicitHeight * f

            // Under the popup: absorbs clicks on the panel's own background so
            // they don't reach the close handler. It must stay *below*, or it
            // swallows the clicks meant for the month and day arrows.
            MouseArea { anchors.fill: parent }

            SerpCalendarPopup {
                id: popup
                visible: win.open
                transformOrigin: Item.TopLeft
                scale: holder.f
            }
        }
    }
}
