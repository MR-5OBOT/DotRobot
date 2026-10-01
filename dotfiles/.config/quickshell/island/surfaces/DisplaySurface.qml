pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../Singletons"
import "../components"

/**
 * 時 DISPLAY settings: UI scale, the 12/24h clock and running seconds, plus
 * general shell behaviour: reduced motion, auto-hide, keep-awake (blocks lock,
 * screen-off and sleep) and memory saver. Opened by the cog; an empty click
 * closes it.
 */
SettingsSurface {
    id: root

    backSurface: ""
    implicitHeight: content.implicitHeight

    rows: [
        { item: scaleRow, kind: "seg", vals: [1.0, 1.15, 1.3, 1.5], get: function () { return Flags.uiScale; }, set: function (v) { Flags.uiScale = v; } },
        { item: timeRow, kind: "seg", vals: [false, true], get: function () { return Flags.time12h; }, set: function (v) { Flags.time12h = v; } },
        { item: secRow, kind: "toggle", get: function () { return Flags.clockSeconds; }, set: function (v) { Flags.clockSeconds = v; } },
        { item: motionRow, kind: "toggle", get: function () { return Flags.reduceMotion; }, set: function (v) { Flags.reduceMotion = v; } },
        { item: autoHideRow, kind: "toggle", get: function () { return Flags.autoHide; }, set: function (v) { Flags.autoHide = v; } },
        { item: awakeRow, kind: "toggle", get: function () { return Flags.keepAwake; }, set: function (v) { Flags.keepAwake = v; } },
        { item: saverRow, kind: "toggle", get: function () { return Flags.memorySaver; }, set: function (v) { Flags.memorySaver = v; } }
    ]

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            title: "DISPLAY"
            showBack: false
        }

        Item { width: 1; height: 12 * root.s }

        SettingsRow {
            id: scaleRow
            surface: root
            name: "UI scale"
            icon: "scaling"

            SettingsSeg {
                s: root.s
                options: [{ label: "100%", value: 1.0 }, { label: "115%", value: 1.15 }, { label: "130%", value: 1.3 }, { label: "150%", value: 1.5 }]
                value: Flags.uiScale
                onPicked: (v) => Flags.uiScale = v
            }
        }

        SettingsRow {
            id: timeRow
            surface: root
            name: "Time format"
            icon: "clock"

            SettingsSeg {
                s: root.s
                options: [{ label: "24H", value: false }, { label: "12H", value: true }]
                value: Flags.time12h
                onPicked: (v) => Flags.time12h = v
            }
        }

        SettingsRow {
            id: secRow
            surface: root
            name: "Clock seconds"
            icon: "stopwatch"

            LinkToggle {
                s: root.s
                on: Flags.clockSeconds
                onToggled: Flags.clockSeconds = !Flags.clockSeconds
            }
        }

        SettingsRow {
            id: motionRow
            surface: root
            name: "Reduce motion"
            icon: "waves"

            LinkToggle {
                s: root.s
                on: Flags.reduceMotion
                onToggled: Flags.reduceMotion = !Flags.reduceMotion
            }
        }

        SettingsRow {
            id: autoHideRow
            surface: root
            name: "Auto hide"
            icon: "eye-off"

            LinkToggle {
                s: root.s
                on: Flags.autoHide
                onToggled: Flags.autoHide = !Flags.autoHide
            }
        }

        SettingsRow {
            id: awakeRow
            surface: root
            name: "Keep awake"
            icon: "awake"

            LinkToggle {
                s: root.s
                on: Flags.keepAwake
                onToggled: Flags.keepAwake = !Flags.keepAwake
            }
        }

        SettingsRow {
            id: saverRow
            surface: root
            name: "Memory saver"
            icon: "stopwatch"
            last: true

            LinkToggle {
                s: root.s
                on: Flags.memorySaver
                onToggled: Flags.memorySaver = !Flags.memorySaver
            }
        }
    }
}
