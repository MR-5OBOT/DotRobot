import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../../../reusables"
import "../../../"

Rectangle {
    id: sideBatRoot

    property var barWindow
    property bool isSolid: false
    property bool distinctPills: barWindow ? (barWindow.distinctPills !== undefined ? barWindow.distinctPills : false) : false
    property bool moduleActive: true
    property bool isGrouped: false
    property bool isCompact: isGrouped || (isSolid && distinctPills)
    property real targetY: 0
    property bool showLayout: false
    property alias batPill: batBtn

    property bool isDesktop: UPower.displayDevice.ready ? !UPower.displayDevice.isLaptopBattery : SystemInfo.isDesktop
    readonly property bool isCharging: batDev.ready && (batDev.state === UPowerDeviceState.Charging || batDev.state === UPowerDeviceState.FullyCharged)
    readonly property string batIcon: isDesktop ? "󰐥" : (isCharging ? "󰂄" : (batCap > 20 ? "󰁹" : "󰂃"))

    // Everything reads the real battery rather than UPower's composite
    // displayDevice, which reports no health (healthSupported is false on it)
    // and carries no nativePath; displayDevice is only the fallback.
    readonly property var batDev: {
        for (const d of UPower.devices.values)
            if (d.isLaptopBattery)
                return d;
        return UPower.displayDevice;
    }

    // The percentage itself comes from sysfs, re-read every second: UPower only
    // refreshes its own percentage when it re-polls (tens of seconds apart), so
    // the pill used to sit on a stale number. UPower still supplies the charge
    // state — it learns that from uevents the moment the charger moves — the
    // rate and time estimates, and the level too if the sysfs read ever fails.
    readonly property string batSysPath: batDev.nativePath ? "/sys/class/power_supply/" + batDev.nativePath : ""
    property int sysPct: -1
    readonly property int batCap: sysPct >= 0 ? sysPct : (batDev.ready ? Math.round(batDev.percentage * 100) : 0)

    FileView {
        id: capFile
        path: sideBatRoot.batSysPath === "" ? "" : sideBatRoot.batSysPath + "/capacity"
        printErrors: false
        onLoaded: {
            const v = parseInt(capFile.text());
            if (!isNaN(v))
                sideBatRoot.sysPct = Math.max(0, Math.min(100, v));
        }
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: sideBatRoot.moduleActive && !sideBatRoot.isDesktop && sideBatRoot.batSysPath !== ""
        onTriggered: capFile.reload()
    }

    property color batDynamicColor: {
        if (isDesktop) return ThemeBackend.red;
        if (isCharging) return ThemeBackend.green;
        if (batCap <= 15) return ThemeBackend.red;
        if (batCap <= 25) return ThemeBackend.peach;
        return ThemeBackend.teal;
    }

    property real targetWidth: barWindow ? (isGrouped ? barWindow.barHeight - 8 : ((isSolid && distinctPills) ? barWindow.barHeight - 6 : barWindow.barHeight)) : (isGrouped ? 22 : ((isSolid && distinctPills) ? 24 : 30))
    property real targetHeight: (moduleActive && batBtn.height > 0) ? (batBtn.height + (barWindow ? barWindow.s(isCompact ? 8 : 10) : (isCompact ? 8 : 10))) : 0

    width: targetWidth
    height: targetHeight

    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    x: barWindow ? ((barWindow.baseOffsetX !== undefined ? barWindow.baseOffsetX : 0) + (barWindow.barHeight - width) / 2) : 0
    y: targetY
    Behavior on y {
        enabled: barWindow && barWindow.startupCascadeFinished
        NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
    }

    radius: ThemeBackend.borderRadius
    border.width: 0
    color: isGrouped ? "transparent" : (isSolid ? (distinctPills ? Qt.darker(ThemeBackend.surface0, 1.15) : "transparent") : ThemeBackend.base)
    clip: true
    layer.enabled: true

    opacity: (showLayout && moduleActive) ? ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : 1.0) : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    // One place for the glyph's size, which the fill-clipped copy of it has to
    // match. s() is the bar's scale factor, absent before the bar hands itself
    // over.
    function sc(v) { return barWindow ? barWindow.s(v) : v; }
    readonly property real pillFontSize: isDesktop ? sc(isCompact ? 15 : 16) : sc(isCompact ? 12 : 13.5)

    Timer {
        running: sideBatRoot.moduleActive && barWindow && barWindow.isStartupReady && barWindow.isDataReady
        interval: 100
        onTriggered: sideBatRoot.showLayout = true
    }

    transform: Translate {
        y: sideBatRoot.showLayout ? 0 : (barWindow ? barWindow.s(60) : 60)
        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
    }

    Rectangle {
        id: batBtn
        anchors.centerIn: parent
        width: barWindow ? barWindow.s(sideBatRoot.isCompact ? 26 : 28) : (sideBatRoot.isCompact ? 26 : 28)
        height: barWindow ? barWindow.s(sideBatRoot.isCompact ? 26 : 28) : (sideBatRoot.isCompact ? 26 : 28)
        radius: Math.max(0, ThemeBackend.borderRadius - (barWindow ? barWindow.s(2) : 2))
        color: sideBatRoot.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
        border.color: sideBatRoot.isCompact ? ThemeBackend.surface2 : ThemeBackend.surface1
        border.width: 1
        clip: true

        // Level is read straight off batCap and drawn flat — no easing into the
        // new value, no wave: the pill is a gauge, not an aquarium.
        property real value: sideBatRoot.isDesktop ? 0.0 : sideBatRoot.batCap / 100
        property color accentColor: sideBatRoot.batDynamicColor
        property bool initAnimTrigger: false

        property real fillRatio: Math.max(0.0, Math.min(1.0, isNaN(value) ? 0.0 : value))
        property real fillY: height * (1.0 - fillRatio)

        Timer {
            running: sideBatRoot.moduleActive && sideBatRoot.showLayout && !batBtn.initAnimTrigger
            interval: 150
            onTriggered: batBtn.initAnimTrigger = true
        }

        opacity: initAnimTrigger ? 1.0 : 0.0
        transform: Translate {
            y: batBtn.initAnimTrigger ? 0 : (barWindow ? barWindow.s(15) : 15)
            Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } }
        }
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        Canvas {
            id: pillCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (batBtn.fillRatio <= 0) return;

                ctx.save();
                var r = Math.max(0, Math.min(batBtn.radius, Math.min(width / 2, height / 2)));
                ctx.beginPath();
                ctx.moveTo(r, 0);
                ctx.lineTo(width - r, 0);
                ctx.quadraticCurveTo(width, 0, width, r);
                ctx.lineTo(width, height - r);
                ctx.quadraticCurveTo(width, height, width - r, height);
                ctx.lineTo(r, height);
                ctx.quadraticCurveTo(0, height, 0, height - r);
                ctx.lineTo(0, r);
                ctx.quadraticCurveTo(0, 0, r, 0);
                ctx.closePath();
                ctx.clip();

                ctx.beginPath();
                ctx.moveTo(0, batBtn.fillY);
                ctx.lineTo(width, batBtn.fillY);
                ctx.lineTo(width, height);
                ctx.lineTo(0, height);
                ctx.closePath();

                var grad = ctx.createLinearGradient(0, 0, 0, height);
                grad.addColorStop(0, Qt.lighter(batBtn.accentColor, 1.25).toString());
                grad.addColorStop(1, batBtn.accentColor.toString());
                ctx.fillStyle = grad;
                ctx.globalAlpha = 0.95;
                ctx.fill();
                ctx.restore();
            }

            Connections {
                target: batBtn
                enabled: sideBatRoot.showLayout && sideBatRoot.moduleActive
                function onRadiusChanged() { pillCanvas.requestPaint(); }
                function onFillRatioChanged() { pillCanvas.requestPaint(); }
                function onAccentColorChanged() { pillCanvas.requestPaint(); }
            }
        }

        Text {
            anchors.centerIn: parent
            text: sideBatRoot.batIcon
            font.family: ThemeBackend.fontFamily
            font.pixelSize: sideBatRoot.pillFontSize
            color: sideBatRoot.isDesktop ? ThemeBackend.red : (sideBatRoot.isCompact ? ThemeBackend.text : ThemeBackend.subtext0)
        }

        // The same label again, clipped to the filled part of the pill and
        // painted in crust, so whatever the fill line covers reads dark.
        Item {
            id: fillClipBox
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(parent.height, Math.max(0, parent.height * batBtn.fillRatio))
            clip: true
            visible: batBtn.fillRatio > 0

            Item {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: batBtn.height

                Text {
                    anchors.centerIn: parent
                    text: sideBatRoot.batIcon
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: sideBatRoot.pillFontSize
                    color: Qt.rgba(ThemeBackend.crust.r, ThemeBackend.crust.g, ThemeBackend.crust.b, 0.75)
                }
            }
        }

        MouseArea {
            id: batMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["qs", "ipc", "call", "powerprofile", "cycle"])
        }
    }

    // ---- hover tooltip ----------------------------------------------------
    // Everything in it but the level is UPower's — its rate and time estimates
    // are smoothed over its own polls, which is what you want in a readout you
    // only glance at.

    function fmtTime(sec) {
        if (!sec || sec <= 0 || !isFinite(sec))
            return "";
        const h = Math.floor(sec / 3600);
        const m = Math.floor((sec % 3600) / 60);
        return h > 0 ? h + "h " + (m < 10 ? "0" : "") + m + "m" : m + "m";
    }

    readonly property string stateText: {
        if (isDesktop)
            return "On AC";
        if (!batDev.ready)
            return "No battery data";
        switch (batDev.state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.FullyCharged:
            return "Fully charged";
        case UPowerDeviceState.Discharging:
            return "On battery";
        case UPowerDeviceState.Empty:
            return "Empty";
        default:
            return "Plugged in";
        }
    }
    readonly property string timeText: {
        if (!batDev.ready)
            return "";
        if (batDev.state === UPowerDeviceState.Charging) {
            const t = fmtTime(batDev.timeToFull);
            return t === "" ? "" : t + " to full";
        }
        if (batDev.state === UPowerDeviceState.Discharging) {
            const t = fmtTime(batDev.timeToEmpty);
            return t === "" ? "" : t + " left";
        }
        return "";
    }
    // changeRate is W either way; which direction it runs is already in stateText
    readonly property string rateText: batDev.ready && batDev.changeRate > 0 ? batDev.changeRate.toFixed(1) + " W" : ""
    readonly property string healthText: batDev.ready && batDev.healthSupported && batDev.healthPercentage > 0 ? Math.round(batDev.healthPercentage) + "% health" : ""

    function joinDot(parts) { return parts.filter(p => p !== "").join("  ·  "); }

    PillPopout {
        anchorItem: batBtn
        host: sideBatRoot.barWindow
        itemHovered: batMouse.containsMouse && sideBatRoot.showLayout && sideBatRoot.moduleActive

        contentComponent: Component {
            Column {
                spacing: sideBatRoot.sc(3)

                Row {
                    spacing: sideBatRoot.sc(7)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: sideBatRoot.batIcon
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: sideBatRoot.sc(15)
                        color: sideBatRoot.batDynamicColor
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: sideBatRoot.isDesktop ? "Desktop" : sideBatRoot.batCap + "%"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: sideBatRoot.sc(14)
                        font.bold: true
                        color: ThemeBackend.text
                    }
                }

                Text {
                    text: sideBatRoot.joinDot([sideBatRoot.stateText, sideBatRoot.timeText])
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: sideBatRoot.sc(11.5)
                    color: ThemeBackend.subtext1
                }

                Text {
                    readonly property string line: sideBatRoot.joinDot([sideBatRoot.rateText, sideBatRoot.healthText])
                    visible: line !== ""
                    text: line
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: sideBatRoot.sc(10.5)
                    color: ThemeBackend.overlay2
                }
            }
        }
    }
}
