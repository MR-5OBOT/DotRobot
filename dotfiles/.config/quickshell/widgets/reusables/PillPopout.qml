import QtQuick
import Quickshell
import "../"

// Hover card for a bar pill. The bar is 40px wide, so anything past a glyph has
// to leave it: this is a PopupWindow anchored to the pill, opening flush to its
// right and vertically centred on it.
//
// The caller drives `itemHovered` from its own hover handler and drops the
// contents in `contentComponent`. The card holds itself open while the pointer
// is on it, so the contents can be interactive; content that drags (a slider)
// should bind `keepOpen` so the card survives a pointer that leaves it mid-drag.
Item {
    id: root

    property Item anchorItem
    property Component contentComponent
    property bool itemHovered: false
    property bool keepOpen: false
    property real gap: 10           // space between pill and card
    property real pad: 11           // card padding around the contents
    property int openDelay: 320     // a beat, so crossing the bar doesn't flash it
    property int closeDelay: 140    // shorter, so the gap can be crossed without a blink

    width: 0
    height: 0

    // The bar window, if it wants to know: while the card is open it adds one to
    // host.popoutHolds, which an autohiding bar treats as "stay revealed".
    property var host: null
    property bool holding: false
    function setHold(on) {
        if (on === holding || !host || host.popoutHolds === undefined)
            return;
        host.popoutHolds += on ? 1 : -1;
        holding = on;
    }
    Component.onDestruction: setHold(false)

    property bool open: false
    onOpenChanged: setHold(open)
    property bool cardHovered: false
    readonly property bool wanted: anchorItem !== null && (itemHovered || cardHovered || keepOpen)
    onWantedChanged: {
        if (wanted) {
            closeT.stop();
            openT.restart();
        } else {
            openT.stop();
            closeT.restart();
        }
    }
    Timer { id: openT; interval: root.openDelay; onTriggered: root.open = true }
    Timer { id: closeT; interval: root.closeDelay; onTriggered: root.open = false }

    PopupWindow {
        id: win
        anchor.item: root.anchorItem
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.rect.x: root.anchorItem ? root.anchorItem.width + root.gap : 0
        anchor.rect.y: root.anchorItem ? (root.anchorItem.height - implicitHeight) / 2 : 0

        // stay mapped through the fade-out so closing isn't a jump cut
        visible: root.open || card.opacity > 0.01
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        color: "transparent"

        Rectangle {
            id: card
            implicitWidth: (loader.item ? loader.item.implicitWidth : 0) + root.pad * 2
            implicitHeight: (loader.item ? loader.item.implicitHeight : 0) + root.pad * 2
            radius: ThemeBackend.borderRadius
            color: ThemeBackend.mantle
            border.width: 1
            border.color: ThemeBackend.surface1

            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

            HoverHandler {
                onHoveredChanged: root.cardHovered = hovered
            }

            Loader {
                id: loader
                anchors.centerIn: parent
                sourceComponent: root.contentComponent
            }
        }
    }
}
