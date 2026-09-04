import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// nm-applet-style wifi menu: list of networks (signal + lock + active check),
// click to connect (inline password prompt if a secured network needs one),
// wifi radio toggle. Opened by clicking the bar's wifi icon.
// All state via nmcli — the native Networking module is unpopulated on this box.
PanelWindow {
    id: win

    readonly property bool open: BarState.networkOpen

    property var nets: []          // [{ssid, signal, secured, active}]
    property bool wifiOn: true
    property string busySsid: ""   // row currently connecting
    property string pwSsid: ""     // row awaiting a password
    property string errorText: ""

    // remember what the last connect attempt was, so onExited can react
    property string tryingSsid: ""
    property bool trySecured: false
    property bool triedPw: false

    onOpenChanged: {
        errorText = "";
        pwSsid = "";
        busySsid = "";
        if (open) {
            radioProc.running = true;
            load(false);   // instant: show cached list right away
            load(true);    // queued: background rescan refreshes it when it lands
        }
        BarState.activePopup = open ? win : (BarState.activePopup === win ? null : BarState.activePopup);
    }

    // one Process reused for both cached (fast) and rescan (slow) listings.
    // A rescan requested while one is running is queued, not dropped.
    property bool rescanQueued: false
    function load(rescan) {
        if (lister.running) { if (rescan) rescanQueued = true; return; }
        lister.command = ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", rescan ? "yes" : "no"];
        lister.running = true;
    }
    function apply(text) {   // -t escapes ':' and '\' inside fields
        const seen = {}, out = [];
        for (const line of text.split("\n")) {
            if (!line) continue;
            const f = line.split(":");
            const ssid = f.slice(3).join(":").replace(/\\/g, "");
            if (!ssid) continue;                 // hidden/blank
            const sig = parseInt(f[1]) || 0;
            const active = f[0] === "*";
            if (seen[ssid] !== undefined) {      // dedup: keep strongest / active
                const p = out[seen[ssid]];
                if (active) p.active = true;
                if (sig > p.signal) p.signal = sig;
                continue;
            }
            seen[ssid] = out.length;
            out.push({ ssid: ssid, signal: sig, secured: (f[2] ?? "").length > 0, active: active });
        }
        out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
        nets = out;
    }

    function iconFor(signal) {
        const b = ["signal_wifi_0_bar", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"];
        return b[Math.min(4, Math.floor(signal / 20))];
    }

    function connect(ssid, secured) {
        errorText = "";
        pwSsid = "";
        busySsid = ssid;
        tryingSsid = ssid;
        trySecured = secured;
        triedPw = false;
        conProc.command = ["nmcli", "-w", "12", "device", "wifi", "connect", ssid];
        conProc.running = true;
    }
    function connectPw(ssid, pw) {
        errorText = "";
        pwSsid = "";
        busySsid = ssid;
        tryingSsid = ssid;
        trySecured = true;
        triedPw = true;
        conProc.command = ["nmcli", "-w", "20", "device", "wifi", "connect", ssid, "password", pw];
        conProc.running = true;
    }
    function disconnect(ssid) {
        busySsid = ssid;
        conProc.command = ["nmcli", "connection", "down", "id", ssid];
        conProc.running = true;
    }

    // ---- nmcli plumbing -----------------------------------------------------
    Process {   // wifi radio state
        id: radioProc
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: win.wifiOn = text.trim() === "enabled"
        }
    }
    Process {   // network list — reused for cached + rescan (see load())
        id: lister
        stdout: StdioCollector {
            onStreamFinished: {
                win.apply(text);
                if (win.rescanQueued) { win.rescanQueued = false; win.load(true); }
            }
        }
    }
    Timer {   // cheap poll while open: refresh signal/active from cache
        interval: 2500
        running: win.open && win.wifiOn
        repeat: true
        onTriggered: win.load(false)
    }
    Process {   // connect / disconnect result
        id: conProc
        stdout: StdioCollector { id: conOut }
        stderr: StdioCollector { id: conErr }
        onExited: code => {
            win.busySsid = "";
            if (code === 0) {
                win.load(false);          // state is known -> cheap refresh, no rescan
                radioProc.running = true;
            } else if (win.trySecured && !win.triedPw) {
                win.pwSsid = win.tryingSsid;   // secured + no saved creds -> ask password
            } else {
                win.errorText = "Couldn't connect to " + win.tryingSsid;
            }
        }
    }
    Process {
        id: toggleProc
        onExited: { radioProc.running = true; win.load(true); }   // repopulate if just turned on
    }

    // ---- window -------------------------------------------------------------
    visible: open || card.opacity > 0.01
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-network"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: BarState.networkOpen = false
    }
    MouseArea {   // click-outside closes
        anchors.fill: parent
        onClicked: BarState.networkOpen = false
    }

    Rectangle {
        id: card
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: win.open ? Theme.barWidth + Theme.gap : -width
        width: 280
        height: col.implicitHeight + 2
        color: Theme.bg
        border.width: 1
        border.color: Theme.border

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on anchors.leftMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }   // swallow clicks on the card

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            spacing: 0

            RowLayout {   // header: title + wifi toggle
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.leftMargin: 14
                Layout.rightMargin: 12
                Icon { size: 18; color: Theme.pink; text: "wifi" }
                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    font.family: Theme.font
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.text
                }
                // toggle pill
                Rectangle {
                    width: 40; height: 20
                    radius: Theme.radius
                    color: win.wifiOn ? Theme.pink : Theme.surface
                    border.width: 1
                    border.color: win.wifiOn ? Theme.pink : Theme.border
                    Rectangle {
                        width: 14; height: 14; radius: Theme.radius
                        color: win.wifiOn ? "#ffffff" : Theme.dim
                        anchors.verticalCenter: parent.verticalCenter
                        x: win.wifiOn ? parent.width - width - 3 : 3
                        Behavior on x { NumberAnimation { duration: 120 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            toggleProc.command = ["nmcli", "radio", "wifi", win.wifiOn ? "off" : "on"];
                            toggleProc.running = true;
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(Math.max(win.nets.length, 1), 7) * 42
                visible: win.wifiOn
                clip: true
                model: win.nets

                delegate: Column {
                    id: rowRoot
                    required property var modelData
                    width: list.width
                    readonly property bool pwOpen: win.pwSsid === modelData.ssid

                    Rectangle {
                        width: parent.width
                        height: 42
                        color: rowHover.hovered ? Theme.surface : "transparent"

                        RowLayout {
                            anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            spacing: 10
                            Icon {
                                size: 18
                                color: rowRoot.modelData.active ? Theme.pink : Theme.text
                                text: win.iconFor(rowRoot.modelData.signal)
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: rowRoot.modelData.ssid
                                    elide: Text.ElideRight
                                    font.family: Theme.font
                                    font.pixelSize: 13
                                    font.bold: rowRoot.modelData.active
                                    color: Theme.text
                                }
                                Text {
                                    visible: win.busySsid === rowRoot.modelData.ssid || rowRoot.modelData.active
                                    text: win.busySsid === rowRoot.modelData.ssid ? "Connecting…" : "Connected"
                                    font.family: Theme.font
                                    font.pixelSize: 10
                                    color: Theme.dim
                                }
                            }
                            Icon {
                                visible: rowRoot.modelData.secured
                                size: 13
                                color: Theme.dim
                                text: "lock"
                            }
                            Icon {
                                visible: rowRoot.modelData.active
                                size: 15
                                color: Theme.pink
                                text: "check"
                            }
                        }

                        HoverHandler { id: rowHover }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (rowRoot.modelData.active)
                                    win.disconnect(rowRoot.modelData.ssid);
                                else
                                    win.connect(rowRoot.modelData.ssid, rowRoot.modelData.secured);
                            }
                        }
                    }

                    // inline password prompt (shown when a secured net needs creds)
                    Rectangle {
                        width: parent.width
                        height: rowRoot.pwOpen ? 40 : 0
                        visible: height > 0
                        clip: true
                        color: Theme.surface
                        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                        TextInput {
                            id: pwInput
                            anchors { fill: parent; leftMargin: 14; rightMargin: 12 }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            font.family: Theme.font
                            font.pixelSize: 13
                            color: Theme.text
                            clip: true
                            onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: pwInput.text.length === 0
                                text: "Password — Enter to connect"
                                font.family: Theme.font
                                font.pixelSize: 12
                                color: Theme.dim
                            }
                            Keys.onEscapePressed: win.pwSsid = "";
                            onAccepted: win.connectPw(rowRoot.modelData.ssid, text)
                        }
                    }
                }
            }

            Text {   // wifi-off hint or last error
                Layout.fillWidth: true
                Layout.margins: 12
                visible: !win.wifiOn || win.errorText.length > 0
                text: !win.wifiOn ? "Wi-Fi is off" : win.errorText
                wrapMode: Text.WordWrap
                font.family: Theme.font
                font.pixelSize: 11
                color: win.errorText.length > 0 ? Theme.pink : Theme.dim
            }
        }
    }
}
