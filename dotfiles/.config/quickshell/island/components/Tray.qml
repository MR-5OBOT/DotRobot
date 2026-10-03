pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../Singletons"

/**
 * System tray. Draws StatusNotifier items as warm-tinted icons. Left-click
 * activates (preferring the resolved desktop entry), middle-click does the
 * secondary action, right-click opens the item's native menu in a floating
 * washi card, wheel scrolls the item. The menu gets its own overlay window so
 * it can grab keyboard focus for dismissal.
 */
Item {
    id: tray

    property real s: 1
    property var barWindow

    /**
     * StatusNotifier items shown in the tray. nm-applet stays: its icon and menu
     * are the shell's Wi-Fi UI. blueman is hidden, since Home's Bluetooth button
     * already opens blueman-manager. Matching runs across id, title and tooltip so
     * applet renames stay covered.
     */
    readonly property var trayItems: SystemTray.items.values.filter(function (it) {
        var key = ((it.id || "") + " " + (it.title || "") + " " + (it.tooltipTitle || "")).toLowerCase();
        return !/(blueman|bluetooth[- ]?manager)/.test(key);
    })

    visible: tray.trayItems.length > 0
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: 24 * tray.s

    function showMenu(item, anchorItem) {
        if (!item.hasMenu)
            return;
        card.expandedIdx = -1;
        opener.menu = item.menu;
        var p = anchorItem.mapToItem(null, anchorItem.width / 2, anchorItem.height);
        menu.anchorX = p.x;
        menu.anchorY = p.y;
        menu.open = true;
    }

    QsMenuOpener {
        id: opener
    }

    RowLayout {
        id: row
        anchors.fill: parent
        spacing: 2 * tray.s

        Repeater {
            model: tray.trayItems

            delegate: Item {
                id: slot

                required property var modelData

                Layout.preferredWidth: 24 * tray.s
                Layout.preferredHeight: 24 * tray.s

                Rectangle {
                    anchors.fill: parent
                    radius: 6 * tray.s
                    color: Theme.frameBg
                    border.width: 1
                    border.color: Theme.frameBorder
                    opacity: area.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                }

                Image {
                    anchors.centerIn: parent
                    source: slot.modelData.icon
                    sourceSize.width: 32
                    sourceSize.height: 32
                    width: 16 * tray.s
                    height: 16 * tray.s
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: true
                    asynchronous: true
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.MiddleButton) {
                            slot.modelData.secondaryActivate();
                        } else if (mouse.button === Qt.RightButton) {
                            tray.showMenu(slot.modelData, slot);
                        } else if (slot.modelData.onlyMenu) {
                            tray.showMenu(slot.modelData, slot);
                        } else {
                            slot.modelData.activate();
                        }
                    }
                    onWheel: (wheel) => {
                        slot.modelData.scroll(wheel.angleDelta.y, false);
                    }
                }

                Tooltip {
                    s: tray.s
                    placement: "below"
                    title: slot.modelData.tooltipTitle || slot.modelData.title || slot.modelData.id
                    show: area.containsMouse && !menu.open
                }
            }
        }
    }

    /**
     * One menu line: separator, or a row with optional checkbox/radio state,
     * icon, label and a submenu chevron that rotates when expanded. Used for
     * both top-level entries and indented submenu children.
     */
    component MenuRow: Item {
        id: mrow

        property var entryData

        /**
         * The menu model drops its entries the moment a menu closes, so every
         * binding below would read a property off null for one frame. Read
         * through `e` instead: a plain copy of the entry's fields while one
         * exists, inert defaults while it does not. A copy, not the entry
         * itself: a property holding the entry turns null when it is deleted,
         * and the bindings reading it re-run before `e` could fall back.
         */
        readonly property var e: mrow.entryData ? ({
            isSeparator: mrow.entryData.isSeparator, enabled: mrow.entryData.enabled,
            icon: mrow.entryData.icon, text: mrow.entryData.text,
            buttonType: mrow.entryData.buttonType, checkState: mrow.entryData.checkState,
            hasChildren: mrow.entryData.hasChildren
        }) : ({
            isSeparator: false, enabled: false, icon: "", text: "",
            buttonType: QsMenuButtonType.None, checkState: Qt.Unchecked, hasChildren: false
        })
        property real indent: 0
        property bool expanded: false
        signal activated()

        implicitHeight: mrow.e.isSeparator ? 7 * tray.s : 26 * tray.s
        /** Natural width: the card fits its widest row (the margins below, summed). */
        implicitWidth: mrow.indent + 12 * tray.s
            + (stateBox.present ? 17 * tray.s : 0)
            + (mrow.e.icon ? 22 * tray.s : 0)
            + labelMetrics.advanceWidth
            + (mrow.e.hasChildren === true ? 29 * tray.s : 12 * tray.s)

        /** The label at its hover weight, so hovering a row never resizes the card. */
        TextMetrics {
            id: labelMetrics
            font.family: Theme.font
            font.pixelSize: 11.5 * tray.s
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
            text: mrow.e.text
        }

        Rectangle {
            visible: mrow.e.isSeparator
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 6 * tray.s + mrow.indent
            anchors.rightMargin: 6 * tray.s
            height: 1
            color: Theme.hair
        }

        Rectangle {
            visible: !mrow.e.isSeparator
            anchors.fill: parent
            anchors.leftMargin: mrow.indent
            radius: 6 * tray.s
            color: mrowArea.containsMouse && mrow.e.enabled
                ? Theme.frameBg : "transparent"

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 4 * tray.s
                width: 2 * tray.s
                height: parent.height * 0.46
                radius: width / 2
                color: Theme.vermLit
                opacity: mrowArea.containsMouse && mrow.e.enabled ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
            }

            Rectangle {
                id: stateBox
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12 * tray.s
                readonly property bool isCheck: mrow.e.buttonType === QsMenuButtonType.CheckBox
                readonly property bool isRadio: mrow.e.buttonType === QsMenuButtonType.RadioButton
                readonly property bool present: isCheck || isRadio
                readonly property bool checked: mrow.e.checkState === Qt.Checked
                visible: present
                width: present ? 10 * tray.s : 0
                height: 10 * tray.s
                radius: isRadio ? width / 2 : 3 * tray.s
                color: "transparent"
                border.width: 1
                border.color: checked ? Theme.vermLit : Theme.border

                Rectangle {
                    anchors.centerIn: parent
                    visible: stateBox.checked
                    width: 4 * tray.s
                    height: 4 * tray.s
                    radius: stateBox.isRadio ? width / 2 : 1.5 * tray.s
                    color: Theme.vermLit
                }
            }

            Image {
                id: entryIcon
                anchors.left: stateBox.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: stateBox.present ? 7 * tray.s : 0
                width: mrow.e.icon ? 14 * tray.s : 0
                height: 14 * tray.s
                source: mrow.e.icon
                sourceSize.width: 30
                sourceSize.height: 30
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: true
                visible: mrow.e.icon
            }

            Text {
                anchors.left: entryIcon.right
                anchors.leftMargin: mrow.e.icon ? 8 * tray.s : 0
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: chevron.visible ? chevron.left : parent.right
                anchors.rightMargin: 12 * tray.s
                text: mrow.e.text
                color: !mrow.e.enabled ? Theme.dim
                    : (mrowArea.containsMouse ? Theme.cream : Theme.creamMenu)
                font.family: Theme.font
                font.pixelSize: 11.5 * tray.s
                font.weight: mrowArea.containsMouse ? Font.DemiBold : Font.Normal
                renderType: Text.NativeRendering   // hinted like Home's text, crisp at this size
                elide: Text.ElideRight
            }

            GlyphIcon {
                id: chevron
                anchors.right: parent.right
                anchors.rightMargin: 8 * tray.s
                anchors.verticalCenter: parent.verticalCenter
                visible: mrow.e.hasChildren === true
                width: 9 * tray.s
                height: 9 * tray.s
                name: "chevron-right"
                color: mrow.expanded ? Theme.vermLit : Theme.iconDim
                stroke: 2
                rotation: mrow.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: Motion.fast } }
            }

            MouseArea {
                id: mrowArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: mrow.e.enabled
                cursorShape: Qt.PointingHandCursor
                onClicked: mrow.activated()
            }
        }
    }

    PanelWindow {
        id: menu

        property bool open: false
        property real anchorX: 0
        /** Bottom of the clicked icon: the menu drops from wherever the tray sits. */
        property real anchorY: 0

        onOpenChanged: {
            if (!open) {
                card.expandedIdx = -1;
                opener.menu = null;
            }
        }

        screen: tray.barWindow ? tray.barWindow.screen : null
        visible: open
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "island-tray"

        anchors { top: true; left: true; right: true; bottom: true }

        MouseArea {
            anchors.fill: parent
            onClicked: menu.open = false
        }

        FocusScope {
            anchors.fill: parent
            focus: menu.open

            Keys.onEscapePressed: menu.open = false

            /**
             * Shadow caster kept apart from the labels, as in the Mixer's device menu:
             * a layer over the card would rasterise its text and soften it.
             */
            Rectangle {
                x: card.x
                y: card.y
                width: card.width
                height: card.height
                radius: card.radius
                color: Theme.cardBot
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.shadow
                    shadowBlur: 0.9
                    shadowVerticalOffset: 4 * tray.s
                }
            }

            Rectangle {
                id: card

                x: Math.max(8 * tray.s, Math.min(menu.anchorX - width / 2, menu.width - width - 8 * tray.s))
                y: menu.anchorY + 8 * tray.s
                /** Fits the widest row, within bounds; a label past the cap elides. */
                width: Math.min(260 * tray.s, Math.max(120 * tray.s, col.implicitWidth)) + 8 * tray.s
                radius: 10 * tray.s
                clip: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.cardTop }
                    GradientStop { position: 1.0; color: Theme.cardBot }
                }
                border.width: 1
                border.color: Theme.border

                property int expandedIdx: -1

                implicitHeight: col.implicitHeight + 8 * tray.s
                height: implicitHeight

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: 1
                    anchors.leftMargin: 10 * tray.s
                    anchors.rightMargin: 10 * tray.s
                    height: 1
                    color: Theme.sheen
                }

                MouseArea { anchors.fill: parent }

                /* Layouts, not Columns: their implicitWidth is the widest row's, which the
                   card sizes to, while fillWidth still stretches every row to the card. */
                ColumnLayout {
                    id: col
                    x: 4 * tray.s
                    y: 4 * tray.s
                    width: card.width - 8 * tray.s
                    spacing: 0

                    Repeater {
                        model: opener.children ? opener.children.values : []

                        delegate: ColumnLayout {
                            id: entry

                            required property var modelData
                            required property int index
                            readonly property bool expanded: card.expandedIdx === index

                            Layout.fillWidth: true
                            spacing: 0

                            MenuRow {
                                Layout.fillWidth: true
                                entryData: entry.modelData
                                expanded: entry.expanded
                                onActivated: {
                                    if (entry.modelData.hasChildren) {
                                        card.expandedIdx = entry.expanded ? -1 : entry.index;
                                    } else {
                                        entry.modelData.triggered();
                                        menu.open = false;
                                    }
                                }
                            }

                            QsMenuOpener {
                                id: childOpener
                                menu: entry.expanded ? entry.modelData : null
                            }

                            Repeater {
                                model: childOpener.children ? childOpener.children.values : []

                                delegate: MenuRow {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    indent: 12 * tray.s
                                    entryData: modelData
                                    onActivated: {
                                        if (!modelData.hasChildren) {
                                            modelData.triggered();
                                            menu.open = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
