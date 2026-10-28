import QtQuick
import Quickshell
import "island/Singletons" as Island

ShellRoot {
    Timer {
        interval: 200
        running: true
        onTriggered: {
            if (!Island.Weather.ready || Island.Weather.daily.length !== 2
                    || Island.Weather.daily[0].temp !== 18 || Island.Weather.daily[1].temp !== 19) {
                console.error("Weather cache read failed");
                Qt.quit();
                return;
            }
            const today = Qt.formatDate(new Date(), "yyyy-MM-dd");
            Island.Weather.daily = [{ date: "2000-01-01", day: "old", code: 3, temp: 1 },
                { date: today, day: "Wed", code: 3, temp: 21 }];
            rollover.running = true;
        }
    }
    Timer {
        id: rollover
        interval: 300
        onTriggered: {
            const today = Qt.formatDate(new Date(), "yyyy-MM-dd");
            if (Island.Weather.daily.length !== 1 || Island.Weather.daily[0].date !== today) {
                console.error("Weather rollover failed");
                Qt.quit();
                return;
            }
            Island.Weather.writeWeather();
            done.running = true;
        }
    }
    Timer {
        id: done
        interval: 300
        onTriggered: { console.log("Weather cache read, rollover and write passed."); Qt.quit(); }
    }
}
