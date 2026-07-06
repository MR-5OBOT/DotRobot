import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

// Vertical system tray. Left-click activate, middle secondary, right menu.
ColumnLayout {
    id: root
    spacing: 10

    // network + bluetooth are rendered natively, so hide their tray applets
    readonly property var hidden: /nm-applet|network|blueman|bluetooth/i
    function keep(item) {
        return !hidden.test(item.id ?? "") && !hidden.test(item.tooltipTitle ?? "") && !hidden.test(item.title ?? "");
    }

    Repeater {
        model: SystemTray.items.values.filter(root.keep)

        delegate: IconImage {
            required property var modelData
            Layout.alignment: Qt.AlignHCenter
            implicitSize: 17
            source: modelData.icon

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        parent.modelData.activate();
                    else if (mouse.button === Qt.MiddleButton)
                        parent.modelData.secondaryActivate();
                    else if (parent.modelData.hasMenu)
                        parent.modelData.display(QsWindow.window, 0, this.height);
                }
            }
        }
    }
}
