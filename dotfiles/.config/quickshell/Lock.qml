pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// gtklock replacement: full-screen wallpaper + centered dark card with clock,
// user, and a masked password field. PAM auth (config "login").
// Lock with:  qs ipc call lock lock   (bound to ALT+L; also hypridle lock_cmd)
Scope {
    id: root

    readonly property string user: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // ---- PAM ----------------------------------------------------------------
    property string pending: ""
    property bool failed: false

    PamContext {
        id: pam
        config: "login"
        user: root.user
        onResponseRequiredChanged: if (responseRequired) respond(root.pending)
        onCompleted: result => {
            root.pending = "";
            if (result === PamResult.Success)
                sessionLock.locked = false;
            else
                root.failed = true;   // wrong password
        }
        onError: { root.pending = ""; root.failed = true; }
    }

    function submit(pw) {
        if (pam.active || pw.length === 0) return;
        root.failed = false;
        root.pending = pw;
        pam.start();
    }

    IpcHandler {
        target: "lock"
        function lock(): void { sessionLock.locked = true; }
    }

    // ---- Surface ------------------------------------------------------------
    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            color: Theme.bg

            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl("lock-bg.jpg")
                fillMode: Image.PreserveAspectCrop
                cache: true
            }
            Rectangle {           // scrim, like gtklock's dark backdrop
                anchors.fill: parent
                color: "#000000"
                opacity: 0.35
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 320
                height: col.implicitHeight + 48
                color: Theme.bg
                radius: Theme.radius
                border.width: 1
                border.color: Theme.border

                Column {
                    id: col
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        font.family: Theme.font
                        font.pixelSize: 52
                        font.bold: true
                        color: Theme.text
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "dddd, MMM d")
                        font.family: Theme.font
                        font.pixelSize: 13
                        color: Theme.dim
                        bottomPadding: 14
                    }

                    // password field
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: Theme.surface
                        radius: Theme.radius
                        border.width: 1
                        border.color: root.failed ? Theme.pink : (input.activeFocus ? Theme.pinkDim : Theme.border)

                        TextInput {
                            id: input
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            focus: true
                            enabled: !pam.active
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            font.family: Theme.font
                            font.pixelSize: 14
                            color: Theme.text
                            clip: true

                            Text {   // placeholder
                                anchors.verticalCenter: parent.verticalCenter
                                visible: input.text.length === 0
                                text: pam.active ? "Checking…" : "Password for " + root.user
                                font.family: Theme.font
                                font.pixelSize: 13
                                color: Theme.dim
                            }
                            onTextChanged: root.failed = false
                            onAccepted: { root.submit(text); text = ""; }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.failed
                        text: "Incorrect password"
                        font.family: Theme.font
                        font.pixelSize: 11
                        color: Theme.pink
                        topPadding: 2
                    }
                }
            }
        }
    }
}
