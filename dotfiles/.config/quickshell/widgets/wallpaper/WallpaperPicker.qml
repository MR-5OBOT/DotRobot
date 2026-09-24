import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.folderlistmodel
import QtMultimedia
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"
import "../reusables"
import "../../island/Singletons" as Island

Item {
    id: window
    width: Screen.width
    focus: true

    function s(val) {
        return Scaler.s(val);
    }

    readonly property string scriptDir: Quickshell.shellDir + "/widgets/scripts/wallpaper"   // DotRobot: vendored scripts
    // DotRobot: upstream reads window.hostScreen from its own Main.qml;
    // the host window sets this instead
    property var hostScreen: null

    property string widgetArg: ""
    property string targetWallName: ""
    property bool initialFocusSet: false
    property int scrollAccum: 0
    property real scrollThreshold: window.s(45)

    property var thumbLookup: ({})
    property var srcNameLookup: ({})

    property bool isApplying: false
    property bool isMonitorSelectorOpen: false
    property bool allowAddAnimation: false

    readonly property string srcDir: Island.Config.wallpaperDir

    onSrcDirChanged: {
        window.initialFocusSet = false;
        window.syncFromSrcModel();
        window.triggerIndexer();
    }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: view.forceActiveFocus()
    }

    readonly property real dynamicCacheBuffer: window.itemWidth * 3

    Timer {
        id: applyUnlockTimer
        interval: 150
        onTriggered: window.isApplying = false
    }

    property bool isReady: visible

    property bool isModelChanging: false

    ListModel { id: monitorModel }

    Process {
        id: monitorDetector
        running: false
        command: ["bash", Quickshell.shellDir + "/widgets/scripts/monitors_detect.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n").map(s => s.trim()).filter(s => s.length > 0);
                window.updateMonitorsFromList(lines);
            }
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (window.visible) {
                window.loadMonitors();
            }
        }
    }

    MediaPlayer {
        id: globalPreviewPlayer
        audioOutput: AudioOutput { muted: true }
        loops: MediaPlayer.Infinite
    }

    function resetPreviewPlayer() {
        if (globalPreviewPlayer.playbackState === MediaPlayer.PlayingState) {
            globalPreviewPlayer.stop();
        }
        globalPreviewPlayer.source = "";
        globalPreviewPlayer.videoOutput = null;
    }

    function refreshCurrent() {
        let scName = window.hostScreen ? window.hostScreen.name : "";
        let activeWallpaper = Wallpaper.getWallpaper(scName);
        window.targetWallName = window.widgetArg || activeWallpaper;
        window.initialFocusSet = false;
        window.updateDisplay(true);
    }

    function getCleanBaseName(name) {
        if (!name) return "";
        let clean = String(name);
        let slash = clean.lastIndexOf("/");
        if (slash !== -1) clean = clean.substring(slash + 1);
        if (clean.startsWith("000_")) clean = clean.substring(4);
        clean = clean.replace(/\.(jpg|jpeg|png|webp|gif|bmp|mp4|mkv|mov|webm)$/i, "");
        return clean;
    }

    function getCleanName(name) {
        if (!name) return "";
        let clean = String(name);
        let slash = clean.lastIndexOf("/");
        if (slash !== -1) clean = clean.substring(slash + 1);
        return clean.startsWith("000_") ? clean.substring(4) : clean;
    }

    function getOriginalFileName(safeFileName) {
        if (!safeFileName) return "";
        let s = String(safeFileName);
        let slash = s.lastIndexOf("/");
        if (slash !== -1) s = s.substring(slash + 1);
        if (window.srcNameLookup[s]) return window.srcNameLookup[s];
        let clean = window.getCleanName(s);
        if (window.srcNameLookup[clean]) return window.srcNameLookup[clean];
        let base = window.getCleanBaseName(s);
        if (window.srcNameLookup[base]) return window.srcNameLookup[base];
        return clean;
    }

    function isVideoTarget(name) {
        if (!name) return false;
        let s = String(name).toLowerCase();
        let slash = s.lastIndexOf("/");
        if (slash !== -1) s = s.substring(slash + 1);
        if (s.startsWith("000_")) return true;
        if (s.endsWith(".mp4") || s.endsWith(".mkv") || s.endsWith(".mov") || s.endsWith(".webm")) return true;
        let orig = window.getOriginalFileName(name).toLowerCase();
        if (orig.endsWith(".mp4") || orig.endsWith(".mkv") || orig.endsWith(".mov") || orig.endsWith(".webm")) return true;
        let base = window.getCleanBaseName(name);
        let match = window.thumbLookup[base] || window.thumbLookup[s];
        if (match && match.isVideo) return true;
        return false;
    }

    function loadMonitors() {
        monitorDetector.running = false;
        monitorDetector.running = true;
    }

    function updateMonitorsFromList(screenNames) {
        let selectionState = {};
        for (let i = 0; i < monitorModel.count; i++) {
            let item = monitorModel.get(i);
            selectionState[item.name] = item.selected;
        }

        monitorModel.clear();

        for (let i = 0; i < screenNames.length; i++) {
            let screenName = screenNames[i];
            if (!screenName) continue;

            let isSelected = selectionState.hasOwnProperty(screenName)
                ? selectionState[screenName]
                : true;

            monitorModel.append({
                "name": screenName,
                "selected": isSelected
            });
        }
    }

    function getMonitorOutputs() {
        if (monitorModel.count <= 1) return "all";

        let selected = [];
        for (let i = 0; i < monitorModel.count; i++) {
            if (monitorModel.get(i).selected) {
                selected.push(monitorModel.get(i).name);
            }
        }

        if (selected.length === 0) return "none";
        if (selected.length === monitorModel.count) return "all";

        return selected.join(",");
    }

    function setWallpaperOnMonitors(targetFile, transition) {
        let outputs = window.getMonitorOutputs();
        if (outputs === "none") return;

        if (outputs === "all") {
            Wallpaper.setWallpaper("all", targetFile, transition);
        } else {
            let monArr = outputs.split(",");
            for (let i = 0; i < monArr.length; i++) {
                Wallpaper.setWallpaper(monArr[i], targetFile, transition);
            }
        }
    }

    function applyWallpaper(safeFileName) {
        if (!safeFileName || window.isApplying) return;

        let outputs = window.getMonitorOutputs();
        if (outputs === "none") return;

        window.isApplying = true;
        applyUnlockTimer.restart();

        window.targetWallName = safeFileName;
        let realFileName = window.getOriginalFileName(safeFileName);

        let lookup = window.thumbLookup[safeFileName] || window.thumbLookup[window.getCleanBaseName(safeFileName)] || {};
        let finalPath = lookup.filePath || (window.srcDir + "/" + realFileName);
        window.setWallpaperOnMonitors(finalPath, "fade");
    }

    function refreshForDisplay() {
        window.initialFocusSet = false;
        window.refreshCurrent();

        if (displayModel.count === 0) {
            window.syncFromSrcModel();
        }
    }

    onVisibleChanged: {
        if (!visible) {
            window.initialFocusSet = false;
            window.allowAddAnimation = false;
            window.isApplying = false;
            window.isMonitorSelectorOpen = false;
            window.resetPreviewPlayer();
        } else {
            window.loadMonitors();
            window.refreshForDisplay();
            focusTimer.restart();
        }
    }

    onWidgetArgChanged: {
        if (widgetArg !== "") {
            targetWallName = widgetArg;
            initialFocusSet = false;
            window.updateDisplay(true);
        }
    }

    Timer {
        id: allowAddAnimationTimer
        interval: 300
        onTriggered: window.allowAddAnimation = true
    }

    readonly property real itemWidth: window.s(400)
    readonly property real itemHeight: window.s(420)
    readonly property real borderWidth: window.s(3)
    readonly property real spacing: window.s(10)
    readonly property real skewFactor: -0.35
    readonly property real selectedCenterOffset: (window.skewFactor * (window.itemHeight)) / 2 

    Timer { id: scrollThrottle; interval: 140 }

    function syncFromSrcModel() {
        if (srcModel.status !== FolderListModel.Ready || srcModel.count === 0) return;

        let localItems = [];
        let videoItems = [];
        let seen = {};
        let newSrcLookup = Object.assign({}, window.srcNameLookup);
        let newThumbLookup = Object.assign({}, window.thumbLookup);

        for (let i = 0; i < srcModel.count; i++) {
            let fn = srcModel.get(i, "fileName");
            let fu = srcModel.get(i, "fileUrl");
            if (!fn) continue;
            let sFn = String(fn);
            if (seen[sFn]) continue;
            seen[sFn] = true;

            let sFu = String(fu);
            let clean = window.getCleanName(sFn);
            let base = window.getCleanBaseName(sFn);
            let isVid = window.isVideoTarget(sFn) || sFn.toLowerCase().match(/\.(mp4|mkv|mov|webm)$/) !== null;

            let cached = newThumbLookup[sFn] || newThumbLookup[clean] || newThumbLookup[base];
            let item = cached ? cached : {
                "fileName": sFn,
                "filePath": decodeURIComponent(sFu.replace("file://", "")),
                "fileUrl": sFu,
                "isVideo": isVid,
                "posterPath": "",
                "posterUrl": "",
                "hex": "#808080",
                "bucket": isVid ? "Video" : "Monochrome"
            };

            newSrcLookup[sFn] = sFn;
            newSrcLookup[clean] = sFn;
            newSrcLookup[base] = sFn;

            newThumbLookup[sFn] = item;
            newThumbLookup[clean] = item;
            newThumbLookup[base] = item;

            if (isVid) videoItems.push(item);
            else localItems.push(item);
        }

        window.srcNameLookup = newSrcLookup;
        window.thumbLookup = newThumbLookup;

        if (localProxyModel.count === 0 && videoProxyModel.count === 0) {
            if (localItems.length > 0) localProxyModel.append(localItems);
            if (videoItems.length > 0) videoProxyModel.append(videoItems);
            window.updateDisplay(true);
        }
    }

    FolderListModel {
        id: srcModel
        folder: "file://" + window.srcDir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp", "*.mp4", "*.mkv", "*.mov", "*.webm", "*.JPG", "*.JPEG", "*.PNG", "*.WEBP", "*.GIF", "*.BMP", "*.MP4", "*.MKV", "*.MOV", "*.WEBM"]
        caseSensitive: true
        showDirs: false
        onCountChanged: {
            window.syncFromSrcModel();
            indexerDebounceTimer.restart();
        }
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                window.syncFromSrcModel();
                indexerDebounceTimer.restart();
            }
        }
    }

    Timer {
        id: indexerDebounceTimer
        interval: 150
        repeat: false
        onTriggered: window.triggerIndexer()
    }

    Process {
        id: indexDiskReader
        running: false
        command: ["cat", Caching.getCacheDir("wallpaper") + "/current_index.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let trimmed = this.text ? this.text.trim() : "";
                if (trimmed.length > 0) {
                    try {
                        let data = JSON.parse(trimmed);
                        if (data && data.srcDir === window.srcDir) {
                            window.loadIndexData(data);
                        }
                    } catch(e) {}
                }
            }
        }
    }

    Process {
        id: indexProcess
        running: false
        command: [
            "python3",
            window.scriptDir + "/indexer.py",
            window.srcDir,
            Caching.getCacheDir("wallpaper"),
            Caching.getRunDir("wallpaper")
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                let trimmed = this.text ? this.text.trim() : "";
                if (trimmed.length > 0) {
                    try {
                        let data = JSON.parse(trimmed);
                        window.loadIndexData(data);
                    } catch(e) {}
                }
            }
        }
    }

    function triggerIndexer() {
        if (indexProcess.running) {
            indexProcess.running = false;
        }
        indexProcess.running = true;
    }

    function itemsEqualToModel(model, newItems) {
        if (model.count !== newItems.length) return false;
        for (let i = 0; i < newItems.length; i++) {
            let e = model.get(i);
            if (e.fileName !== newItems[i].fileName ||
                e.fileUrl !== newItems[i].fileUrl ||
                e.posterUrl !== newItems[i].posterUrl ||
                e.hex !== newItems[i].hex ||
                e.bucket !== newItems[i].bucket ||
                e.isVideo !== newItems[i].isVideo) {
                return false;
            }
        }
        return true;
    }

    function loadIndexData(data) {
        if (!data || !data.items) return;

        let localItems = [];
        let videoItems = [];
        let seen = {};
        let newSrcLookup = {};
        let newThumbLookup = {};

        for (let i = 0; i < data.items.length; i++) {
            let item = data.items[i];
            if (!item || !item.fileName) continue;
            let fname = String(item.fileName);
            if (seen[fname]) continue;
            seen[fname] = true;

            let clean = window.getCleanName(fname);
            let base = window.getCleanBaseName(fname);

            newSrcLookup[fname] = fname;
            newSrcLookup[clean] = fname;
            newSrcLookup[base] = fname;

            newThumbLookup[fname] = item;
            newThumbLookup[clean] = item;
            newThumbLookup[base] = item;

            let isVid = !!item.isVideo || window.isVideoTarget(fname) || fname.toLowerCase().match(/\.(mp4|mkv|mov|webm)$/) !== null;

            if (isVid) {
                item.isVideo = true;
                item.bucket = "Video";
                videoItems.push(item);
            } else {
                item.isVideo = false;
                localItems.push(item);
            }
        }

        window.srcNameLookup = newSrcLookup;
        window.thumbLookup = newThumbLookup;

        const order = { "Red": 1, "Orange": 2, "Yellow": 3, "Green": 4, "Blue": 5, "Purple": 6, "Pink": 7, "Monochrome": 8 };
        localItems.sort((a, b) => {
            let oA = order[a.bucket] || 10;
            let oB = order[b.bucket] || 10;
            if (oA !== oB) return oA - oB;
            return String(a.fileName).localeCompare(String(b.fileName));
        });
        videoItems.sort((a, b) => String(a.fileName).localeCompare(String(b.fileName)));

        let localChanged = !window.itemsEqualToModel(localProxyModel, localItems);
        let videoChanged = !window.itemsEqualToModel(videoProxyModel, videoItems);

        if (!localChanged && !videoChanged) return;

        window.isModelChanging = true;
        let wasAllowing = window.allowAddAnimation;
        window.allowAddAnimation = false;

        if (localChanged) {
            localProxyModel.clear();
            if (localItems.length > 0) localProxyModel.append(localItems);
        }
        if (videoChanged) {
            videoProxyModel.clear();
            if (videoItems.length > 0) videoProxyModel.append(videoItems);
        }

        window.updateDisplay(true);

        if (wasAllowing) allowAddAnimationTimer.restart();
        window.isModelChanging = false;
    }

    function stepToNextValidIndex(direction) {
        if (displayModel.count === 0) return;
        window.initialFocusSet = true;

        if (view.currentIndex < 0) {
            view.currentIndex = direction > 0 ? 0 : displayModel.count - 1;
        } else {
            view.currentIndex = (view.currentIndex + direction + displayModel.count) % displayModel.count;
        }
    }

    function updateDisplay(forceSnap) {
        window.isModelChanging = true;
        window.resetPreviewPlayer();

        let newItems = [];
        let seenNames = {};
        let targetIndex = -1;
        let focusName = window.targetWallName;
        let cleanTarget = window.getCleanBaseName(focusName);
        let fullTarget = window.getCleanName(focusName);

        for (let sourceModel of [localProxyModel, videoProxyModel]) {
            for (let i = 0; i < sourceModel.count; i++) {
                let it = sourceModel.get(i);
                let fname = it && it.fileName;
                if (!fname || seenNames[fname]) continue;
                seenNames[fname] = true;

                newItems.push({
                    "fileName": fname,
                    "filePath": it.filePath || "",
                    "fileUrl": String(it.fileUrl),
                    "posterPath": it.posterPath || "",
                    "posterUrl": String(it.posterUrl || ""),
                    "isVideo": !!it.isVideo,
                    "hex": it.hex || "#808080",
                    "bucket": it.bucket || (it.isVideo ? "Video" : "Monochrome")
                });

                if (cleanTarget !== "" && (fname === focusName || window.getCleanName(fname) === fullTarget || window.getCleanBaseName(fname) === cleanTarget)) {
                    targetIndex = newItems.length - 1;
                }
            }
        }

        let isIdentical = displayModel.count === newItems.length;
        if (isIdentical) {
            for (let i = 0; i < newItems.length; i++) {
                let old = displayModel.get(i);
                let item = newItems[i];
                if (old.fileName !== item.fileName || old.fileUrl !== item.fileUrl ||
                    old.posterUrl !== item.posterUrl || old.bucket !== item.bucket ||
                    old.isVideo !== item.isVideo) {
                    isIdentical = false;
                    break;
                }
            }
        }

        if (!isIdentical) {
            displayModel.clear();
            if (newItems.length > 0) displayModel.append(newItems);
        }

        let indexToFocus = targetIndex !== -1 ? targetIndex :
            (displayModel.count > 0 ? (view.currentIndex >= 0 && view.currentIndex < displayModel.count ? view.currentIndex : 0) : -1);
        if (indexToFocus !== -1) {
            view.currentIndex = indexToFocus;
            if (forceSnap) {
                view.forceLayout();
                view.positionViewAtIndex(indexToFocus, ListView.Center);
            }
            if (targetIndex !== -1 || cleanTarget === "") window.initialFocusSet = true;
            allowAddAnimationTimer.restart();
        }

        window.isModelChanging = false;
    }

    Shortcut { sequence: "Left"; enabled: window.visible && !window.isApplying; onActivated: window.stepToNextValidIndex(-1) }
    Shortcut { sequence: "Right"; enabled: window.visible && !window.isApplying; onActivated: window.stepToNextValidIndex(1) }
    Shortcut {
        sequence: "Return"
        enabled: window.visible && !window.isApplying
        onActivated: {
            if (view.currentIndex >= 0 && view.currentIndex < displayModel.count) {
                let item = displayModel.get(view.currentIndex);
                if (item && item.fileName) window.applyWallpaper(String(item.fileName));
            }
        }
    }
    Shortcut { sequence: "Tab"; enabled: window.visible && !window.isApplying; onActivated: window.stepToNextValidIndex(1) }
    Shortcut { sequence: "Backtab"; enabled: window.visible && !window.isApplying; onActivated: window.stepToNextValidIndex(-1) }

    ListModel { id: localProxyModel }
    ListModel { id: videoProxyModel }
    ListModel { id: displayModel }
    ListView {
        id: view
        anchors.fill: parent
        opacity: window.isReady ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        spacing: 0; orientation: ListView.Horizontal; clip: false
        interactive: !window.isApplying
        cacheBuffer: window.dynamicCacheBuffer
        reuseItems: true

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width / 2) - ((window.itemWidth * 1.5 + window.s(4)) / 2) + window.selectedCenterOffset
        preferredHighlightEnd: (width / 2) + ((window.itemWidth * 1.5 + window.s(4)) / 2) + window.selectedCenterOffset

        highlightMoveDuration: window.isModelChanging ? 0 : 400
        focus: true

        add: Transition {
            enabled: window.allowAddAnimation && !window.isModelChanging
            NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
        }
        addDisplaced: Transition {
            enabled: window.allowAddAnimation && !window.isModelChanging
            NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
        }
        move: Transition {
            enabled: !window.isModelChanging
            NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
        }
        moveDisplaced: Transition {
            enabled: !window.isModelChanging
            NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
        }
        remove: Transition {
            enabled: window.allowAddAnimation && !window.isModelChanging
            NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
        }
        removeDisplaced: Transition {
            enabled: window.allowAddAnimation && !window.isModelChanging
            NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
        }
        displaced: Transition {
            enabled: window.allowAddAnimation && !window.isModelChanging
            NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutCubic }
        }

        header: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2) + window.selectedCenterOffset) }
        footer: Item { width: Math.max(0, (view.width / 2) - ((window.itemWidth * 1.5) / 2) - window.selectedCenterOffset) }
        model: displayModel

        MouseArea {
            anchors.fill: parent; acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                if (window.isApplying || scrollThrottle.running) { wheel.accepted = true; return; }
                let dx = wheel.angleDelta.x; let dy = wheel.angleDelta.y;
                let delta = Math.abs(dx) > Math.abs(dy) ? dx : dy;
                scrollAccum += delta;
                if (Math.abs(scrollAccum) >= scrollThreshold) {
                    window.stepToNextValidIndex(scrollAccum > 0 ? -1 : 1); scrollAccum = 0; scrollThrottle.start();
                }
                wheel.accepted = true;
            }
        }

        delegate: Item {
            id: delegateRoot
            property bool isFailed: false

            function handleFailedImage() {
                if (delegateRoot.isFailed) return;
                delegateRoot.isFailed = true;
                let fn = delegateRoot.safeFileName;
                if (!fn) return;
                for (let i = displayModel.count - 1; i >= 0; i--) {
                    if (displayModel.get(i).fileName === fn) {
                        displayModel.remove(i);
                    }
                }
                if (view.currentIndex >= displayModel.count) {
                    view.currentIndex = Math.max(0, displayModel.count - 1);
                }
                for (let i = localProxyModel.count - 1; i >= 0; i--) {
                    if (localProxyModel.get(i).fileName === fn) {
                        localProxyModel.remove(i);
                    }
                }
                for (let i = videoProxyModel.count - 1; i >= 0; i--) {
                    if (videoProxyModel.get(i).fileName === fn) {
                        videoProxyModel.remove(i);
                    }
                }
            }

            ListView.onPooled: {
                imageRetryTimer.stop();
                if (delegateRoot.isPlayingVideo || globalPreviewPlayer.videoOutput === previewOutput) {
                    window.resetPreviewPlayer();
                    delegateRoot.isPlayingVideo = false;
                }
            }

            ListView.onReused: {
                delegateRoot.isPlayingVideo = false;
                delegateRoot.isFailed = false;
                paperImage.retryCount = 0;
            }

            readonly property string safeFileName: fileName !== undefined ? String(fileName) : ""
            readonly property string itemFileUrl: fileUrl !== undefined ? String(fileUrl) : ""
            readonly property string itemPosterUrl: posterUrl !== undefined ? String(posterUrl) : ""
            readonly property bool isVideo: (model.isVideo !== undefined && model.isVideo !== null) ? !!model.isVideo : (safeFileName.toLowerCase().match(/\.(mp4|mkv|mov|webm)$/) !== null || safeFileName.startsWith("000_"))

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool isVisuallyEnlarged: isCurrent

            readonly property int dist: Math.abs(index - view.currentIndex)
            readonly property real sideScale: Math.max(0.58, Math.pow(0.88, Math.max(0, dist - 1)))
            readonly property real sideOpacity: 1.0

            readonly property real dynamicRadius: {
                let baseR = ThemeBackend.borderRadius;
                if (baseR <= 0) return 0;
                let k = Math.min(1.0, Math.pow(baseR / 48, 2));
                let decay = Math.max(0.45, Math.pow(0.85, dist));
                return baseR * (1.0 - k * (1.0 - decay));
            }

            readonly property real cellWidth: isVisuallyEnlarged ? (window.itemWidth * 1.5 + window.s(4)) : (window.itemWidth * 0.48 * sideScale)
            readonly property real targetWidth: isVisuallyEnlarged ? (window.itemWidth * 1.5) : (window.itemWidth * 0.48 * sideScale)
            readonly property real targetHeight: isVisuallyEnlarged ? (window.itemHeight + window.s(30)) : (window.itemHeight * Math.max(0.62, Math.pow(0.90, Math.max(0, dist - 1))))
            property bool isPlayingVideo: false

            function toggleVideoPlay() {
                if (isPlayingVideo) {
                    window.resetPreviewPlayer();
                    isPlayingVideo = false;
                } else {
                    window.resetPreviewPlayer();
                    globalPreviewPlayer.videoOutput = previewOutput;
                    globalPreviewPlayer.source = delegateRoot.itemFileUrl !== "" ? delegateRoot.itemFileUrl : ("file://" + window.srcDir + "/" + window.getOriginalFileName(delegateRoot.safeFileName));
                    isPlayingVideo = true;
                    globalPreviewPlayer.play();
                }
            }

            onIsVisuallyEnlargedChanged: {
                if (!isVisuallyEnlarged) {
                    if (globalPreviewPlayer.videoOutput === previewOutput) {
                        window.resetPreviewPlayer();
                    }
                    isPlayingVideo = false;
                }
            }

            width: isFailed ? 0 : cellWidth
            visible: (opacity > 0.01) && !isFailed
            opacity: isFailed ? 0.0 : sideOpacity
            height: isFailed ? 0 : targetHeight
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            anchors.verticalCenterOffset: window.s(25)
            z: isVisuallyEnlarged ? 100 : Math.max(1, 50 - dist)

            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on width { enabled: window.initialFocusSet && !window.isModelChanging; NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: window.initialFocusSet && !window.isModelChanging; NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

            Item {
                id: skewedWrapper
                anchors.centerIn: parent

                readonly property real targetCenterIndex: view.currentIndex
                anchors.horizontalCenterOffset: -(window.skewFactor * height) / 2

                property real targetPadding: 0
                Behavior on targetPadding { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                width: parent.width - targetPadding
                height: parent ? parent.height : 0
                transform: Matrix4x4 { property real s: window.skewFactor; matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }

                MouseArea {
                    anchors.fill: parent; enabled: !window.isApplying && !delegateRoot.isFailed
                    onClicked: { window.initialFocusSet = true; view.currentIndex = index; window.applyWallpaper(delegateRoot.safeFileName); }
                }

                Item {
                    id: paperContentFrame
                    anchors.fill: parent
                    anchors.margins: window.borderWidth

                    Rectangle {
                        anchors.fill: parent
                        radius: delegateRoot.dynamicRadius
                        color: delegateRoot.isFailed ? "transparent" : ThemeBackend.surface0
                    }

                    Rectangle {
                        id: paperMask
                        anchors.fill: parent
                        radius: delegateRoot.dynamicRadius
                        visible: false
                        layer.enabled: true
                    }

                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: paperMask
                        }

                        Image {
                            id: paperImage
                            anchors.centerIn: parent ? parent : undefined
                            anchors.horizontalCenterOffset: window.s(-50)
                            width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50)
                            height: window.itemHeight + window.s(30)
                            fillMode: Image.PreserveAspectCrop
                            source: delegateRoot.isVideo ? (delegateRoot.itemPosterUrl !== "" ? delegateRoot.itemPosterUrl : "") : delegateRoot.itemFileUrl
                            asynchronous: true
                            cache: true
                            opacity: (status === Image.Ready && source.toString() !== "") ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            sourceSize.width: Math.round((window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * 0.35) + window.s(50))
                            sourceSize.height: Math.round(window.itemHeight + window.s(30))

                            property int retryCount: 0
                            onStatusChanged: {
                                if (status === Image.Error) {
                                    if (retryCount < 2) {
                                        retryCount++;
                                        imageRetryTimer.restart();
                                    } else {
                                        delegateRoot.handleFailedImage();
                                    }
                                } else if (status === Image.Ready) {
                                    retryCount = 0;
                                }
                            }
                            Timer {
                                id: imageRetryTimer
                                interval: 300
                                onTriggered: {
                                    if (paperImage.status === Image.Error) {
                                        let currentSrc = paperImage.source;
                                        paperImage.source = "";
                                        paperImage.source = currentSrc;
                                    }
                                }
                            }
                            transform: Matrix4x4 { property real s: -window.skewFactor; matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                        }

                        VideoOutput {
                            id: previewOutput
                            anchors.centerIn: parent ? parent : undefined
                            anchors.horizontalCenterOffset: window.s(-50)
                            width: (window.itemWidth * 1.5) + ((window.itemHeight + window.s(30)) * Math.abs(window.skewFactor)) + window.s(50)
                            height: window.itemHeight + window.s(30)
                            fillMode: VideoOutput.PreserveAspectCrop
                            visible: delegateRoot.isPlayingVideo && globalPreviewPlayer.playbackState === MediaPlayer.PlayingState
                            transform: Matrix4x4 { property real s: -window.skewFactor; matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                        }

                        IconButton {
                            id: videoActionButton
                            visible: delegateRoot.isVideo
                            anchors.centerIn: parent ? parent : undefined
                            size: window.s(50)
                            cornerRadius: window.s(16)
                            iconFontSize: window.s(20)
                            buttonIcon: delegateRoot.isPlayingVideo && globalPreviewPlayer.playbackState === MediaPlayer.PlayingState ? "󰏤" : "󰐊"
                            accentColor: Qt.rgba(ThemeBackend.surface0.r, ThemeBackend.surface0.g, ThemeBackend.surface0.b, 0.65)
                            textColor: ThemeBackend.text
                            opacity: (delegateRoot.isPlayingVideo && globalPreviewPlayer.playbackState === MediaPlayer.PlayingState) ? (isHoveredOrHighlighted ? 0.9 : 0.18) : 0.88
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            enabled: !window.isApplying
                            onClicked: delegateRoot.toggleVideoPlay()
                            transform: Matrix4x4 { property real s: -window.skewFactor; matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: delegateRoot.dynamicRadius
                        color: "transparent"
                        border.width: 0
                        border.color: "transparent"
                    }
                }
            }
        }
    }

    Rectangle {
        id: monitorBar; anchors.top: parent.top
        visible: monitorModel.count > 1
        anchors.topMargin: window.isReady ? window.s(65) : window.s(-75)
        opacity: window.isReady ? 1.0 : 0.0
        Behavior on anchors.topMargin { NumberAnimation { duration: 650; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
        anchors.horizontalCenter: parent.horizontalCenter; z: 200; height: window.s(48); width: monitorRow.width + window.s(20); radius: ThemeBackend.borderRadius
        color: Qt.rgba(ThemeBackend.base.r, ThemeBackend.base.g, ThemeBackend.base.b, 0.90); border.color: ThemeBackend.surface0; border.width: 1

        Row {
            id: monitorRow; anchors.centerIn: parent ? parent : undefined; spacing: window.s(8)

            Rectangle {
                id: monitorDrawer; visible: monitorModel.count > 1; height: window.s(34)
                property real expandedWidth: window.s(34) + monitorListRow.implicitWidth + window.s(6)
                width: visible ? (window.isMonitorSelectorOpen ? expandedWidth : window.s(34)) : 0
                radius: ThemeBackend.borderRadius; clip: true; anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                color: window.isMonitorSelectorOpen ? ThemeBackend.surface2 : ThemeBackend.surface0; border.color: window.isMonitorSelectorOpen ? ThemeBackend.text : ThemeBackend.surface1; border.width: window.isMonitorSelectorOpen ? window.s(1.5) : 1
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                CanvasIconButton {
                    id: monitorToggleBtn
                    size: window.s(34)
                    cornerRadius: window.s(10)
                    iconSize: window.s(14)
                    accentColor: "transparent"
                    textColor: window.isMonitorSelectorOpen ? ThemeBackend.text : ThemeBackend.subtext0
                    anchors.left: parent ? parent.left : undefined
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    paintCanvas: function(ctx, canvas) {
                        var s = window.s;
                        ctx.lineWidth = s(2);
                        ctx.strokeStyle = monitorToggleBtn.textColor;
                        ctx.lineJoin = "round";
                        ctx.lineCap = "round";
                        ctx.beginPath(); ctx.rect(s(1), s(2), s(12), s(8)); ctx.stroke();
                        ctx.beginPath(); ctx.moveTo(s(7), s(10)); ctx.lineTo(s(7), s(13)); ctx.moveTo(s(4), s(13)); ctx.lineTo(s(10), s(13)); ctx.stroke();
                    }
                    onClicked: {
                        if (!window.isApplying) {
                            window.isMonitorSelectorOpen = !window.isMonitorSelectorOpen;
                        }
                    }
                }

                Row {
                    id: monitorListRow; anchors.left: monitorToggleBtn.right; anchors.verticalCenter: parent ? parent.verticalCenter : undefined; spacing: window.s(6)
                    opacity: window.isMonitorSelectorOpen ? 1.0 : 0.0; Behavior on opacity { NumberAnimation { duration: 200 } }
                    Repeater {
                        model: monitorModel
                        delegate: ClickButton {
                            height: window.s(26)
                            cornerRadius: window.s(6)
                            horizontalPadding: window.s(8)
                            buttonText: model.name
                            textFontSize: window.s(10)
                            accentColor: model.selected ? ThemeBackend.text : ThemeBackend.surface1
                            textColor: model.selected ? ThemeBackend.base : ThemeBackend.text
                            enabled: window.isMonitorSelectorOpen && !window.isApplying
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                            onClicked: {
                                if (model.selected) {
                                    let activeCount = 0;
                                    for (let i = 0; i < monitorModel.count; i++) { if (monitorModel.get(i).selected) activeCount++; }
                                    if (activeCount > 1) monitorModel.setProperty(index, "selected", false);
                                } else {
                                    monitorModel.setProperty(index, "selected", true);
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    Component.onCompleted: {
        indexDiskReader.running = true;
        window.syncFromSrcModel();
        window.triggerIndexer();

        if (visible) {
            window.loadMonitors();
            window.refreshForDisplay();
            focusTimer.restart();
        }
    }
}
