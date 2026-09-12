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
    // edge; FullBar = serpantinum's full-height side bar (see widgets/README.md).
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
    // WallpaperPicker {}   // replaced by WallpaperPanel; uncomment to go back
    WallpaperPanel {}  // serpantinum's picker; qs ipc call wallpicker toggle
    ScreenTimePanel {}  // screen time; qs ipc call screentime toggle
    // WorkspaceOSD {}   // top-edge workspace strip — uncomment to bring it back
    Clipboard {}
    Osd {}
    CalendarPanel {}   // serpantinum's dashboard; qs ipc call calendar toggle
    NetworkPanel {}    // serpantinum's wifi/bt panel; qs ipc call wifi toggle
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
            { icon: "lock",               label: "Lock",          cmd: ["bash", "-c", "pidof hyprlock || hyprlock"] },   // same as ALT+L
            { icon: "logout",             label: "Quit Hyprland", cmd: ["hyprctl", "dispatch", "exit"] },
            { icon: "bedtime",            label: "Suspend",       cmd: ["systemctl", "suspend"] },
            { icon: "restart_alt",        label: "Reboot",        cmd: ["systemctl", "reboot"] },
            { icon: "power_settings_new", label: "Shutdown",      cmd: ["systemctl", "poweroff"] },
        ]
    }

    PowerProfileMenu {}

}
