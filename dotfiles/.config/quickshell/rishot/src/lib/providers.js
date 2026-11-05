/**
 * Window enumeration for region-mode window-snap: turns Hyprland's CLI query
 * output into window rectangles in GLOBAL compositor coordinates:
 *   [{ x, y, w, h, z }]
 * A smaller z means the window is visually closer to the top, matching the
 * caller's hit test which prefers the rect with the lowest z under the cursor.
 * On any parse error it returns [] so region and monitor selection still work.
 */

/**
 * Parse Hyprland monitor and client JSON into global window rects.
 *
 * Replicates the union of `hyprctl monitors -j` active-workspace collection and
 * `hyprctl clients -j` window filtering: a client is kept only when it is mapped
 * and not hidden, sits on an active workspace, and has a positive size.
 *
 * @param {string} monitorsJson Raw stdout of `hyprctl monitors -j`.
 * @param {string} clientsJson Raw stdout of `hyprctl clients -j`.
 * @returns {Array<{x: number, y: number, w: number, h: number, z: number}>}
 */
function parseHyprland(monitorsJson, clientsJson) {
    var rects = [];
    try {
        var activeWs = [];
        var monitors = JSON.parse(monitorsJson);
        for (var m = 0; m < monitors.length; m++) {
            if (monitors[m].activeWorkspace) activeWs.push(monitors[m].activeWorkspace.id);
        }
        var clients = JSON.parse(clientsJson);
        for (var i = 0; i < clients.length; i++) {
            var c = clients[i];
            if (!c.mapped || c.hidden) continue;
            if (!c.workspace || activeWs.indexOf(c.workspace.id) === -1) continue;
            if (!c.size || c.size[0] <= 0 || c.size[1] <= 0) continue;
            if (!c.at) continue;
            rects.push({ x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1], z: c.focusHistoryID });
        }
    } catch (e) {
        return [];
    }
    return rects;
}
