pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Live weather for the pill's hover glance, served by Open-Meteo with no API key.
 * Location resolves once and is cached so a restart never re-hits the network for
 * coordinates: by default GeoClue locates the machine from the wifi networks in
 * range (the keyless ip-api lookup covers a missing GeoClue) and OpenStreetMap
 * names the spot, but a non-empty `Flags.weatherCity` override (a town name, or
 * exact "lat,lon") wins. Once coordinates are known the forecast runs
 * immediately and then every 20 minutes, exposing the current conditions plus a
 * 24-hour hourly strip.
 *
 * Everything is async through `Process` + `curl`, mirroring how Sysmon and Devices
 * fetch, so startup never blocks on a slow or absent connection. Every JSON parse
 * is guarded: a partial body or network blip leaves the last good values in place.
 * The last successful forecast is also cached to disk, so the instant the deferred
 * singleton arms on first hover the glance renders instantly from cache and the
 * fresh fetch lands ~1 second later in the background.
 *
 * Conditions render as on-brand kanji rather than icons — 晴 clear, 曇 cloud,
 * 雨 rain, 雪 snow, 霧 fog, 雷 thunder, 月 a clear night — keyed off the WMO weather
 * code via `glyphFor`, with `labelFor` giving the short english word.
 */
Singleton {
    id: root

    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/island/weather"

    property int tempNow: 0
    property int codeNow: 0
    property int humidity: 0
    property bool isDay: true
    property string city: ""
    property var hourly: []
    property var daily: []
    property bool ready: false

    property real lat: 0
    property real lon: 0
    property bool located: false

    /**
     * Set the first time any weather UI is demanded (pill expands / a surface
     * opens). Until then nothing touches the network: the chip renders from the
     * disk cache, and the 20-minute refresh stays silent. This keeps the
     * always-built chip layout-stable and instant from the first frame.
     */
    property bool needed: false

    /**
     * Maps a WMO weather code to its on-brand kanji. Clear skies show 月 at night
     * so the glance reads day-versus-night at a glance; every other condition is
     * the same glyph round the clock.
     */
    function glyphFor(code, day) {
        if (code === 0)
            return day ? "sun" : "moon";
        if (code <= 3)
            return "cloud";
        if (code === 45 || code === 48)
            return "cloud-fog";
        if (code >= 95)
            return "cloud-lightning";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "cloud-snow";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "cloud-rain";
        return "cloud";
    }

    /** Short english word for a WMO weather code, for labels and accessibility. */
    function labelFor(code) {
        if (code === 0)
            return "Clear";
        if (code <= 3)
            return "Cloudy";
        if (code === 45 || code === 48)
            return "Fog";
        if (code >= 95)
            return "Thunder";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "Snow";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "Rain";
        return "Cloudy";
    }

    /** Persist resolved coordinates so a restart skips the location round-trip. */
    function writeLoc() {
        locCache.setText(JSON.stringify({ city: root.city, lat: root.lat, lon: root.lon }));
    }

    /**
     * Persists the last good forecast so a fresh session shows conditions instantly
     * instead of a blank chip while the first fetch runs.
     */
    function writeWeather() {
        weatherCache.setText(JSON.stringify({
            tempNow: root.tempNow,
            codeNow: root.codeNow,
            humidity: root.humidity,
            isDay: root.isDay,
            ts: Date.now()
        }));
    }

    /**
     * Applies the cached forecast synchronously (blockLoading) at instantiation.
     * No network is touched; the in-flight fetch overwrites these within ~1 s.
     */
    function loadWeatherCache() {
        try {
            var c = JSON.parse(weatherCache.text());
            if (c && typeof c.codeNow === "number") {
                root.tempNow = c.tempNow || 0;
                root.codeNow = c.codeNow;
                root.humidity = c.humidity || 0;
                root.isDay = c.isDay !== false;
                root.ready = true;
            }
        } catch (e) {}
    }

    function fetchWeather() {
        if (!root.needed || !located || wxProc.running)
            return;
        wxProc.running = true;
    }

    readonly property bool hasOverride: (Flags.weatherCity || "").trim().length > 0

    /**
     * First weather demand arms the network path (loads fresh data on hover). The
     * cached spot renders at once; without a manual override a fresh GeoClue fix
     * is taken each session too, since a laptop moves between them.
     */
    onNeededChanged: {
        if (!root.needed)
            return;
        if (root.located)
            root.fetchWeather();
        if (!root.located || !root.hasOverride)
            root.locate();
    }

    /**
     * Loads cached coordinates synchronously (blockLoading) but defers location
     * lookup and the forecast fetch until `needed` (first hover / surface open).
     * The cached forecast already made `ready` true, so the arm shows instantly.
     */
    Component.onCompleted: {
        root.loadWeatherCache();
        try {
            var c = JSON.parse(locCache.text());
            if (c && typeof c.lat === "number" && typeof c.lon === "number") {
                root.city = c.city || "";
                root.lat = c.lat;
                root.lon = c.lon;
                root.located = true;
            }
        } catch (e) {}
    }

    FileView {
        id: locCache
        path: root.cacheDir + "/weather-loc.json"
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: weatherCache
        path: root.cacheDir + "/weather-cache.json"
        blockLoading: true
        printErrors: false
    }

    /**
     * Resolve coordinates: an exact "lat,lon" override is used as-is, a town name
     * is geocoded, and an empty override asks GeoClue (IP lookup as the fallback).
     */
    function locate() {
        if (!root.needed)
            return;
        var q = (Flags.weatherCity || "").trim();
        var m = q.match(/^(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)$/);
        if (m) {
            root.lat = Number(m[1]);
            root.lon = Number(m[2]);
            root.city = root.lat.toFixed(3) + ", " + root.lon.toFixed(3);
            root.located = true;
            root.writeLoc();
            root.fetchWeather();
        } else if (q.length > 0) {
            geoProc.running = true;
        } else if (!geoclueProc.running) {
            geoclueProc.running = true;
        }
    }

    /**
     * Precise location through GeoClue, the system location service: it looks the
     * wifi networks in range up itself. The where-am-i demo client prints every fix
     * it gets before its timeout and the most accurate one wins. GeoClue only
     * answers clients an agent authorises, so the demo agent (whitelisted in
     * geoclue.conf) is started first when none is running. No fix at all, or no
     * GeoClue installed, falls back to the IP lookup.
     */
    Process {
        id: geoclueProc
        command: ["sh", "-c",
            "w=/usr/lib/geoclue-2.0/demos/where-am-i; a=/usr/lib/geoclue-2.0/demos/agent; " +
            "[ -x \"$w\" ] || exit 0; " +
            "pgrep -f \"^$a\" >/dev/null || { setsid -f \"$a\" >/dev/null 2>&1 < /dev/null; sleep 1; }; " +
            "timeout 40 \"$w\" -t 30 -a 8 2>/dev/null | awk -F': *' '" +
            "/^Latitude/ { lat = $2 + 0 } /^Longitude/ { lon = $2 + 0 } " +
            "/^Accuracy/ { acc = $2 + 0; if (best == \"\" || acc < best) { best = acc; blat = lat; blon = lon } } " +
            "END { if (best != \"\") printf \"%.6f %.6f %d\\n\", blat, blon, best }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = this.text.trim().split(/\s+/);
                var lat = parseFloat(f[0]);
                var lon = parseFloat(f[1]);
                if (f.length < 3 || isNaN(lat) || isNaN(lon)) {
                    if (!root.located)
                        ipProc.running = true;
                    return;
                }
                root.lat = lat;
                root.lon = lon;
                root.located = true;
                root.writeLoc();
                root.fetchWeather();
                placeProc.running = true;
            }
        }
    }

    /** Names a GeoClue fix (which carries no place name) with one OpenStreetMap lookup. */
    Process {
        id: placeProc
        command: ["curl", "-s", "--max-time", "8", "-G", "-A", "island-weather/1.0 (quickshell)",
            "https://nominatim.openstreetmap.org/reverse",
            "--data-urlencode", "lat=" + root.lat,
            "--data-urlencode", "lon=" + root.lon,
            "--data-urlencode", "format=jsonv2",
            "--data-urlencode", "zoom=10",
            "--data-urlencode", "accept-language=en"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var a = JSON.parse(this.text).address || {};
                    var name = a.town || a.city || a.village || a.municipality || a.county || "";
                    if (name.length > 0) {
                        root.city = name;
                        root.writeLoc();
                    }
                } catch (e) {}
            }
        }
    }

    /** Re-locate hourly while in automatic mode, in case the laptop moved. */
    Timer {
        interval: 3600000
        running: root.needed && !root.hasOverride
        repeat: true
        onTriggered: root.locate()
    }

    Connections {
        target: Flags
        function onWeatherCityChanged() { root.locate(); }
    }

    Process {
        id: ipProc
        command: ["curl", "-s", "--max-time", "8", "http://ip-api.com/json?fields=lat,lon,city"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text);
                    if (typeof d.lat === "number" && typeof d.lon === "number") {
                        root.city = d.city || "";
                        root.lat = d.lat;
                        root.lon = d.lon;
                        root.located = true;
                        root.writeLoc();
                        root.fetchWeather();
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: geoProc
        command: ["curl", "-s", "--max-time", "8", "-G",
            "https://geocoding-api.open-meteo.com/v1/search",
            "--data-urlencode", "name=" + (Flags.weatherCity || ""),
            "--data-urlencode", "count=1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text);
                    var r = d.results && d.results[0];
                    if (r && typeof r.latitude === "number" && typeof r.longitude === "number") {
                        root.city = r.name || "";
                        root.lat = r.latitude;
                        root.lon = r.longitude;
                        root.located = true;
                        root.writeLoc();
                        root.fetchWeather();
                    } else {
                        ipProc.running = true;
                    }
                } catch (e) { ipProc.running = true; }
            }
        }
    }

    Process {
        id: wxProc
        command: ["curl", "-s", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + root.lat
            + "&longitude=" + root.lon
            + "&current=temperature_2m,weather_code,is_day,relative_humidity_2m"
            + "&hourly=temperature_2m,weather_code&forecast_hours=24"
            + "&daily=weather_code,temperature_2m_max,relative_humidity_2m_mean&forecast_days=5&timezone=auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text);
                    var cur = d.current;
                    if (!cur)
                        return;
                    var rows = [];
                    var h = d.hourly;
                    if (h && h.time && h.temperature_2m && h.weather_code) {
                        var n = Math.min(h.time.length, h.temperature_2m.length, h.weather_code.length);
                        for (var i = 0; i < n; i++) {
                            rows.push({
                                hour: h.time[i].slice(11, 13),
                                temp: Math.round(h.temperature_2m[i]),
                                code: h.weather_code[i]
                            });
                        }
                    }
                    var days = [];
                    var dd = d.daily;
                    if (dd && dd.time && dd.weather_code && dd.temperature_2m_max && dd.relative_humidity_2m_mean) {
                        var dn = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                        var m = Math.min(dd.time.length, dd.weather_code.length, dd.temperature_2m_max.length, dd.relative_humidity_2m_mean.length);
                        for (var j = 0; j < m; j++) {
                            days.push({
                                day: dn[new Date(dd.time[j]).getDay()],
                                code: dd.weather_code[j],
                                temp: Math.round(dd.temperature_2m_max[j]),
                                rh: Math.round(dd.relative_humidity_2m_mean[j])
                            });
                        }
                    }
                    root.tempNow = Math.round(cur.temperature_2m);
                    root.codeNow = cur.weather_code;
                    root.humidity = Math.round(cur.relative_humidity_2m);
                    root.isDay = cur.is_day === 1;
                    root.hourly = rows;
                    root.daily = days;
                    root.ready = true;
                    root.writeWeather();
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1200000
        running: true
        repeat: true
        onTriggered: root.fetchWeather()
    }
}
