//@ pragma UseQApplication
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
import Quickshell

// One bar per screen. Run with:  qs -c quickshell   (waybar stays as-is)
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
}
