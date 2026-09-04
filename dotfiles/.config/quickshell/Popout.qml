import QtQuick
import Quickshell

// Reusable hover popup: anchored to a bar item, opens flush to the RIGHT of the
// bar and reads as an extension of it (no border). Stays open while either the
// bar item or the popup is hovered, with a short close delay to cross the gap.
Scope {
    id: root

    required property Item anchorItem
    property Component contentComponent
    property int pad: 14

    property bool itemHovered: false
    property bool popHovered: false
    property bool open: false

    // gate on BarState.settled so a fast hover can't open a popup anchored to a
    // half-revealed (still-sliding) bar item.
    readonly property bool shouldShow: (itemHovered || popHovered) && BarState.settled
    onShouldShowChanged: {
        if (shouldShow) {
            closeT.stop();
            open = true;
        } else {
            closeT.restart();
        }
    }

    // keep the auto-hiding bar revealed while this popup is up
    onOpenChanged: {
        if (open)
            BarState.activePopup = root;
        else if (BarState.activePopup === root)
            BarState.activePopup = null;
    }
    Component.onDestruction: if (BarState.activePopup === root)
        BarState.activePopup = null

    Timer {
        id: closeT
        interval: 160
        onTriggered: root.open = false
    }

    PopupWindow {
        id: win

        // anchored to the bar's visible band, flush right and vertically centred
        // on it — every popout opens in the same spot, always inside the bar height
        readonly property Item band: BarState.barContent ?? root.anchorItem
        anchor.item: band
        anchor.edges: Edges.Top | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.rect.x: band.width              // right edge of the band
        anchor.rect.y: (band.height - implicitHeight) / 2

        // stay visible through the fade-out so closing animates too
        visible: root.open || card.opacity > 0.01
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        color: "transparent"

        Rectangle {
            id: card
            implicitWidth: loader.item ? loader.item.implicitWidth + root.pad * 2 : 100
            implicitHeight: loader.item ? loader.item.implicitHeight + root.pad * 2 : 60
            color: Theme.bg

            // hover anim: fade (M3 effects curve) + grow out of the bar edge
            // with a gentle overshoot (M3 expressive spatial curve).
            transformOrigin: Item.Left
            opacity: root.open ? 1 : 0
            scale: root.open ? 1 : 0.9
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.34, 0.8, 0.34, 1, 1, 1]
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: [0.38, 1.21, 0.22, 1, 1, 1]
                }
            }

            HoverHandler {
                onHoveredChanged: root.popHovered = hovered
            }

            Loader {
                id: loader
                anchors.centerIn: parent
                sourceComponent: root.contentComponent
            }
        }
    }
}
