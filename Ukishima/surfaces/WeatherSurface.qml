pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import "../Singletons"
import "../components"

/**
 * 天 WEATHER surface: a live read-out of the Open-Meteo forecast already served
 * by the Weather singleton, so no extra dependency or network hops are added
 * here. Laid out wide and short: current conditions (temperature, glyph,
 * humidity) sit left of the next eight hours as columns, and the five-day
 * forecast runs as one row of columns beneath a hairline. Delegate data is read
 * through `required property var modelData` and column widths are derived from
 * the container, so nothing reads undefined and nothing escapes the pill. Before
 * the first fetch lands only the header and a dim waiting hint are shown.
 */
PillSurface {
    id: root

    mTop: 16
    mLeft: 19
    mRight: 19
    mBottom: 20

    implicitWidth: 600 * s
    implicitHeight: content.implicitHeight

    ameForm: "off"

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item {
            id: header
            width: parent.width
            height: 22 * root.s

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Flags.showGlyphs
                    text: "天"
                    color: Theme.cream
                    font.family: Theme.fontJp
                    font.weight: Font.Medium
                    font.pixelSize: 16 * root.s
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "WEATHER"
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.6 * root.s
                }
            }

            Item {
                id: cityBox
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(cityText.implicitWidth, cityField.implicitWidth) + 4
                height: 14 * root.s

                property bool editing: false

                Text {
                    id: cityText
                    visible: !cityBox.editing
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.city.length ? Weather.city : "set town"
                    color: cityArea.containsMouse ? Theme.subtle : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 9.5 * root.s
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.8 * root.s
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: cityArea
                    visible: !cityBox.editing
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        cityField.text = Flags.weatherCity;
                        cityBox.editing = true;
                        cityField.forceActiveFocus();
                        cityField.selectAll();
                    }
                }
                TextField {
                    id: cityField
                    visible: cityBox.editing
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(cityText.implicitWidth, 150 * root.s)
                    background: null
                    padding: 0
                    horizontalAlignment: TextInput.AlignRight
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 9.5 * root.s
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.8 * root.s
                    placeholderText: "town or lat,lon"
                    placeholderTextColor: Theme.faint
                    selectByMouse: true
                    selectionColor: Theme.verm
                    onAccepted: {
                        Flags.weatherCity = text.trim();
                        cityBox.editing = false;
                    }
                    Keys.onEscapePressed: cityBox.editing = false
                    onActiveFocusChanged: if (!activeFocus) cityBox.editing = false
                }
            }
        }

        Column {
            width: parent.width
            topPadding: 18 * root.s
            spacing: 16 * root.s
            visible: Weather.ready

            Row {
                id: topRow
                width: parent.width
                height: 74 * root.s
                spacing: 18 * root.s

                Row {
                    id: hero
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12 * root.s

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Weather.tempNow + "°"
                        color: Weather.codeNow >= 95 ? Theme.vermLit : Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 40 * root.s
                        font.weight: Font.Bold
                        font.letterSpacing: -1 * root.s
                        font.features: { "tnum": 1 }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4 * root.s

                        Row {
                            spacing: 7 * root.s
                            GlyphIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22 * root.s
                                height: 22 * root.s
                                name: Weather.glyphFor(Weather.codeNow, Weather.isDay)
                                color: Theme.flameGlow
                                stroke: 1.7
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Weather.labelFor(Weather.codeNow)
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 13 * root.s
                                font.weight: Font.DemiBold
                            }
                        }

                        Row {
                            spacing: 5 * root.s
                            GlyphIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 11 * root.s
                                height: 11 * root.s
                                name: "droplet"
                                color: Theme.subtle
                                stroke: 1.6
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Weather.humidity + "%"
                                color: Theme.subtle
                                font.family: Theme.font
                                font.pixelSize: 10 * root.s
                                font.weight: Font.Medium
                                font.features: { "tnum": 1 }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: Theme.hair
                }

                Row {
                    id: hours
                    readonly property int count: 8
                    width: parent.width - hero.implicitWidth - 1 - 2 * topRow.spacing
                    height: parent.height

                    Repeater {
                        model: Weather.hourly.slice(0, hours.count)

                        Column {
                            id: hourCol
                            required property var modelData
                            width: hours.width / hours.count
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 7 * root.s

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: hourCol.modelData.hour + "h"
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: 9.5 * root.s
                                font.weight: Font.Medium
                                font.features: { "tnum": 1 }
                            }
                            GlyphIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 16 * root.s
                                height: 16 * root.s
                                name: Weather.glyphFor(hourCol.modelData.code, true)
                                color: Theme.iconDim
                                stroke: 1.7
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: hourCol.modelData.temp + "°"
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 11 * root.s
                                font.weight: Font.DemiBold
                                font.features: { "tnum": 1 }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.hair
            }

            Row {
                id: days
                width: parent.width

                Repeater {
                    model: Weather.daily

                    Column {
                        id: dayCol
                        required property var modelData
                        width: days.width / Math.max(1, Weather.daily.length)
                        spacing: 7 * root.s

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: dayCol.modelData.day
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 10 * root.s
                            font.weight: Font.Medium
                            font.capitalization: Font.AllUppercase
                        }
                        GlyphIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 16 * root.s
                            height: 16 * root.s
                            name: Weather.glyphFor(dayCol.modelData.code, true)
                            color: Theme.iconDim
                            stroke: 1.7
                        }
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 6 * root.s

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: dayCol.modelData.temp + "°"
                                color: Theme.cream
                                font.family: Theme.font
                                font.pixelSize: 11.5 * root.s
                                font.weight: Font.DemiBold
                                font.features: { "tnum": 1 }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: dayCol.modelData.rh + "%"
                                color: Theme.faint
                                font.family: Theme.font
                                font.pixelSize: 9.5 * root.s
                                font.weight: Font.Medium
                                font.features: { "tnum": 1 }
                            }
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width
            topPadding: 15 * root.s
            spacing: 5 * root.s
            visible: !Weather.ready

            Text {
                width: parent.width
                text: Weather.city.length ? Weather.city : "Weather"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 14 * root.s
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                text: "Waiting for forecast…"
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 10.5 * root.s
            }
        }
    }
}
