//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import QtQuick
import Quickshell
import "island" as IslandShell

// The whole desktop shell in one qs process. Run with:  qs
ShellRoot {
    id: root
    settings.watchFiles: true

    // Top-edge island bar: notch, panels, notifications, OSD (island/).
    // Toasts and OSD flashes drop below whichever notch card is open; the big
    // wallpaper panel sits on a lower layer and gets them on top instead.
    // Wi-Fi is nm-applet's tray icon (Home's tray); the radio panel is gone.
    IslandShell.Island {
        id: island
        onRequestNotifications: monitor => notifications.toggle(monitor)
        widgetDrops: {
            const drops = {};
            for (const widget of [launcher, clipboard, calc, powerProfile, keymaps]) {
                if (widget.drop > 0 && widget.screen)
                    drops[widget.screen.name] = Math.max(drops[widget.screen.name] || 0, widget.drop);
            }
            return drops;
        }
    }
    Binding { target: BarState; property: "islandWindows"; value: island.windows }
    Binding { target: BarState; property: "toastHole"; value: island.toastHole }
    NotificationCenter { id: notifications }

    // Widgets the island opens, drawn as top-edge notches in the same style.
    Launcher { id: launcher }                  // qs ipc call launcher toggle
    Clipboard { id: clipboard }                // qs ipc call clipboard toggle
    WallpaperPanel { id: wallpicker }          // qs ipc call wallpicker toggle
    WorkspacePanel { id: overview }            // qs ipc call workspaces toggle
    Calculator { id: calc }                    // qs ipc call calc toggle
    PowerProfileMenu { id: powerProfile }      // qs ipc call powerprofile cycle
    Keymaps { id: keymaps }                    // qs ipc call keymaps toggle

    // One panel at a time: opening any widget closes the island's open surface
    // (the dashboard etc.) and every other widget; opening an island surface
    // closes the widgets.
    readonly property var widgets: [notifications, launcher, clipboard, wallpicker, overview, calc, powerProfile, keymaps]

    function closeWidgets(except) {
        for (const w of widgets) {
            if (w === except || !w.open)
                continue;
            if (w === launcher)
                BarState.launcherOpen = false;   // these two keep their state in BarState
            else if (w === calc)
                BarState.calcOpen = false;
            else
                w.open = false;
        }
    }

    Instantiator {
        model: root.widgets
        delegate: Connections {
            required property var modelData
            target: modelData
            function onOpenChanged() {
                if (!modelData.open)
                    return;
                island.close();
                root.closeWidgets(modelData);
            }
        }
    }

    Connections {
        target: island
        function onOpenSurfaceChanged() {
            if (island.openSurface.length > 0)
                root.closeWidgets(null);
        }
    }
}
