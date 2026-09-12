pragma Singleton
import QtQuick

// DotRobot stub: upstream's Matugen shells out to the matugen binary to rebuild
// the palette and then SIGUSR1s every running kitty. Our ThemeBackend derives
// its palette from the wallpaper itself (ColorQuantizer), so regeneration is a
// no-op here — the wallpaper picker calls generate() on every apply.
// The signals stay because upstream code connects to them.
QtObject {
    signal generationStarted()
    signal generationFinished(bool success)

    function isMatugenTheme() { return false; }
    function generate(imagePath, mode, schemeType) { return false; }
    function generateImage(imagePath) { return false; }
    function generateFromStatic(colorsObj, mode) { return false; }
}
