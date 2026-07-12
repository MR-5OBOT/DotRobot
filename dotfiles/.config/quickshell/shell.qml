//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import Quickshell

// One bar per screen. Run with:  qs -c quickshell
ShellRoot {
    settings.watchFiles: true

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

    ActionMenu {
        ipcTarget: "recorder"
        title: "Record"
        titleIcon: "screen_record"
        cardWidth: 240
        readonly property string rec: "$HOME/.config/hypr/scripts/recording/wf-screenRE"
        actions: [
            { icon: "desktop_windows", label: "Full",         cmd: ["sh", "-c", rec + " full"] },
            { icon: "crop_free",       label: "Region",       cmd: ["sh", "-c", rec + " region"] },
            { icon: "graphic_eq",      label: "Full + audio", cmd: ["sh", "-c", rec + " audio"] },
            { icon: "screen_record",   label: "Region + audio", cmd: ["sh", "-c", rec + " region-audio"] },
        ]
    }
}
