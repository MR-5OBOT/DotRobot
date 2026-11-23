pragma Singleton
import QtQuick
import "../../../island/Singletons" as Island

// DotRobot: what each screen shows, from island's Walls.shown (wallpaper.sh's
// per-output map). The picker applies through Island.Walls.apply directly.
QtObject {
    /** File name shown on screenName, else on the first mapped screen. */
    function getWallpaper(screenName: string): string {
        const shown = Island.Walls.shown;
        const hit = shown.find(e => e[0] === screenName) || shown[0];
        return hit ? hit[1].slice(hit[1].lastIndexOf("/") + 1) : "";
    }
}
