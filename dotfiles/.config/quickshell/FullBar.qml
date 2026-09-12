import QtQuick
import Quickshell
import Quickshell.Wayland
import "widgets"
import "widgets/bar"

// Serpantinum's side bar (github.com/ilyamiro/serpantinum, AGPL-3.0; what was
// vendored and changed is in widgets/README.md), hosted here instead of in its own
// Bar.qml, which also pulls in the top bar, OSD and tutorial plumbing.
// Full height; reserves its width so windows sit beside it. Style, modules
// and workspace count come from widgets/settings.json. Swap with Bar in shell.qml.
PanelWindow {
    id: barWindow
    required property var modelData
    screen: modelData

    // settings: widgets/settings.json -> bar
    readonly property var cfg: Config.rawSettings.bar ?? ({})
    readonly property string barPosition: cfg.position === "right" ? "right" : "left"   // SideBar is vertical-only
    readonly property bool isVertical: true
    readonly property string barStyle: typeof cfg.style === "string" ? cfg.style : "modular"
    readonly property bool isFill: barStyle === "fill"
    readonly property bool distinctPills: cfg.distinctPills ?? false
    readonly property bool autohide: cfg.autohide ?? false
    readonly property real barOpacity: (cfg.opacity ?? 100) / 100
    readonly property real barWidthPercent: cfg.width ?? 100

    // geometry the modules read off barWindow
    function s(val) { return Math.round(val); }   // serpantinum's Scaler is identity
    readonly property int barHeight: 40            // the bar's thickness, despite the name
    // 0 = square where the bar meets the screen edge; serpantinum's fill
    // style rounds it off with an inverted corner (bar.cornerRadius)
    readonly property real cornerRadius: cfg.cornerRadius ?? 0
    readonly property real edgePadding: autohide && !isFill ? 4 : 0
    readonly property real effectiveBarHeight: Math.round(isFill ? height : (height - (autohide ? edgePadding * 2 : 0)) * barWidthPercent / 100)
    readonly property real verticalOffset: Math.round(isFill ? 0 : (height - effectiveBarHeight) / 2)
    readonly property real baseOffsetY: 0   // SideBar watches this; vertical bars never offset

    readonly property real currentBarMinY: sideBar.dynamicMaxY > sideBar.dynamicMinY ? sideBar.dynamicMinY : verticalOffset
    readonly property real currentBarMaxY: sideBar.dynamicMaxY > sideBar.dynamicMinY ? sideBar.dynamicMaxY : verticalOffset + effectiveBarHeight

    // staged startup: modules fade and slide in on these
    property bool positionChanging: false
    property bool isStartupReady: false
    property bool isDataReady: false
    property bool fastPollerLoaded: false
    property bool startupCascadeFinished: false
    Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }
    Timer { interval: 400; running: true; onTriggered: barWindow.isDataReady = true }
    Timer { interval: 1050; running: true; onTriggered: barWindow.startupCascadeFinished = true }

    // autohide (bar.autohide), off by default
    HoverHandler { id: hover }
    Timer { id: hideTimer; interval: barWindow.cfg.autohideTimeout ?? 1000 }
    Connections {
        target: hover
        function onHoveredChanged() {
            if (!hover.hovered && barWindow.autohide)
                hideTimer.restart();
            else
                hideTimer.stop();
        }
    }
    readonly property bool isRevealed: !autohide || hover.hovered || hideTimer.running

    visible: Config.dataReady
    color: "transparent"
    WlrLayershell.namespace: "quickshell-fullbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // Responsive height: the window is only as tall as the modules and rides
    // centred on its edge, so the wallpaper shows above and below it.
    // widgets/settings.json -> bar.fitContent; false restores the full-height bar.
    readonly property bool fitContent: cfg.fitContent ?? true
    readonly property real contentHeight: sideBar.tHeightTarget + sideBar.cHeightTarget + sideBar.bHeightTarget
                                          + sideBar.tcGap + sideBar.cbGap + 2 * sideBar.fillInset + 16
    implicitHeight: fitContent ? Math.round(contentHeight) : 0
    anchors { top: !fitContent; bottom: !fitContent; left: barPosition === "left"; right: barPosition === "right" }
    margins {
        top: isFill || autohide ? 0 : 4
        bottom: isFill || autohide ? 0 : 4
        left: isFill || autohide || barPosition === "right" ? 0 : 4
        right: isFill || autohide || barPosition === "left" ? 0 : 4
    }
    implicitWidth: barHeight + (isFill ? cornerRadius : edgePadding)
    exclusiveZone: !Config.dataReady || autohide ? 0 : barHeight

    // input: the bar strip, plus (fill style) the two rounded inner corners
    readonly property real stripWidth: autohide && !isRevealed ? 4 : barHeight + edgePadding
    readonly property real innerX: barPosition === "right" ? width - barHeight - cornerRadius : barHeight
    mask: Region {
        Region {
            x: barWindow.barPosition === "right" ? barWindow.width - barWindow.stripWidth : 0
            y: barWindow.isFill ? 0 : barWindow.currentBarMinY
            width: barWindow.stripWidth
            height: barWindow.isFill ? barWindow.height : barWindow.currentBarMaxY - barWindow.currentBarMinY
        }
        Region { x: barWindow.innerX; y: 0; width: barWindow.isFill ? barWindow.cornerRadius : 0; height: width }
        Region { x: barWindow.innerX; y: barWindow.height - barWindow.cornerRadius; width: barWindow.isFill ? barWindow.cornerRadius : 0; height: width }
    }

    SideBar {
        id: sideBar
        barWindow: barWindow
        transform: Translate {
            x: barWindow.isRevealed ? 0 : (barWindow.barPosition === "right" ? 1 : -1) * (barWindow.barHeight + barWindow.edgePadding + 10)
            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        }
    }
}
