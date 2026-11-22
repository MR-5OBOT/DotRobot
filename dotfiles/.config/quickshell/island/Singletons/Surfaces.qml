pragma Singleton
import QtQuick
import Quickshell

/** Back-navigation state shared by every pill and its surfaces. */
Singleton {
    id: root

    /**
     * Back-navigation state, shared so every PillSurface can render one chevron
     * without the pill threading a signal through every Loader. `back`
     * is the surface to return to, set only when one surface was opened from
     * inside another; a surface opened by keybind or IPC clears it, so the
     * chevron appears exactly when there is somewhere to go back to.
     */
    property string back: ""
    property var host: null

    /**
     * Band above the surface that the breadcrumb sits in, in unscaled units:
     * the breadcrumb's 16 (Pill.qml backBtn) plus its 9 top margin. It was a
     * left lane, but reserving a full-height column for one line of text left a
     * tall empty gutter beside every widget; a top band costs ~20px of height
     * and no width at all.
     *
     * Derived here, not written by the pills: every monitor's pill used to bind
     * it, and the last writer won when focus moved between screens. One surface
     * is open at a time and `back` is only set while it is, so this is exact.
     */
    readonly property int pad: back.length > 0 ? 16 + 9 : 0

    function goBack() {
        if (root.host)
            root.host.navigateBack();
    }
}