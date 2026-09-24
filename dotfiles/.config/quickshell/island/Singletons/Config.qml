pragma Singleton
import QtQuick
import Quickshell
import "../../widgets" as Widgets

/**
 * Path authority for the pill, kept as one self-locating source of truth. The
 * app root is this file's own directory tree (the quickshell project folder),
 * so nothing depends on where the shell was launched from or on exported
 * ISLAND_* environment variables. Hyprland-compat outputs (generated modules/*,
 * hypridle.conf, hyprsunset.conf and scripts/) all resolve under the same
 * project folder.
 */
Singleton {
    id: root

    // The picker and drag-and-drop must save/read the same collection.
    readonly property string wallpaperDir: Flags.wallpaperDir
        || Widgets.Config.rawSettings.wallpaperDir
        || Widgets.Config.rawSettings.wallpaper_dir
        || Quickshell.env("WALLPAPER_DIR")
        || (Quickshell.env("HOME") + "/Pictures/wallpapers")

    /** Absolute filesystem path of the quickshell project folder (parent of Singletons/). */
    readonly property string configDir: {
        var p = root._localPath(Qt.resolvedUrl("../"));
        return p.length > 1 && p.slice(-1) === "/" ? p.slice(0, -1) : p;
    }

    function _localPath(url) {
        var s = String(url);
        if (s.indexOf("file://") === 0) {
            s = s.substring(7);
            try { s = decodeURIComponent(s); } catch (e) {}
        }
        return s;
    }

    /** Join a path under the project folder, e.g. islandPath("scripts", "lock.sh"). */
    function islandPath() {
        var parts = Array.prototype.slice.call(arguments);
        return root.join(root.configDir, parts);
    }

    function join(base, parts) {
        var out = String(base || "");
        for (var i = 0; i < parts.length; i++) {
            var next = String(parts[i] || "");
            if (!next)
                continue;
            if (out.length === 0)
                out = next;
            else if (out.slice(-1) === "/")
                out += next.replace(/^\//, "");
            else
                out += "/" + next.replace(/^\//, "");
        }
        return out;
    }
}
