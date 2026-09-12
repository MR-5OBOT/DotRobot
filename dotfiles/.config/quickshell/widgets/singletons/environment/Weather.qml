pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// DotRobot replacement for serpantinum's Weather, which shells out to its
// weather.sh/location.sh and writes your IP geolocation into settings.json
// (tracked in this repo). Same properties the bar and the calendar popup read.
// Location: general.location {latitude, longitude} in settings.json if set,
// else looked up by IP (ipwho.is) once a day and cached under ~/.cache.
// Forecast: open-meteo, no API key. `data` is rebuilt here in the shape
// weather.sh used to emit, because CalendarPopup binds to those field names.
Item {
    id: root

    readonly property var general: Config.getSetting("general", {})
    readonly property string unit: general.weatherUnit ?? "metric"
    readonly property int refreshInterval: (general.weatherInterval ?? 15) * 60000
    readonly property string unitSym: unit === "imperial" ? "°F" : "°C"

    // current conditions — what the bar's weather module reads
    property string currentIcon: ""
    property string currentTemp: ""
    property string currentTempFormatted: "--°"
    property string currentHex: "#f9e2af"
    property bool isLoading: false
    property bool isReady: false
    // the whole payload — what the calendar popup reads (see build()).
    // Starts with an empty forecast: the popup guards `data` but then indexes
    // `data.forecast[n]`, so a bare {} throws on its first frames.
    property var data: ({ forecast: [] })
    signal weatherUpdated()

    // WMO weather code -> serpantinum's glyph, colour and description
    function wmo(code, isDay) {
        if (code === 0)
            return isDay ? [0xf185, "#f9e2af", "Sunny"] : [0xf186, "#cba6f7", "Clear"];
        if (code >= 1 && code <= 3)
            return [0xf0c2, "#bac2de", "Cloudy"];
        if (code === 45 || code === 48)
            return [0xf0591, "#84afdb", "Mist"];
        if ((code >= 51 && code <= 57) || (code >= 61 && code <= 67) || (code >= 80 && code <= 82))
            return [0xf0597, "#74c7ec", "Rainy"];
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return [0xf2dc, "#cdd6f4", "Snow"];
        if (code === 95 || code === 96 || code === 99)
            return [0xf0e7, "#f9e2af", "Storm"];
        return [0xf0c2, "#cdd6f4", "Unknown"];
    }
    function glyph(m) { return String.fromCodePoint(m[0]); }
    function fmt(t) { return (Math.round((t ?? 0) * 10) / 10).toFixed(1); }

    // Rebuild what weather.sh emitted: five days, each with its highs and
    // averages plus three-hourly slots. CalendarPopup binds to these names.
    function build(api) {
        const cur = api.current ?? {};
        const h = api.hourly ?? {};
        const times = h.time ?? [];
        const pick = (arr, i) => (arr && arr[i] !== undefined && arr[i] !== null) ? arr[i] : 0;

        const order = [], byDate = {};
        for (let i = 0; i < times.length; i++) {
            const d = times[i].split("T")[0];
            if (!byDate[d]) { byDate[d] = []; order.push(d); }
            byDate[d].push(i);
        }

        const forecast = [];
        for (let di = 0; di < Math.min(5, order.length); di++) {
            const idx = byDate[order[di]];
            const temps = idx.map(i => pick(h.temperature_2m, i));
            const feels = idx.map(i => pick(h.apparent_temperature, i));
            const pops = idx.map(i => pick(h.precipitation_probability, i));
            const winds = idx.map(i => pick(h.wind_speed_10m, i));
            const hums = idx.map(i => pick(h.relative_humidity_2m, i));

            // the day's own icon comes from midday, its slots from every third hour
            const noon = idx.length > 12 ? idx[12] : idx[0];
            const dayMap = root.wmo(pick(h.weather_code, noon), true);
            // Today starts at the current hour, so the slot the popup
            // highlights reads "now" instead of the last three-hour mark.
            let startK = 0;
            if (di === 0) {
                const nowHour = new Date().getHours();
                for (let k = 0; k < idx.length; k++) {
                    if (parseInt(times[idx[k]].split("T")[1].split(":")[0]) >= nowHour) { startK = k; break; }
                }
            }
            const slots = [];
            for (let k = startK; k < idx.length; k += 3) {
                const i = idx[k];
                const clock = times[i].split("T")[1];
                const hour = parseInt(clock.split(":")[0]);
                const m = root.wmo(pick(h.weather_code, i), hour >= 6 && hour <= 18);
                slots.push({ time: clock, temp: root.fmt(pick(h.temperature_2m, i)), icon: root.glyph(m), hex: m[1] });
            }

            const dt = new Date(order[di] + "T12:00:00");
            forecast.push({
                id: String(di),
                day: dt.toLocaleDateString(Qt.locale("en_US"), "ddd"),
                day_full: dt.toLocaleDateString(Qt.locale("en_US"), "dddd"),
                date: dt.toLocaleDateString(Qt.locale("en_US"), "d MMM"),
                max: root.fmt(Math.max(...temps)),
                min: root.fmt(Math.min(...temps)),
                feels_like: root.fmt(Math.max(...feels)),
                wind: String(Math.round(Math.max(...winds))),
                humidity: String(Math.round(hums.reduce((a, b) => a + b, 0) / Math.max(1, hums.length))),
                pop: String(Math.round(Math.max(...pops))),
                icon: root.glyph(dayMap),
                hex: dayMap[1],
                desc: dayMap[2],
                hourly: slots
            });
        }

        const cm = root.wmo(cur.weather_code, cur.is_day === 1);
        return {
            latitude: api.latitude ?? 0,
            longitude: api.longitude ?? 0,
            city: api.city ?? "",
            unit: root.unit,
            unit_sym: root.unitSym,
            current_temp: root.fmt(cur.temperature_2m),
            current_temp_formatted: root.fmt(cur.temperature_2m) + root.unitSym,
            current_icon: root.glyph(cm),
            current_hex: cm[1],
            forecast: forecast
        };
    }

    function refresh() {
        root.isLoading = !root.isReady;
        fetch.running = true;
    }
    onUnitChanged: refresh()

    Connections {
        target: Config
        function onSettingsLoaded() { root.refresh(); }
    }
    Component.onCompleted: if (Config.dataReady) refresh()

    Process {
        id: fetch
        // $1 location cache, $2/$3 lat/lon (empty = look up by IP), $4 unit params
        command: ["bash", "-c", `
            loc="$1"; lat="$2"; lon="$3"
            if [ -z "$lat" ] || [ -z "$lon" ]; then
                mkdir -p "$(dirname "$loc")"
                if [ ! -s "$loc" ] || [ -z "$(jq -r '.city // empty' "$loc" 2>/dev/null)" ] || [ -n "$(find "$loc" -mmin +1440)" ]; then
                    curl -sf --max-time 8 https://ipwho.is/ | jq -ce 'select(.success) | {lat: .latitude, lon: .longitude, city: .city}' > "$loc.tmp" && mv "$loc.tmp" "$loc"
                    rm -f "$loc.tmp"
                fi
                read -r lat lon < <(jq -r '"\\(.lat) \\(.lon)"' "$loc" 2>/dev/null) || exit 1
            fi
            city="$(jq -r '.city // ""' "$loc" 2>/dev/null)"
            curl -sf --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&timezone=auto&forecast_days=5&current=temperature_2m,weather_code,is_day&hourly=temperature_2m,apparent_temperature,precipitation_probability,relative_humidity_2m,wind_speed_10m,weather_code$4" | jq -c --arg city "$city" '. + {city: $city}'`,
            "_", Caching.cacheDir + "/weather/location.json",
            String(root.general.location?.latitude ?? ""), String(root.general.location?.longitude ?? ""),
            root.unit === "imperial" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : ""]
        stdout: StdioCollector {
            onStreamFinished: {
                let api;
                try {
                    api = JSON.parse(text);
                } catch (e) {
                    return;
                }
                if (!api || !api.current)
                    return;
                const d = root.build(api);
                root.data = d;
                root.currentTemp = d.current_temp;
                root.currentTempFormatted = d.current_temp_formatted;
                root.currentIcon = d.current_icon;
                root.currentHex = d.current_hex;
                root.isReady = true;
                root.weatherUpdated();
            }
        }
        onExited: root.isLoading = false
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
