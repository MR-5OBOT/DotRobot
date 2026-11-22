pragma ComponentBehavior: Bound

import QtQuick
import "../Singletons"
import "../components"

/**
 * 色 THEME sub-surface: the wallpaper folder that feeds the rotation. The accent
 * itself always follows the wallpaper (Theme.qml, wallcolors.py). Folds back to
 * Display on the back chevron or an empty click.
 */
SettingsSurface {
    id: root

    backSurface: "display"
    implicitHeight: content.implicitHeight

    rows: [
        { item: wpDirRow, kind: "text", activate: function () {
            wpDirRow.editing = !wpDirRow.editing;
            if (wpDirRow.editing) {
                wpDirField.text = Flags.wallpaperDir;
                Qt.callLater(wpDirField.forceActiveFocus);
            }
        } }
    ]

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            title: "THEME"
            showBack: true
        }

        Item { width: 1; height: 12 * root.s }

        SettingsRow {
            id: wpDirRow
            surface: root
            name: "Wallpaper folder"
            icon: "wallpaper"
            sub: wpDirRow.editing ? "Return to save · Esc to cancel" : Walls.wpDir
            captionOnFocus: true
            last: true

            property bool editing: false

            Item {
                width: wpDirRow.editing ? 200 * root.s : 26 * root.s
                height: 26 * root.s
                Behavior on width { NumberAnimation { duration: Motion.fast } }

                Rectangle {
                    anchors.fill: parent
                    radius: 9 * root.s
                    visible: wpDirRow.editing
                    color: Qt.alpha(Theme.frameBg, 0.7)
                    border.width: 1
                    border.color: wpDirField.activeFocus ? Qt.alpha(Theme.vermLit, 0.7) : Theme.hairSoft
                }

                TextInput {
                    id: wpDirField
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10 * root.s
                    anchors.rightMargin: 10 * root.s
                    visible: wpDirRow.editing
                    clip: true
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 11 * root.s
                    selectByMouse: true
                    selectionColor: Theme.verm

                    Keys.onPressed: (e) => {
                        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            Flags.wallpaperDir = text.trim();
                            wpDirRow.editing = false;
                            focus = false;
                            e.accepted = true;
                        } else if (e.key === Qt.Key_Escape) {
                            wpDirRow.editing = false;
                            focus = false;
                            e.accepted = true;
                        }
                    }
                }

                GlyphIcon {
                    anchors.centerIn: parent
                    visible: !wpDirRow.editing
                    width: 15 * root.s
                    height: 15 * root.s
                    name: "wallpaper"
                    color: wpDirRow.focused ? Theme.cream : Theme.iconDim
                    stroke: 1.7
                }
            }
        }
    }
}
