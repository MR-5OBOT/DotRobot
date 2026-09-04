import QtQuick

// Material Symbols glyph by name, e.g. Icon { text: "wifi" }.
// Centralises the font family + FILL/weight axes so every icon is one family.
Text {
    id: root
    property real size: 16
    property bool filled: true
    property int weight: 500

    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({
        "FILL": filled ? 1 : 0,
        "wght": weight,
        "GRAD": 0,
        "opsz": size
    })
    color: Theme.text
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
