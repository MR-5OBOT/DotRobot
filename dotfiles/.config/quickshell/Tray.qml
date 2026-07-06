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
            id: icon
            required property var modelData
            Layout.alignment: Qt.AlignHCenter
            implicitSize: 17
            source: modelData.icon

            // native menu anchored to this icon, opening flush to the RIGHT of
            // the bar like the hover popups do
            QsMenuAnchor {
                id: menu
                menu: icon.modelData.menu
                anchor.item: icon
                anchor.edges: Edges.Right
                anchor.gravity: Edges.Right

                // hold the auto-hiding bar out while the menu is open, otherwise
                // opening it leaves the bar's hover region and it slides away
                onVisibleChanged: {
                    if (visible)
                        BarState.activePopup = menu;
                    else if (BarState.activePopup === menu)
                        BarState.activePopup = null;
                }
            }
            Component.onDestruction: if (BarState.activePopup === menu)
                BarState.activePopup = null

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        icon.modelData.activate();
                    else if (mouse.button === Qt.MiddleButton)
                        icon.modelData.secondaryActivate();
                    else if (icon.modelData.hasMenu)
                        menu.open();
                }
            }
        }
    }
}
