//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import QtQuick
import Quickshell
import "island" as IslandShell

// The whole desktop shell in one qs process. Run with:  qs
ShellRoot {
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
    NotificationCenter {
        id: notifications
        onOpened: island.close()
    }

    // Widgets the island opens, drawn as top-edge notches in the same style.
    Launcher { id: launcher }                  // qs ipc call launcher toggle
    Clipboard { id: clipboard }                // qs ipc call clipboard toggle
    WallpaperPanel {}                          // qs ipc call wallpicker toggle
    WorkspacePanel {}                          // qs ipc call workspaces toggle
    Calculator { id: calc }                    // qs ipc call calc toggle
    PowerProfileMenu { id: powerProfile }      // qs ipc call powerprofile cycle
    Keymaps { id: keymaps }                    // qs ipc call keymaps toggle
}
