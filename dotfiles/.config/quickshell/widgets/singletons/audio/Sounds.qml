pragma Singleton
import QtQuick

// DotRobot stub: serpantinum's click sounds live in its assets/, which aren't
// vendored, so every call is a no-op instead of a failing pw-play. Keeps
// upstream's whole signature list — the vendored widgets call playSfx,
// playUntilStopped and stopSfx, and a missing one is a runtime TypeError.
QtObject {
    function play(filePath, volume, duration, overrideSfxBlock) {}
    function playSfx(filename, volume, duration, overrideSfxBlock) {}
    function playUntilStopped(filenameOrPath, volume, loop, overrideSfxBlock) { return 0; }
    function stopSfx(handleId) {}
    function stopAllSfx() {}
}
