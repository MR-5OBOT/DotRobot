//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import Quickshell

// One bar per screen. Run with:  qs -c quickshell
ShellRoot {
    settings.watchFiles: true

    // Wallpaper is painted by the awww daemon now (started in hypr autostart),
    // so it survives qs restarts. Uncomment to go back to drawing it here.
    // Variants {
    //     model: Quickshell.screens
    //     Wallpaper {}
    // }

    Variants {   // analog clock, bottom-right, click-through
        model: Quickshell.screens
        DesktopClock {}
    }

    // Bar: one per screen, pick one. Bar = the auto-hiding pill on the left
    // edge; FullBar = serpantinum's full-height side bar (see serp/README.md).
    Variants {
        model: Quickshell.screens
        // Bar {
        //     required property var modelData
        //     screen: modelData
        // }
        FullBar {}
    }

    Notifications {}
    Launcher {}
    // WallpaperPicker {}   // replaced by SerpWallpaper; uncomment to go back
    SerpWallpaper {}  // serpantinum's picker; qs ipc call serpwallpaper toggle
    // WorkspaceOSD {}   // top-edge workspace strip — uncomment to bring it back
    Clipboard {}
    Osd {}
    SerpCalendar {}   // serpantinum's dashboard; qs ipc call serpcalendar toggle
    SerpNetwork {}    // serpantinum's wifi/bt panel; qs ipc call serpnetwork toggle
    NetworkMenu {}
    Calculator {}
    Lock {}
    // FIXME: GoSleep window never maps (backingWindowVisible=true but Hyprland
    // gets no layer surface), and qs restarts on reload while it's loaded.
    // Debug before re-enabling.
    // GoSleep {}

    ActionMenu {
        ipcTarget: "powermenu"
        title: "Power"
        titleIcon: "power_settings_new"
        actions: [
            { icon: "logout",             label: "Quit Hyprland", cmd: ["hyprctl", "dispatch", "exit"] },
            { icon: "restart_alt",        label: "Reboot",        cmd: ["systemctl", "reboot"] },
            { icon: "power_settings_new", label: "Shutdown",      cmd: ["systemctl", "poweroff"] },
        ]
    }

    PowerProfileMenu {}

}
