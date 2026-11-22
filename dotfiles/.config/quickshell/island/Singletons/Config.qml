pragma Singleton
import QtQuick
import Quickshell

/** The wallpaper folder the picker, drag-and-drop and the backend share. Script paths come from Quickshell.shellPath(). */
Singleton {
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
}
