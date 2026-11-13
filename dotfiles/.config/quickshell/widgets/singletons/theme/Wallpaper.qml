pragma Singleton
import QtQuick
import "../../../island/Singletons" as Island

// DotRobot: the picker's wallpaper state. ../../../WallpaperPanel.qml bridges
// wallpaperChanged to island's backend; what each screen shows is island's
// Walls.shown (wallpaper.sh's per-output map).
QtObject {
    signal wallpaperChanged(string screenName, string path, string transition)

    function setWallpaper(screenName: string, path: string, transition: string): void {
        wallpaperChanged(screenName, path, transition ? transition : "fade");
    }

    /** File name shown on screenName, else on the first mapped screen. */
    function getWallpaper(screenName: string): string {
        const shown = Island.Walls.shown;
        const hit = shown.find(e => e[0] === screenName) || shown[0];
        return hit ? hit[1].slice(hit[1].lastIndexOf("/") + 1) : "";
    }
}
