//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import Quickshell

// One bar per screen. Run with:  qs -c quickshell
ShellRoot {
    settings.watchFiles: true

    Variants {   // wallpaper: one background layer per screen
        model: Quickshell.screens
        Wallpaper {}
    }

    Variants {
        model: Quickshell.screens
        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Notifications {}
    Launcher {}
    WallpaperPicker {}
    WorkspaceOSD {}
    Clipboard {}
    Osd {}
    CalendarPopup {}
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

}
