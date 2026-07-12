import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Simple calculator with two modes:
//   pad   — classic keypad + display (Super+equal / XF86Calculator)
//   paper — a running tape: type an expression, Enter, it stacks up
// One evaluator for both. Toggle: qs ipc call calc toggle
PanelWindow {
    id: win

    readonly property bool open: BarState.calcOpen
    property string input: ""
    property bool paper: false
    property var tape: []          // [{expr, res}]

    onOpenChanged: {
        BarState.activePopup = open ? win : (BarState.activePopup === win ? null : BarState.activePopup);
        if (open) inputFocus();
    }
    function inputFocus() { Qt.callLater(() => { (paper ? paperInput : padInput).forceActiveFocus(); }); }

    // ---- evaluator: whitelist chars, then Function-eval. Local input only. ---
    // ponytail: char-whitelisted Function eval; swap for a real parser only if
    // you need precedence quirks or big-decimal precision.
    function calc(expr) {
        if (!expr) return "";
        let e = expr.replace(/×/g, "*").replace(/÷/g, "/").replace(/−/g, "-").replace(/%/g, "/100").replace(/√\(?/g, "Math.sqrt(");
        // auto-close unbalanced "(" (so "√(9" works)
        const opens = (e.match(/\(/g) || []).length, closes = (e.match(/\)/g) || []).length;
        e += ")".repeat(Math.max(0, opens - closes));
        if (e.replace(/Math\.sqrt/g, "").replace(/[0-9.+\-*/() ]/g, "").length) return "";  // illegal chars
        try {
            const r = Function('"use strict";return (' + e + ')')();
            if (r === undefined || r === null || !isFinite(r)) return "";
            return String(+parseFloat(Number(r).toFixed(10)));
        } catch (_) { return ""; }
    }
    readonly property string preview: calc(input)

    function press(k) {
        if (k === "C") { input = ""; return; }
        if (k === "⌫") { input = input.slice(0, -1); return; }
        if (k === "=") { equals(); return; }
        if (k === "√") { input += "√("; return; }
        input += k;
    }
    function equals() {
        const r = calc(input);
        if (r === "") return;
        tape = tape.concat([{ expr: input, res: r }]);
        input = r;                       // chain from the result (pad); paper clears on Enter
    }

    readonly property var keys: ["C", "⌫", "%", "÷", "7", "8", "9", "×", "4", "5", "6", "−", "1", "2", "3", "+", "√", "0", ".", "="]

    // ---- window --------------------------------------------------------------
    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-calc"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "calc"
        function toggle(): void { BarState.calcOpen = !BarState.calcOpen; }
    }
    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: BarState.calcOpen = false
    }
    MouseArea { anchors.fill: parent; onClicked: BarState.calcOpen = false }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 272
        height: content.implicitHeight
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }   // swallow clicks

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            spacing: 0

            RowLayout {   // header: title + mode toggle
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                Layout.leftMargin: 14
                Layout.rightMargin: 10
                Text {
                    Layout.fillWidth: true
                    text: win.paper ? "Paper" : "Calculator"
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.dim
                }
                Rectangle {   // mode toggle
                    width: 26; height: 22
                    color: modeHover.hovered ? Theme.surface : "transparent"
                    Icon {
                        anchors.centerIn: parent
                        size: 16
                        color: Theme.pink
                        text: win.paper ? "receipt_long" : "grid_view"
                    }
                    HoverHandler { id: modeHover }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { win.paper = !win.paper; win.inputFocus(); }
                    }
                }
                Rectangle {   // close
                    width: 26; height: 22
                    color: closeHover.hovered ? Theme.pink : "transparent"
                    Icon {
                        anchors.centerIn: parent
                        size: 16
                        color: closeHover.hovered ? "#ffffff" : Theme.dim
                        text: "close"
                    }
                    HoverHandler { id: closeHover }
                    MouseArea { anchors.fill: parent; onClicked: BarState.calcOpen = false }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            // ---- PAPER MODE: tape on top, input + Enter at bottom -------------
            ColumnLayout {
                visible: win.paper
                Layout.fillWidth: true
                spacing: 0

                ListView {
                    id: tapeView
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    clip: true
                    model: win.tape
                    onCountChanged: positionViewAtEnd()
                    verticalLayoutDirection: ListView.TopToBottom
                    delegate: Column {
                        required property var modelData
                        width: tapeView.width
                        topPadding: 8
                        leftPadding: 14
                        rightPadding: 14
                        Text {
                            width: parent.width - 28
                            text: modelData.expr
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft
                            font.family: Theme.font
                            font.pixelSize: 12
                            color: Theme.dim
                        }
                        Text {
                            width: parent.width - 28
                            text: "= " + modelData.res
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft
                            font.family: Theme.font
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.text
                        }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    spacing: 0
                    TextInput {
                        id: paperInput
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        verticalAlignment: TextInput.AlignVCenter
                        text: win.input
                        onTextChanged: if (text !== win.input) win.input = text
                        font.family: Theme.font
                        font.pixelSize: 15
                        color: Theme.text
                        clip: true
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: paperInput.text.length === 0
                            text: "type an expression…"
                            font.family: Theme.font
                            font.pixelSize: 13
                            color: Theme.dim
                        }
                        Keys.onEscapePressed: BarState.calcOpen = false
                        onAccepted: { win.equals(); win.input = ""; }
                    }
                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.fillHeight: true
                        color: enterHover.hovered ? Theme.pink : Theme.surface
                        Text {
                            anchors.centerIn: parent
                            text: "Enter"
                            font.family: Theme.font
                            font.pixelSize: 12
                            color: Theme.text
                        }
                        HoverHandler { id: enterHover }
                        MouseArea { anchors.fill: parent; onClicked: { win.equals(); win.input = ""; paperInput.forceActiveFocus(); } }
                    }
                }
            }

            // ---- PAD MODE: display on top, keypad below -----------------------
            ColumnLayout {
                visible: !win.paper
                Layout.fillWidth: true
                spacing: 0

                Item {   // display (input big; live result faint below)
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    TextInput {
                        id: padInput
                        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 14; rightMargin: 14; topMargin: 12 }
                        horizontalAlignment: TextInput.AlignRight
                        text: win.input
                        onTextChanged: if (text !== win.input) win.input = text
                        font.family: Theme.font
                        font.pixelSize: 26
                        font.bold: true
                        color: Theme.text
                        clip: true
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: padInput.text.length === 0
                            text: "0"
                            font.family: Theme.font
                            font.pixelSize: 26
                            font.bold: true
                            color: Theme.dim
                        }
                        Keys.onEscapePressed: BarState.calcOpen = false
                        Keys.onReturnPressed: win.equals()
                        Keys.onEnterPressed: win.equals()
                    }
                    Text {   // live preview of the result
                        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 14; bottomMargin: 8 }
                        visible: win.preview.length > 0 && win.preview !== win.input
                        text: "= " + win.preview
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.dim
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    columnSpacing: 0
                    rowSpacing: 0
                    Repeater {
                        model: win.keys
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool op: ["÷", "×", "−", "+", "="].includes(modelData)
                            readonly property bool eq: modelData === "="
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            color: eq ? (bHover.hovered ? Theme.pink : Theme.pinkDim) : (bHover.hovered ? Theme.surface : Theme.bg)
                            border.width: 1
                            border.color: Theme.border
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData
                                font.family: Theme.font
                                font.pixelSize: 16
                                font.bold: parent.op
                                color: parent.eq ? "#ffffff" : (parent.op ? Theme.pink : Theme.text)
                            }
                            HoverHandler { id: bHover }
                            MouseArea { anchors.fill: parent; onClicked: { win.press(parent.modelData); padInput.forceActiveFocus(); } }
                        }
                    }
                }
            }
        }
    }
}
