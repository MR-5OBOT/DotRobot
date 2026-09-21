//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import Quickshell
import "island" as IslandShell

// The whole desktop shell in one qs process. Run with:  qs
// The old side bar and its widgets are archived in old-config.back.tar.gz.
ShellRoot {
    settings.watchFiles: true

    // Top-edge island bar: notch, panels, notifications, OSD (island/).
    IslandShell.Island {}

    // Widgets the island opens, drawn as top-edge notches in the same style.
    Launcher {}          // qs ipc call launcher toggle
    Clipboard {}         // qs ipc call clipboard toggle
    WallpaperPanel {}    // qs ipc call wallpicker toggle
    NetworkPanel {}      // qs ipc call wifi toggle | wifiIsland
    Calculator {}        // qs ipc call calc toggle
    PowerProfileMenu {}  // qs ipc call powerprofile cycle
}
