pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var seenIds: ({})
    property var arrivalMs: ({})
    property var popups: []
    property int tick: 0
    property var expandedApps: ({})
    property var history: []
    property var userDismissed: ({})
    property var expireAt: ({})
    property var hookedIds: ({})

    /**
     * Arrival times, read state and history across QS reloads: the server keeps
     * the notifications themselves (keepOnReload), but this singleton restarts
     * empty, so ages read "now" and everything turned unread. Stored as JSON
     * text because the restore copies values between engines, which strings
     * survive. `reloaded` lands after the server may have re-sent notifications,
     * so the old values are merged in over whatever was filled meanwhile.
     */
    PersistentProperties {
        id: persist
        reloadableId: "islandNotifs"
        property string arrivalJson: "{}"
        property string seenJson: "{}"
        property string historyJson: "[]"
        onReloaded: {
            root.arrivalMs = Object.assign({}, root.arrivalMs, JSON.parse(arrivalJson));
            root.seenIds = Object.assign({}, root.seenIds, JSON.parse(seenJson));
            root.history = JSON.parse(historyJson).concat(root.history).slice(0, 50);
        }
    }
    onArrivalMsChanged: persist.arrivalJson = JSON.stringify(arrivalMs)
    onSeenIdsChanged: persist.seenJson = JSON.stringify(seenIds)
    onHistoryChanged: persist.historyJson = JSON.stringify(history)

    readonly property var tracked: server.trackedNotifications.values
    readonly property int count: tracked.length + history.length

    /** The toast actually shown is the newest popup; critical flags whether it must never be covered. */
    readonly property bool toastCritical: {
        var p = popups;
        return p.length > 0 && p[p.length - 1].urgency === NotificationUrgency.Critical;
    }

    readonly property int unread: {
        var u = 0;
        for (var i = 0; i < tracked.length; i++)
            if (!seenIds[tracked[i].id]) u++;
        return u;
    }

    readonly property var groups: {
        var map = {};
        var order = [];
        for (var i = 0; i < tracked.length; i++) {
            var n = tracked[i];
            var app = (n.appName && n.appName.length) ? n.appName : "System";
            if (map[app] === undefined) { map[app] = []; order.push(app); }
            map[app].push({ live: true, n: n, t: arrivalMs[n.id] || 0 });
        }
        for (var j = 0; j < history.length; j++) {
            var h = history[j];
            if (map[h.app] === undefined) { map[h.app] = []; order.push(h.app); }
            map[h.app].push({ live: false, n: h, t: h.ts || 0 });
        }
        function coalesce(list, it) {
            var last = list.length > 0 ? list[list.length - 1] : null;
            if (last && last.n.summary === it.n.summary && last.n.body === it.n.body) {
                last.count++;
                last.items.push(it.n);
            } else {
                list.push({ live: it.live, n: it.n, count: 1, items: [it.n] });
            }
        }
        var gs = order.map(function(app) {
            var items = map[app];
            items.sort(function(a, b) { return b.t - a.t; });
            var criticals = [];
            var entries = [];
            for (var k = 0; k < items.length; k++)
                coalesce(items[k].n.urgency === NotificationUrgency.Critical ? criticals : entries, items[k]);
            var preview = items.find(function(it) { return it.n.urgency !== NotificationUrgency.Critical; });
            return {
                app: app,
                count: items.length,
                t: items[0].t,
                newest: items[0].n,
                preview: preview ? preview.n : items[0].n,
                criticals: criticals,
                entries: entries
            };
        });
        gs.sort(function(a, b) { return b.t - a.t; });
        return gs;
    }

    function iconFor(n) {
        if (!n) return "";
        var img = n.image || "";
        var names = [];
        if (img.indexOf("image://icon/") === 0) {
            names.push(img.substring(13));
        } else if (img.length && !/\.svg$/i.test(img)) {
            return img;
        }
        names.push(n.appIcon, n.desktopEntry, (n.appName || n.app || "").toLowerCase());
        for (var i = 0; i < names.length; i++) {
            var nm = names[i];
            if (!nm || !nm.length) continue;
            if (nm.indexOf("/") === 0 || nm.indexOf("file://") === 0) return nm;
            var p = Quickshell.iconPath(nm, true);
            if (p.length) return p;
        }
        return "";
    }

    /**
     * The app's themed icon by name, skipping images and paths: the fallback once
     * iconFor's pick fails to load (Chromium's temp image is already gone, a sent
     * icon path does not exist).
     */
    function appIconFor(n) {
        if (!n) return "";
        var names = [n.appIcon, n.desktopEntry, (n.appName || n.app || "").toLowerCase()];
        for (var i = 0; i < names.length; i++) {
            var nm = names[i];
            if (!nm || nm.indexOf("/") >= 0) continue;
            var p = Quickshell.iconPath(nm, true);
            if (p.length) return p;
        }
        return "";
    }

    function dismissEntry(e) {
        if (!e || !e.items) return;
        var d = Object.assign({}, userDismissed);
        var gone = {};
        var live = [];
        for (var i = 0; i < e.items.length; i++) {
            var n = e.items[i];
            // tracked, not "has dismiss()": a notification invoke() just closed is not dismissable again
            if (root.tracked.indexOf(n) >= 0) {
                d[n.id] = true;
                live.push(n);
            } else {
                gone[n.id] = true;
            }
        }
        root.userDismissed = d;
        for (var j = 0; j < live.length; j++) live[j].dismiss();
        root.history = root.history.filter(function(h) { return !gone[h.id]; });
    }

    /**
     * Focus the app's Hyprland window (workspace switch included) by matching the
     * notification's desktopEntry/appName against the live window classes.
     */
    function raiseWindow(n) {
        if (!n) return;
        var token = String(n.desktopEntry && n.desktopEntry.length ? n.desktopEntry : (n.appName || "")).toLowerCase();
        if (token.length === 0) return;
        Quickshell.execDetached(["sh", "-c",
            "addr=$(hyprctl clients -j | jq -r --arg q \"$1\" 'first(.[] | select(((.class | if . then ascii_downcase else \"\" end) | contains($q)) or ((.initialClass | if . then ascii_downcase else \"\" end) | contains($q))) | .address)'); [ -n \"$addr\" ] && hyprctl dispatch \"hl.dsp.focus({ window = \\\"address:$addr\\\" })\"",
            "sh", token]);
    }

    /**
     * Open the app behind a notification: invoke its default action when present,
     * then jump to the app's window, mirroring stock notification-center behavior.
     */
    function activateNotif(n) {
        if (!n) return;
        var acts = n.actions || [];
        for (var i = 0; i < acts.length; i++) {
            if (acts[i].identifier === "default") {
                acts[i].invoke();
                break;
            }
        }
        raiseWindow(n);
    }

    /** Inbox-row entry wrapper: activate the app, then dismiss the entry. */
    function activateEntry(e) {
        if (!e || !e.n) return;
        // invoke() closes a non-resident notification on the spot, and the closed
        // handler files anything not marked dismissed into history, so mark first.
        var d = Object.assign({}, userDismissed);
        for (var i = 0; i < e.items.length; i++)
            if (root.tracked.indexOf(e.items[i]) >= 0)
                d[e.items[i].id] = true;
        root.userDismissed = d;
        activateNotif(e.n);
        dismissEntry(e);
    }

    function dismissApp(app) {
        var doomed = tracked.filter(function(n) {
            return ((n.appName && n.appName.length) ? n.appName : "System") === app;
        });
        var d = Object.assign({}, userDismissed);
        for (var i = 0; i < doomed.length; i++) d[doomed[i].id] = true;
        root.userDismissed = d;
        for (var j = 0; j < doomed.length; j++) doomed[j].dismiss();
        root.history = root.history.filter(function(h) { return h.app !== app; });
    }

    function markAllSeen() {
        var m = {};
        for (var i = 0; i < tracked.length; i++) m[tracked[i].id] = true;
        root.seenIds = m;
    }

    function clearAll() {
        var l = tracked.slice();
        var d = Object.assign({}, userDismissed);
        for (var i = 0; i < l.length; i++) d[l[i].id] = true;
        root.userDismissed = d;
        for (var j = 0; j < l.length; j++) l[j].dismiss();
        root.history = [];
        root.popups = [];
    }

    function pruneOld(now) {
        now = now || Date.now();
        var cutoff = now - 3600000;
        root.history = root.history.filter(function(h) { return (h.ts || now) >= cutoff; });
        var stale = tracked.filter(function(n) { return (arrivalMs[n.id] || now) < cutoff; });
        if (stale.length === 0) return;
        var d = Object.assign({}, userDismissed);
        for (var i = 0; i < stale.length; i++) d[stale[i].id] = true;
        root.userDismissed = d;
        for (var j = 0; j < stale.length; j++) stale[j].dismiss();
    }

    function removePopup(n) {
        if (n.appName === "Calendar")
            Events.stopBeep();
        root.popups = root.popups.filter(function(p) { return p !== n; });
    }

    /** Queue n as the newest toast; Do Not Disturb holds back all but criticals. */
    function showPopup(n) {
        if (Flags.dnd && n.urgency !== NotificationUrgency.Critical)
            return;
        var e = Object.assign({}, root.expireAt);
        e[n.id] = Date.now() + 3000;
        root.expireAt = e;
        root.popups = root.popups.concat([n]).slice(-3);
    }

    /** Drop every non-critical popup whose deadline has passed (50ms slack for timer jitter). */
    function expirePopups() {
        var now = Date.now() + 50;
        var gone = root.popups.filter(function(p) {
            return p.urgency !== NotificationUrgency.Critical && (root.expireAt[p.id] || 0) <= now;
        });
        for (var i = 0; i < gone.length; i++)
            root.removePopup(gone[i]);
    }

    /**
     * Drop every pending popup at once. Used when a transient OSD covers a
     * non-critical toast: the toast is retired permanently instead of
     * reappearing when the OSD ends and looking like a second notification.
     * The notification itself stays tracked, so the inbox and unread dot
     * still show it.
     */
    function clearPopups() {
        root.popups = [];
    }

    /** App groups start expanded; only an explicit `false` collapses one. */
    function toggleExpanded(app) {
        var e = Object.assign({}, expandedApps);
        e[app] = e[app] === false;
        root.expandedApps = e;
    }

    /**
     * Bind the history-snapshot handler to a notification's `closed` signal, and
     * the re-toast handler to its replacement, once.
     * `keepOnReload` re-runs Component.onCompleted on every QS reload over the
     * still-tracked notifications, so the id set gates re-hooks: without it each
     * reload would stack another handler and a single close would push duplicate
     * history rows. The id is cleared inside the handler so a later notification
     * reusing the id re-hooks cleanly.
     */
    function hookClosed(n) {
        if (root.hookedIds[n.id])
            return;
        var hooked = Object.assign({}, root.hookedIds);
        hooked[n.id] = true;
        root.hookedIds = hooked;
        // A replacement (notify-send -r) updates this same object and emits no new
        // `notification`, so toast it again unless it is still queued. libnotify's
        // per-process sender-pid hint makes even a same-text repeat change `hints`.
        var replaced = function() {
            if (root.popups.indexOf(n) < 0)
                root.showPopup(n);
        };
        n.summaryChanged.connect(replaced);
        n.bodyChanged.connect(replaced);
        n.hintsChanged.connect(replaced);
        n.closed.connect(function(reason) {
            if (!root.userDismissed[n.id])
                root.history = [{
                    app: (n.appName && n.appName.length) ? n.appName : "System",
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    desktopEntry: n.desktopEntry,
                    // browsers pass a temp file they delete on close; drop it so the row falls back to the app icon
                    image: /^(file:\/\/)?\/tmp\//.test(n.image || "") ? "" : n.image,
                    urgency: n.urgency,
                    ts: root.arrivalMs[n.id] || Date.now(),
                    id: "h" + n.id + "-" + Date.now()
                }].concat(root.history).slice(0, 50);
            else {
                var du = Object.assign({}, root.userDismissed);
                delete du[n.id];
                root.userDismissed = du;
            }
            root.removePopup(n);
            var b = Object.assign({}, root.arrivalMs);
            delete b[n.id];
            root.arrivalMs = b;
            var c = Object.assign({}, root.expireAt);
            delete c[n.id];
            root.expireAt = c;
            var h = Object.assign({}, root.hookedIds);
            delete h[n.id];
            root.hookedIds = h;
        });
    }

    function ageLabel(n) {
        void root.tick;
        var t = arrivalMs[n.id] || n.ts;
        if (!t) return "";
        var m = Math.floor((Date.now() - t) / 60000);
        if (m < 1) return "now";
        if (m < 60) return m + "m";
        return Math.floor(m / 60) + "h";
    }

    Timer {
        interval: 30000
        running: root.count > 0
        repeat: true
        onTriggered: {
            root.tick++;
            root.pruneOld();
        }
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true

        Component.onCompleted: {
            var l = trackedNotifications.values;
            var a = Object.assign({}, root.arrivalMs);
            for (var i = 0; i < l.length; i++) {
                if (!a[l[i].id]) a[l[i].id] = Date.now();
                root.hookClosed(l[i]);
            }
            root.arrivalMs = a;
        }

        onNotification: function(n) {
            var a = Object.assign({}, root.arrivalMs);
            if (!n.lastGeneration || !a[n.id])   // a re-sent one keeps its restored arrival
                a[n.id] = Date.now();
            root.arrivalMs = a;
            n.tracked = true;
            root.hookClosed(n);
            // keepOnReload re-sends every held notification on each reload; it was toasted already.
            if (!n.lastGeneration)
                root.showPopup(n);
        }
    }
}
