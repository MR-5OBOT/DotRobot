pragma Singleton
import QtQuick
import Quickshell

/**
 * Surface-lifecycle registry. Every pill instance registers itself here so the
 * shell can command all pills at once (the unloadAll IPC) without threading
 * pointers through the per-monitor screen Variants. Pills live for the whole
 * daemon lifetime, so the list is append-only and bounded by the monitor
 * count; de-registration is unnecessary.
 */
Singleton {
    id: root

    property var pills: []

    /**
     * Back-navigation state, shared so every PillSurface can render one chevron
     * without the pill threading a signal through all nineteen Loaders. `back`
     * is the surface to return to, set only when one surface was opened from
     * inside another; a surface opened by keybind or IPC clears it, so the
     * chevron appears exactly when there is somewhere to go back to.
     */
    property string back: ""
    property var host: null

    /**
     * Width the pill adds, and the lane PillSurface leaves, while a back target
     * exists. The panel grows by exactly what the breadcrumb occupies, so no
     * surface loses any of its own layout to it.
     */
    /**
     * Band above the surface that the breadcrumb sits in, in unscaled units, as
     * measured by the pill. It was a left lane, but reserving a full-height
     * column for one line of text left a tall empty gutter beside every widget;
     * a top band costs ~20px of height and no width at all.
     */
    property int pad: 0

    function goBack() {
        if (root.host)
            root.host.navigateBack();
    }

    function register(p) {
        if (root.pills.indexOf(p) >= 0)
            return;
        root.pills = root.pills.concat([p]);
    }

    /**
     * Drop every closed surface on every pill immediately, leaving each open
     * surface (never in a pill's closedAt set) untouched. Callers expecting a
     * result get nothing back; the unloads happen synchronously.
     */
    function unloadClosed() {
        var list = root.pills;
        for (var i = 0; i < list.length; i++)
            if (list[i] && list[i].unloadClosedSurfaces)
                list[i].unloadClosedSurfaces();
    }
}