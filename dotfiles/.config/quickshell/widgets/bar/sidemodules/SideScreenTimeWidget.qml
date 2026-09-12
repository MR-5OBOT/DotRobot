import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../reusables"
import "../../"

// DotRobot addition: opens the screen-time panel. Same shape as SideTopWidget,
// which upstream uses for its settings button, so it sits in the bar like any
// other module — add "screentime" to bar.modules in settings.json.
Rectangle {
    id: screenTimeRoot

    property var barWindow
    property bool isSolid: false
    property bool distinctPills: barWindow ? (barWindow.distinctPills !== undefined ? barWindow.distinctPills : false) : false
    property bool moduleActive: true
    property bool isGrouped: false
    property bool isCompact: isGrouped || (isSolid && distinctPills)
    property real targetY: 0
    property bool showLayout: barWindow ? Boolean(barWindow.isStartupReady) : true

    y: targetY
    property real targetWidth: barWindow ? (isGrouped ? barWindow.barHeight - 8 : ((isSolid && distinctPills) ? barWindow.barHeight - 6 : barWindow.barHeight)) : (isGrouped ? 22 : ((isSolid && distinctPills) ? 24 : 30))
    property real targetHeight: targetWidth

    width: targetWidth
    height: targetHeight

    radius: ThemeBackend.borderRadius
    border.width: 0
    color: isGrouped ? "transparent" : (isSolid ? (distinctPills ? Qt.darker(ThemeBackend.surface0, 1.15) : "transparent") : ThemeBackend.base)
    clip: true

    opacity: (showLayout && moduleActive) ? ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : 1.0) : 0.0
    visible: opacity > 0
    enabled: moduleActive

    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    IconButton {
        anchors.centerIn: parent
        width: barWindow ? barWindow.s(screenTimeRoot.isCompact ? 28 : 30) : (screenTimeRoot.isCompact ? 28 : 30)
        height: width
        cornerRadius: Math.max(0, ThemeBackend.borderRadius - (barWindow ? barWindow.s(2) : 2))
        buttonIcon: "󰄨"
        iconFontSize: barWindow ? barWindow.s(screenTimeRoot.isCompact ? 14 : 15) : (screenTimeRoot.isCompact ? 14 : 15)
        accentColor: screenTimeRoot.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
        textColor: isHoveredOrHighlighted ? ThemeBackend.text : (screenTimeRoot.isCompact ? ThemeBackend.subtext0 : ThemeBackend.overlay2)
        onClicked: Quickshell.execDetached(["qs", "ipc", "call", "screentime", "toggle"])
    }
}
