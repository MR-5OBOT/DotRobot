pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: root

    signal wallpaperChanged(string screenName, string path, string transition)
    signal playbackChanged(string screenName, string state)
    signal wallpaperCleared(string screenName)

    property var screenWallpapers: ({})
    property var screenWallpaperPaths: ({})
    property string currentPath: ""
    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")

    FileView {
        path: root.stateDir + "/island-wallpaper"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.currentPath = text().trim()
        onFileChanged: reload()
    }

    FileView {
        path: root.stateDir + "/island-wallpaper-map"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            let paths = {};
            let names = {};
            for (const line of text().split("\n")) {
                const tab = line.indexOf("\t");
                if (tab < 1) continue;
                const output = line.slice(0, tab);
                const path = line.slice(tab + 1);
                paths[output] = path;
                names[output] = path.slice(path.lastIndexOf("/") + 1);
            }
            root.screenWallpaperPaths = paths;
            root.screenWallpapers = names;
        }
        onFileChanged: reload()
    }

    function setWallpaper(screenName: string, path: string, transition: string): void {
        root.wallpaperChanged(screenName, path, transition ? transition : "fade");
    }

    function getWallpaper(screenName: string): string {
        if (!screenName || screenName === "") {
            return root.currentPath.slice(root.currentPath.lastIndexOf("/") + 1);
        }
        return root.screenWallpapers[screenName] || root.currentPath.slice(root.currentPath.lastIndexOf("/") + 1);
    }

    function getWallpaperPath(screenName: string): string {
        if (!screenName || screenName === "") {
            return root.currentPath;
        }
        return root.screenWallpaperPaths[screenName] || root.currentPath;
    }

    function setPlayback(screenName: string, state: string): void {
        root.playbackChanged(screenName, state);
    }

    function clearWallpaper(screenName: string): void {
        root.wallpaperCleared(screenName);
    }

    IpcHandler {
        target: "wallpaper"

        function setWallpaper(screenName: string, path: string, transition: string): void {
            root.setWallpaper(screenName, path, transition);
        }

        function getWallpaper(screenName: string): string {
            return root.getWallpaper(screenName);
        }

        function getWallpaperPath(screenName: string): string {
            return root.getWallpaperPath(screenName);
        }

        function setPlayback(screenName: string, state: string): void {
            root.setPlayback(screenName, state);
        }

        function clearWallpaper(screenName: string): void {
            root.clearWallpaper(screenName);
        }
    }
}
