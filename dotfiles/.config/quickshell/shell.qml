//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import QtQuick
import Quickshell
import "island" as IslandShell

// The whole desktop shell in one qs process. Run with:  qs
// The old side bar and its widgets are archived in old-config.back.tar.gz.
ShellRoot {
    settings.watchFiles: true

    // Top-edge island bar: notch, panels, notifications, OSD (island/).
    // Toasts and OSD flashes drop below whichever notch card is open; the big
    // panels (wallpaper, wifi) sit on a lower layer and get them on top instead.
    IslandShell.Island {
        id: island
        widgetDrop: Math.max(launcher.drop, clipboard.drop, calc.drop, powerProfile.drop, keymaps.drop)
    }
    Binding { target: BarState; property: "islandWindows"; value: island.windows }
    Binding { target: BarState; property: "toastHole"; value: island.toastHole }

    // Widgets the island opens, drawn as top-edge notches in the same style.
    Launcher { id: launcher }                  // qs ipc call launcher toggle
    Clipboard { id: clipboard }                // qs ipc call clipboard toggle
    WallpaperPanel {}                          // qs ipc call wallpicker toggle
    NetworkPanel {}                            // qs ipc call wifi toggle | wifiIsland
    Calculator { id: calc }                    // qs ipc call calc toggle
    PowerProfileMenu { id: powerProfile }      // qs ipc call powerprofile cycle
    Keymaps { id: keymaps }                    // qs ipc call keymaps toggle
}
