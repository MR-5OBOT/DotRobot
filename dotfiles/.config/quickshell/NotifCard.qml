pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// One notification toast. Two layers: outer = entrance (fade+scale), inner card
// = horizontal drag-to-dismiss. Auto-expires (urgency-based, hover pauses).
Item {
    id: root
    required property Notification notif
    property int cardWidth: 300

    readonly property bool critical: notif.urgency === NotificationUrgency.Critical
    readonly property int timeout: notif.expireTimeout > 0 ? notif.expireTimeout : (notif.urgency === NotificationUrgency.Low ? 4000 : critical ? 0 : 8000)

    implicitWidth: cardWidth
    implicitHeight: card.implicitHeight

    // entrance (this layer never fights the drag layer below)
    opacity: 0
    scale: 0.96
    Component.onCompleted: {
        opacity = 1;
        scale = 1;
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Rectangle {
        id: card
        // hug content up to maxWidth (short toasts stay narrow)
        width: parent.width
        implicitHeight: row.implicitHeight + 24
        color: Theme.bg

        // drag-to-dismiss: follow finger, fade with distance, fling off past 30%
        opacity: 1 - Math.min(1, Math.abs(x) / (width * 0.55)) * 0.9
        Behavior on x {
            enabled: !dragH.active
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        DragHandler {
            id: dragH
            target: card
            yAxis.enabled: false
            xAxis.enabled: true
            onActiveChanged: {
                if (!active) {
                    if (Math.abs(card.x) > card.width * 0.3) {
                        card.x = card.x > 0 ? card.width * 1.3 : -card.width * 1.3;  // fling off
                        dismissT.start();
                    } else {
                        card.x = 0;  // spring back
                    }
                }
            }
        }
        // click the body -> invoke default action (open the app) + dismiss.
        // TapHandler coexists with DragHandler (tap vs drag gesture).
        TapHandler {
            onTapped: {
                // "default" action raises the sending app; if none was tagged but a
                // single action exists, use it (some apps skip the identifier).
                const acts = root.notif.actions;
                const def = acts.find(a => a.identifier === "default") ?? (acts.length === 1 ? acts[0] : null);
                if (def)
                    def.invoke();
                root.notif.dismiss();
            }
        }
        Timer {
            id: dismissT
            interval: 200
            onTriggered: root.notif.dismiss()
        }

        // accent stripe (pink, brighter for critical)
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 3
            color: root.critical ? "#c0396b" : Theme.pink
        }

        Timer {
            running: root.timeout > 0 && !hover.hovered && !dragH.active
            interval: root.timeout
            onTriggered: root.notif.expire()
        }

        HoverHandler {
            id: hover
        }

        RowLayout {
            id: row
            anchors.fill: parent
            anchors.margins: 12
            anchors.leftMargin: 15
            spacing: 12

            Loader {
                Layout.alignment: Qt.AlignTop
                active: root.notif.image || root.notif.appIcon
                sourceComponent: root.notif.image ? imageComp : iconComp
            }
            Component {
                id: imageComp
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    color: Theme.surface
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: root.notif.image
                        fillMode: Image.PreserveAspectCrop
                    }
                }
            }
            Component {
                id: iconComp
                IconImage {
                    implicitSize: 40
                    source: Quickshell.iconPath(root.notif.appIcon, "dialog-information")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.notif.appName || "Notification"
                        elide: Text.ElideRight
                        font.family: Theme.font
                        font.pixelSize: 10
                        color: Theme.pink
                    }

                    // close button: hover square + pink, click bounce
                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        color: closeHover.hovered ? Theme.surface : "transparent"
                        scale: closeMA.pressed ? 0.82 : 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }

                        Icon {
                            anchors.centerIn: parent
                            text: "close"
                            size: closeMA.pressed ? 13 : 15
                            color: closeHover.hovered ? Theme.pink : Theme.dim
                            Behavior on size { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        HoverHandler {
                            id: closeHover
                        }
                        MouseArea {
                            id: closeMA
                            anchors.fill: parent
                            onClicked: root.notif.dismiss()
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.notif.summary
                    elide: Text.ElideRight
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.text
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.notif.body.length > 0
                    text: root.notif.body
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    maximumLineCount: 5
                    elide: Text.ElideRight
                    font.family: Theme.font
                    font.pixelSize: 11
                    color: Theme.dim
                    onLinkActivated: link => Quickshell.execDetached(["xdg-open", link])
                }

                RowLayout {
                    Layout.topMargin: 4
                    // "default" is the click-the-body action, never a button
                    visible: root.notif.actions.some(a => a.identifier !== "default")
                    spacing: 8
                    Repeater {
                        model: root.notif.actions.filter(a => a.identifier !== "default")
                        delegate: Rectangle {
                            id: actBtn
                            required property var modelData
                            // outer ids resolve in bindings but NOT in delegate click
                            // handlers here — copy the ref locally so onClicked only
                            // touches delegate-internal ids.
                            readonly property var owner: root.notif
                            implicitWidth: label.implicitWidth + 20
                            implicitHeight: 24
                            color: btnHover.hovered ? Theme.pinkDim : Theme.surface
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                id: label
                                anchors.centerIn: parent
                                text: actBtn.modelData.text
                                font.family: Theme.font
                                font.pixelSize: 11
                                color: Theme.text
                            }
                            HoverHandler {
                                id: btnHover
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    actBtn.modelData.invoke();
                                    actBtn.owner.dismiss();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
