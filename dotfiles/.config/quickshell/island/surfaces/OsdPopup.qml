pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../Singletons"
import "../components"

/**
 * Standalone OSD overlay, fully decoupled from the pill. The pill never morphs
 * for volume/brightness/workspace flashes anymore; this capsule shows itself at
 * its final size, slides in from the left for workspaces or the top otherwise,
 * holds for the flash timeout, then retracts. Content stays at fixed geometry
 * the whole time, so the level bars never stretch with the transition.
 */
Item {
    id: popup

    property real s: 1
    property string screenName: ""
    property bool suppressed: false
    property bool expanded: false

    /**
     * 1 when the popup should dock flush to the screen top like the strip bar
     * (squared top corners); 0 for the rounded island capsule. Mirrors the
     * pill's own top-flat rule so the OSD keeps each display mode's silhouette.
     */
    property real topFlat: 0
    Behavior on topFlat { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }

    readonly property bool active: osd.flashing
    readonly property bool workspace: osd.kind === "workspace"
    property real reveal: active ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: popup.active ? Motion.standard : Motion.fast
            easing.type: popup.active ? Easing.OutCubic : Easing.InCubic
        }
    }

    width: osd.desiredW
    height: osd.desiredH

    // Retract through the same edge the popup is anchored to.
    visible: reveal > 0.001
    transform: Translate {
        x: popup.workspace ? (popup.reveal - 1) * popup.width : 0
        y: popup.workspace ? 0 : (popup.reveal - 1) * popup.height
    }

    Rectangle {
        anchors.fill: parent
        radius: 22 * s
        topLeftRadius: popup.workspace ? 0 : 22 * s * (1 - topFlat)
        topRightRadius: popup.workspace ? 22 * s : 22 * s * (1 - topFlat)
        bottomLeftRadius: popup.workspace ? 0 : 22 * s
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Theme.cardTop, Flags.pillOpacity) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.cardBot, Flags.pillOpacity) }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, Theme.shadowOpacity)
            shadowBlur: 0.7
            shadowVerticalOffset: 3 * s
        }

    }

    NotchEars {
        anchors.top: parent.top
        width: parent.width
        r: 14 * popup.s
        color: Qt.alpha(Theme.cardTop, Flags.pillOpacity)
        opacity: popup.workspace ? 0 : popup.topFlat
    }

    Osd {
        id: osd
        anchors.fill: parent
        anchors.topMargin: 12 * s
        anchors.leftMargin: 18 * s
        anchors.rightMargin: 18 * s
        anchors.bottomMargin: 12 * s
        s: popup.s
        screenName: popup.screenName
        suppressed: popup.suppressed
        expanded: popup.expanded
    }
}
