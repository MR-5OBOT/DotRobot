pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../Singletons"
import "../components"

Item {
    id: root
    property real s: 1
    property bool open: false
    property var pinnedApps: []
    enabled: open
    signal requestClose()

    onOpenChanged: {
        if (open) seenTimer.restart();
        else {
            seenTimer.stop();
            pinnedApps = [];
        }
    }
    Timer { id: seenTimer; interval: 600; onTriggered: Notifs.markAllSeen() }

    component IconButton: ToolButton {
        id: button
        required property string glyph
        required property string label
        implicitWidth: 32 * root.s
        implicitHeight: 32 * root.s
        padding: 8 * root.s
        Accessible.name: label
        ToolTip.visible: hovered
        ToolTip.text: label
        background: Rectangle {
            color: button.hovered || button.activeFocus ? Theme.frameBg : "transparent"
            border.width: button.activeFocus ? 1 : 0
            border.color: Theme.vermLit
        }
        contentItem: GlyphIcon { name: button.glyph; color: Theme.iconDim }
    }

    component AppIcon: Rectangle {
        id: tile
        required property var notification
        width: 24 * root.s
        height: width
        color: "transparent"
        Image {
            id: appImage
            property var failedFor: null
            anchors.fill: parent
            anchors.margins: 5 * root.s
            source: failedFor !== tile.notification && /^(\/|file:\/\/)/.test(tile.notification.appIcon || "")
                ? tile.notification.appIcon : Notifs.appIconFor(tile.notification)
            onStatusChanged: if (status === Image.Error) {
                const notification = tile.notification;
                Qt.callLater(() => appImage.failedFor = notification);
            }
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready
        }
        GlyphIcon {
            anchors.centerIn: parent
            width: 16 * root.s
            height: width
            visible: !appImage.visible
            name: "app-window"
            color: Theme.vermLit
        }
    }

    component NotificationCard: Button {
        id: card
        required property var entry
        required property string appName
        required property int appCount
        readonly property var n: entry.n
        readonly property bool critical: n.urgency === 2
        readonly property bool unread: entry.live && !Notifs.seenIds[n.id]
        padding: 10 * root.s
        implicitHeight: details.implicitHeight + topPadding + bottomPadding
        hoverEnabled: true
        Accessible.name: (n.summary || "") + ". " + (n.body || "")
        onClicked: {
            Notifs.activateEntry(entry);
            root.requestClose();
        }
        background: Rectangle {
            color: card.hovered ? Qt.alpha(Theme.cream, 0.075) : Theme.tileBg
            border.width: 1
            border.color: card.activeFocus || card.critical ? Theme.vermLit : Theme.hairSoft
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        contentItem: Column {
            id: details
            spacing: 4 * root.s
            Item {
                width: parent.width
                height: 24 * root.s
                ToolButton {
                    id: appToggle
                    objectName: "notificationAppIcon"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 24 * root.s
                    implicitHeight: 24 * root.s
                    padding: 0
                    Accessible.name: card.appName + ", " + card.appCount + " notifications. Toggle group."
                    ToolTip.visible: hovered
                    ToolTip.text: card.appName + " · " + card.appCount
                    onClicked: root.pinnedApps = root.pinnedApps.includes(card.appName)
                        ? root.pinnedApps.filter(app => app !== card.appName)
                        : root.pinnedApps.concat([card.appName])
                    background: Rectangle {
                        color: "transparent"
                        border.width: appToggle.activeFocus ? 1 : 0
                        border.color: Theme.vermLit
                    }
                    contentItem: AppIcon { notification: card.n }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: appMenu.popup()
                    }
                    Menu {
                        id: appMenu
                        MenuItem {
                            text: "Clear notifications for this app"
                            onTriggered: Notifs.dismissApp(card.appName)
                        }
                    }
                }
                Text {
                    anchors.left: appToggle.right
                    anchors.leftMargin: 8 * root.s
                    anchors.right: dismiss.left
                    anchors.rightMargin: 6 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: (card.n.summary || card.n.appName || card.n.app || "Notification")
                        + (card.entry.count > 1 ? "  ×" + card.entry.count : "")
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    font.weight: Font.DemiBold
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }
                IconButton {
                    id: dismiss
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 26 * root.s
                    implicitHeight: 26 * root.s
                    padding: 6 * root.s
                    glyph: "close"
                    label: "Dismiss notification"
                    onClicked: Notifs.dismissEntry(card.entry)
                }
            }
            Row {
                width: parent.width
                spacing: 10 * root.s
                visible: bodyText.text.length > 0 || preview.visible
                Image {
                    id: preview
                    width: 32 * root.s
                    height: width
                    source: card.n.image || ""
                    sourceSize.width: 88
                    sourceSize.height: 88
                    fillMode: Image.PreserveAspectFit
                    visible: source.toString().length > 0 && status === Image.Ready
                }
                Text {
                    id: bodyText
                    width: parent.width - (preview.visible ? preview.width + parent.spacing : 0)
                    text: card.n.body || ""
                    textFormat: Text.PlainText
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    lineHeight: 1.15
                }
            }
            Row {
                spacing: 5 * root.s
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 5 * root.s
                    height: width
                    visible: card.unread
                    color: Theme.vermLit
                }
                Text {
                    text: (card.critical ? "Important · " : "") + Notifs.ageLabel(card.n)
                    color: card.critical ? Theme.vermLit : Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 9 * root.s
                }
            }
            Flow {
                width: parent.width
                spacing: 6 * root.s
                visible: actions.count > 0
                Repeater {
                    id: actions
                    model: card.entry.live ? (card.n.actions || []).filter(a => a.identifier !== "default") : []
                    delegate: Button {
                        id: actionButton
                        required property var modelData
                        text: modelData.text
                        font.family: Theme.font
                        font.pixelSize: 11 * root.s
                        padding: 7 * root.s
                        onClicked: modelData.invoke()
                        background: Rectangle {
                            color: Theme.frameBg
                            border.width: 1
                            border.color: actionButton.activeFocus ? Theme.vermLit : Theme.border
                        }
                        contentItem: Text {
                            text: actionButton.text
                            textFormat: Text.PlainText
                            color: Theme.cream
                            font: actionButton.font
                        }
                    }
                }
            }
        }
    }

    Column {
        id: header
        width: parent.width
        spacing: 14 * root.s
        Item {
            width: parent.width
            height: 34 * root.s
            Text {
                anchors.left: parent.left
                anchors.right: headerActions.left
                anchors.rightMargin: 12 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 22 * root.s
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Row {
                id: headerActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2 * root.s
                IconButton {
                    glyph: Flags.dnd ? "moon" : "inbox"
                    label: Flags.dnd ? "Turn off Do not disturb" : "Turn on Do not disturb"
                    onClicked: Flags.dnd = !Flags.dnd
                    background: Rectangle {
                        color: Flags.dnd ? Qt.alpha(Theme.vermLit, 0.15) : "transparent"
                    }
                }
                IconButton {
                    enabled: Notifs.count > 0
                    opacity: enabled ? 1 : 0.35
                    glyph: "trash"
                    label: "Clear all notifications"
                    onClicked: Notifs.clearAll()
                }
                IconButton {
                    glyph: "close"
                    label: "Close notifications · Esc"
                    onClicked: root.requestClose()
                }
            }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.hairSoft }
    }

    Flickable {
        id: list
        objectName: "notificationList"
        anchors.top: header.bottom
        anchors.topMargin: 20 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: groups.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        onContentHeightChanged: returnToBounds()
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: groups
            width: list.width
            spacing: 14 * root.s
            Repeater {
                model: Notifs.groups
                delegate: Item {
                    id: group
                    required property var modelData
                    objectName: "notificationGroup-" + modelData.app
                    readonly property var entries: modelData.criticals.concat(modelData.entries)
                    readonly property bool pinned: root.pinnedApps.includes(modelData.app)
                    property bool peek: false
                    readonly property bool expanded: pinned || peek
                    readonly property int layers: Math.min(2, entries.length - 1)
                    width: groups.width
                    height: stack.height

                    Connections {
                        target: root
                        function onOpenChanged() {
                            if (!root.open) group.peek = false;
                        }
                    }
                    HoverHandler {
                        id: groupHover
                        onHoveredChanged: {
                            if (hovered) { collapse.stop(); expand.restart(); }
                            else { expand.stop(); collapse.restart(); }
                        }
                    }
                    Timer { id: expand; interval: 100; onTriggered: group.peek = true }
                    Timer { id: collapse; interval: 180; onTriggered: group.peek = false }

                    Item {
                        id: stack
                        anchors.top: parent.top
                        width: parent.width
                        height: group.expanded ? cards.implicitHeight : firstCard.height + group.layers * 7 * root.s
                        clip: true
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                        Repeater {
                            model: group.layers
                            delegate: Rectangle {
                                required property int index
                                readonly property int depth: group.layers - index
                                x: depth * 7 * root.s
                                y: depth * 7 * root.s
                                width: stack.width - 2 * x
                                height: firstCard.height
                                color: Qt.lighter(Theme.tileBg, 1 + depth * 0.14)
                                border.width: 1
                                border.color: Theme.hairSoft
                                opacity: group.expanded ? 0 : 1
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }
                        Column {
                            id: cards
                            width: parent.width
                            spacing: 8 * root.s
                            NotificationCard {
                                id: firstCard
                                width: parent.width
                                entry: group.entries[0]
                                appName: group.modelData.app
                                appCount: group.modelData.count
                            }
                            Repeater {
                                model: group.expanded ? group.entries.slice(1) : []
                                delegate: NotificationCard {
                                    required property var modelData
                                    width: cards.width
                                    entry: modelData
                                    appName: group.modelData.app
                                    appCount: group.modelData.count
                                }
                            }
                        }
                    }
                }
            }
        }
        WheelScroller { anchors.fill: parent; s: root.s; flick: list }
    }

    Column {
        anchors.centerIn: list
        width: parent.width
        spacing: 15 * root.s
        visible: Notifs.count === 0
        GlyphIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 38 * root.s
            height: width
            name: "inbox"
            color: Theme.faint
        }
        Text {
            width: parent.width
            text: "A little peace and quiet"
            horizontalAlignment: Text.AlignHCenter
            color: Theme.cream
            font.family: Theme.font
            font.pixelSize: 15 * root.s
            font.weight: Font.DemiBold
        }
        Text {
            width: parent.width
            text: "New notifications will be collected here."
            horizontalAlignment: Text.AlignHCenter
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }
    }

}
