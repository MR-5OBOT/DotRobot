import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

// Freedesktop notification daemon + top-right toast stack. Replaces swaync/dunst.
// Only one process can own org.freedesktop.Notifications, so swaync must be off.
Scope {
    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => n.tracked = true
    }

    PanelWindow {
        anchors { top: true; right: true }
        implicitWidth: col.implicitWidth + 20
        implicitHeight: Math.max(1, col.implicitHeight + 20)
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-notifications"
        visible: server.trackedNotifications.values.length > 0

        // only the cards are interactive; rest of the strip clicks through
        mask: Region {
            item: col
        }

        ColumnLayout {
            id: col
            anchors { top: parent.top; right: parent.right; topMargin: 10; rightMargin: 10 }
            spacing: 8

            Repeater {
                model: server.trackedNotifications
                delegate: NotifCard {
                    required property var modelData
                    notif: modelData
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }
}
