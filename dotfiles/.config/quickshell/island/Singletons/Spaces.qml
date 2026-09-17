pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * 場 SPACES store: reads the Hyprland spaces config path, the user-defined
 * special workspaces. Each entry is { id, name, desc, key, glyph, apps[] }: id is
 * the special-workspace name, key a single Super-prefixed letter, glyph an
 * optional GlyphIcon name, apps the window classes that auto-route in. The pill
 * reads `list` to name the special workspace it is showing.
 *
 * Read-only: the settings page that wrote this file is gone, so the writer,
 * its `hyprctl reload` and the whole add/rename/route API went with it (git
 * history has them if the page comes back).
 */
Singleton {
    id: root

    readonly property string path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/island/spaces.lua"
    property var list: []

    /** Pull the fields out of one `{ ... }` entry block. Null when it has no id. */
    function parseEntry(block) {
        var id = root.field(block, "id");
        if (id.length === 0)
            return null;
        var apps = [];
        var am = block.match(/apps\s*=\s*{([^}]*)}/);
        if (am) {
            var re = /"([^"]*)"/g;
            var m;
            while ((m = re.exec(am[1])) !== null)
                if (m[1].length > 0)
                    apps.push(m[1]);
        }
        return {
            id: id,
            name: root.field(block, "name") || id,
            desc: root.field(block, "desc"),
            key: root.field(block, "key"),
            glyph: root.field(block, "glyph"),
            apps: apps
        };
    }

    function field(block, key) {
        var m = block.match(new RegExp("\\b" + key + "\\s*=\\s*\"([^\"]*)\""));
        return m ? m[1] : "";
    }

    /**
     * Walk the `return { ... }` table brace by brace, slicing every top-level
     * entry block (depth 2) and parsing it. The nested apps `{ ... }` sits at
     * depth 3 so it never opens a spurious entry.
     */
    function parse(text) {
        var ri = text.indexOf("return");
        var body = ri >= 0 ? text.slice(ri) : text;
        var ob = body.indexOf("{");
        if (ob < 0)
            return [];
        var out = [];
        var depth = 0;
        var start = -1;
        for (var i = ob; i < body.length; i++) {
            var c = body[i];
            if (c === "{") {
                depth++;
                if (depth === 2)
                    start = i;
            } else if (c === "}") {
                if (depth === 2 && start >= 0) {
                    var e = root.parseEntry(body.slice(start, i + 1));
                    if (e)
                        out.push(e);
                    start = -1;
                }
                depth--;
                if (depth === 0)
                    break;
            }
        }
        return out;
    }

    function refresh() {
        root.list = root.parse(spacesFile.text());
    }

    FileView {
        id: spacesFile
        path: root.path
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.refresh()
        onFileChanged: reload()
    }

    Component.onCompleted: root.refresh()
}
