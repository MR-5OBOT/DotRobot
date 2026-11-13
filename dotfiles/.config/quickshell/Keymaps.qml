import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "island/components" as IslandUi

// Keymap cheat sheet: `qs ipc call keymaps toggle` (SUPER + /). A pure-black
// top-edge notch; closes on Esc, the × button, or a click anywhere outside it.
// Tabs (Hyprland, keyd, tmux, zsh): Tab / Shift+Tab cycle them, or click one. Add a
// tool by appending a tab to `tabs`. In a bind's keys, " + " and " / " between key
// names draw as separators and everything else as a keycap.
PanelWindow {
    id: win

    // One entry per tab; each tab is two columns of groups (keeps the card one width).
    readonly property var tabs: [
        {
            name: "Hyprland",
            columns: [
                [{
                    title: "HYPRLAND",
                    note: "Apps & tools · Super = Win key",
                    binds: [
                        ["Super + Return", "Terminal"],
                        ["Super + Space / Q", "App launcher / close window"],
                        ["Super + D / B", "Dashboard / Battery"],
                        ["Super + I / Shift + I", "Network manager / Wi-Fi picker"],
                        ["Super + X / W", "Power / wallpapers"],
                        ["Super + V / N / T", "Clipboard / notifications / bar peek"],
                        ["Super + = / /", "Calculator / this sheet"],
                        ["Super + Shift + N", "Restart Quickshell"],
                        ["Super + Shift + C / P", "Pick colour / power profile"],
                        ["Super + Alt + F", "Click anywhere (grid, g = click)"],
                        ["Super + S", "Quick fullscreen copy"],
                        ["Print / Shift + Print", "Screenshot region / monitor (rishot)"],
                        ["Mouse side buttons", "Mic mute / screenshot"],
                        ["Media keys", "Volume, mic and brightness"]
                    ]
                }],
                [{
                    title: "HYPRLAND",
                    note: "Windows & workspaces",
                    binds: [
                        ["Super + H J K L", "Focus left / down / up / right"],
                        ["Super + Shift + H J K L", "Move window (crosses to the other screen)"],
                        ["Super + Ctrl + H J K L", "Resize window"],
                        ["Super + mouse drag", "Left: move · right: resize"],
                        ["Super + C", "Center window"],
                        ["Super + F", "Fullscreen"],
                        ["Alt + Space", "Toggle floating"],
                        ["Super + Alt + L", "Lock screen"],
                        ["Super + 1 … 0", "Switch workspace 1 … 10"],
                        ["Super + Shift + 1 … 0", "Move window to workspace"],
                        ["Super + O / Shift + O", "Focus / move window to next monitor"]
                    ]
                }]
            ]
        },
        {
            name: "keyd",
            columns: [
                [{
                    title: "KEYD",
                    note: "Hold Caps Lock · works everywhere, even the TTY",
                    binds: [
                        ["Caps + H J K L", "Left / down / up / right"],
                        ["Caps + W / B", "Jump word right / left"],
                        ["Caps + U / D", "Page up / down"],
                        ["Caps + 0", "Line start"],
                        ["Caps + Shift + 4 ($)", "Line end"],
                        ["Caps + - / =", "Volume down / up"],
                        ["Caps + Space", "Toggle microphone mute"],
                        ["Caps Lock", "Tap for normal Caps Lock"],
                        ["Super + Alt + K", "Turn keyd on / off"]
                    ]
                }],
                [{
                    title: "ZIYOULANG T60",
                    note: "Fn layer · on-board, works on any OS",
                    binds: [
                        ["Fn + \\", "Cycle lighting effect (the \\ beside Enter)"],
                        ["Fn + ] / [", "Backlight brightness up / down"],
                        ["Fn + ' / ;", "Effect speed up / down"],
                        ["Fn + Right Shift", "Hold 2 s: / Alt Menu Ctrl turn into arrows"],
                        ["Fn + Win", "Lock the Win key"],
                        ["Fn + 1 … =", "F1 – F12"],
                        ["Fn + Space", "Reset to factory settings"],
                        ["Fn + other", "Media, volume, Home, Mail (side legends)"]
                    ]
                }]
            ]
        },
        {
            name: "tmux",
            columns: [
                [{
                    title: "TMUX",
                    note: "Panes · Prefix = Ctrl + Space, let go, then the key",
                    binds: [
                        ["Ctrl + H J K L", "Switch pane / nvim split (no prefix)"],
                        ["Prefix + | / -", "Split side by side / stacked"],
                        ["Prefix + Shift + H J K L", "Resize pane (tap again to repeat)"],
                        ["Prefix + Ctrl + Z", "Zoom pane in / out"],
                        ["Prefix + X", "Close pane (asks first)"],
                        ["Prefix + Ctrl + L", "Clear the screen"],
                        ["Prefix + O", "Floating terminal show / hide"],
                        ["Prefix + [", "Copy mode (vi keys, scroll back)"],
                        ["V / Y / X", "In copy mode: select / copy / cut"]
                    ]
                }],
                [{
                    title: "TMUX",
                    note: "Windows & sessions",
                    binds: [
                        ["Prefix + C", "New window"],
                        ["Prefix + 1 … 9 / 0", "Go to window 1 … 9 / 10"],
                        ["Prefix + Space", "Last window"],
                        ["Prefix + Ctrl + N / P", "Next / previous window"],
                        ["Prefix + W / S", "Pick a window / session"],
                        ["Prefix + Shift + R", "Rename window"],
                        ["Prefix + G", "Lazygit in a new window"],
                        ["Prefix + B", "Show / hide the status bar"],
                        ["Prefix + R", "Reload tmux config"],
                        ["Prefix + D", "Detach (tmux keeps running)"]
                    ]
                }]
            ]
        },
        {
            name: "zsh",
            columns: [
                [{
                    title: "ZSH",
                    note: "Normal mode (after Esc, block cursor) · vim keys, case matters",
                    binds: [
                        ["Esc", "Normal mode: keys move instead of typing"],
                        ["i / a", "Back to typing, before / after the cursor"],
                        ["w / b / e", "Word right / left / to its end"],
                        ["0 / $", "Line start / end"],
                        ["x / dd / cc", "Delete char / clear line / retype line"],
                        ["u", "Undo"],
                        ["k / j", "Older / newer command"],
                        ["/", "Search old commands, vim style"],
                        ["v", "Edit the command in nvim (:wq comes back)"]
                    ]
                }],
                [{
                    title: "ZSH",
                    note: "While typing (bar cursor)",
                    binds: [
                        ["Ctrl + R", "Fuzzy search old commands (fzf)"],
                        ["Tab", "Complete with a fuzzy menu (fzf-tab)"],
                        ["Alt + F", "Accept the next word of the grey suggestion"],
                        ["Caps + W / B", "Jump word right / left"],
                        ["Caps + 0", "Line start"],
                        ["Caps + Shift + 4 ($)", "Line end"]
                    ]
                }]
            ]
        }
    ]

    property bool open: false
    property int tab: 0  // stays on the last tab between opens
    function show(i: int): void { tab = (i + tabs.length) % tabs.length; flick.contentY = 0; }
    readonly property real drop: open ? card.height : 0  // island drops toasts below the card

    IpcHandler {
        target: "keymaps"
        function toggle(): void { win.open = !win.open; }
    }

    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    mask: BarState.widgetMask
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-keymaps"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        active: win.open
        windows: [win].concat(BarState.islandWindows)
        onCleared: win.open = false
    }

    MouseArea {  // click-outside, any button
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: win.open = false
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: win.open ? 0 : -height   // hangs flush from the top edge and slides out of it
        width: col.implicitWidth + 24
        height: Math.min(col.height + strip.y + strip.height + 28,(win.screen ? win.screen.height : 800) - 20)
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: Theme.notchRadius
        bottomRightRadius: Theme.notchRadius
        color: Theme.notchBg

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }  // swallow clicks on the card

        IslandUi.NotchEars {
            anchors.top: parent.top
            width: parent.width
            color: card.color
        }

        Item {  // key sink
            focus: true
            Keys.onEscapePressed: win.open = false
            Keys.onTabPressed: win.show(win.tab + 1)
            Keys.onBacktabPressed: win.show(win.tab - 1)
        }

        Row {  // tab strip, level with the close button
            id: strip
            anchors { top: parent.top; left: parent.left; topMargin: 13; leftMargin: 12 }
            spacing: 6

            Repeater {
                model: win.tabs

                Rectangle {
                    id: pill
                    required property var modelData
                    required property int index
                    readonly property bool current: index === win.tab
                    width: pillLabel.implicitWidth + 26
                    height: 28
                    radius: 14
                    color: current ? Theme.well : pillMa.containsMouse ? Theme.hover : "transparent"
                    border.width: current ? 1 : 0
                    border.color: Theme.ghost
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: pillLabel
                        anchors.centerIn: parent
                        text: pill.modelData.name
                        font.family: Theme.font
                        font.pixelSize: 12
                        font.weight: pill.current ? Font.Bold : Font.Medium
                        color: pill.current ? Theme.notchAccent : pillMa.containsMouse ? Theme.text : Theme.dim
                    }
                    MouseArea {
                        id: pillMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.show(pill.index)
                    }
                }
            }
        }

        Text {  // hint, left of the close button
            anchors { right: closeBtn.left; rightMargin: 10; verticalCenter: strip.verticalCenter }
            text: "Tab / Shift + Tab to switch"
            font.family: Theme.font
            font.pixelSize: 11
            color: Theme.dim
        }

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 12
            anchors.topMargin: strip.y + strip.height + 12
            clip: true
            contentHeight: col.height
            boundsBehavior: Flickable.StopAtBounds

        Row {
            id: col
            spacing: 14

            Repeater {
                model: win.tabs[win.tab].columns

            Column {
                required property var modelData
                spacing: 14

            Repeater {
                model: parent.modelData

                ColumnLayout {
                    id: group
                    required property var modelData
                    width: 480
                    spacing: 0

                    RowLayout {  // header
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        Layout.bottomMargin: 8
                        spacing: 10

                        Icon { text: "keyboard"; size: 18; color: Theme.notchAccent }
                        Text {
                            text: group.modelData.title
                            font.family: Theme.font
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: Theme.text
                        }
                        Text {
                            Layout.fillWidth: true
                            text: group.modelData.note ?? ""
                            font.family: Theme.font
                            font.pixelSize: 11
                            color: Theme.dim
                            elide: Text.ElideRight
                        }
                    }

                    Repeater {
                        model: group.modelData.binds

                        Rectangle {  // one bind: keycaps left, what it does right
                            id: row
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.rightMargin: 6
                            Layout.preferredHeight: 30  // 20 rows + header fit a 720 px tall screen
                            radius: 8
                            color: rowMa.containsMouse ? Theme.well : "transparent"

                            MouseArea { id: rowMa; anchors.fill: parent; hoverEnabled: true }

                            Row {
                                id: caps
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(200, childrenRect.width)
                                spacing: 5

                                Repeater {
                                    model: row.modelData[0].split(/ ([+\/]) /)

                                    Rectangle {
                                        id: cap
                                        required property string modelData
                                        required property int index
                                        readonly property bool sep: index % 2 === 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: sep ? label.implicitWidth : Math.max(24, label.implicitWidth + 14)
                                        height: 22
                                        radius: 5
                                        color: sep ? "transparent" : Theme.well
                                        border.width: sep ? 0 : 1
                                        border.color: Theme.ghost

                                        Rectangle {  // keycap lip
                                            visible: !cap.sep
                                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 1 }
                                            height: 2
                                            radius: 4
                                            color: Theme.surface
                                        }

                                        Text {
                                            id: label
                                            anchors.centerIn: parent
                                            anchors.verticalCenterOffset: cap.sep ? 0 : -1
                                            text: cap.modelData
                                            font.family: Theme.font
                                            font.pixelSize: 12
                                            font.weight: cap.index === 0 ? Font.Bold : Font.Medium
                                            color: cap.sep ? Theme.dim : cap.index === 0 ? Theme.notchAccent : Theme.text
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors { left: caps.right; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                text: row.modelData[1]
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: rowMa.containsMouse ? Theme.text : Theme.subtle
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
            }
            }
        }
        }

        Rectangle {  // close button, level with the tab strip
            id: closeBtn
            anchors { top: parent.top; right: parent.right; topMargin: 13; rightMargin: 12 }
            width: 28
            height: 28
            radius: 14
            color: closeMa.containsMouse ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Icon {
                anchors.centerIn: parent
                text: "close"
                size: 16
                color: closeMa.containsMouse ? Theme.text : Theme.dim
            }
            MouseArea {
                id: closeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: win.open = false
            }
        }
    }
}
