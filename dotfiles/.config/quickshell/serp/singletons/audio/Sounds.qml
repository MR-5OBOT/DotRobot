pragma Singleton
import QtQuick

// DotRobot stub: serpantinum's click sounds live in its assets/, which aren't
// vendored, so every call is a no-op instead of a failing pw-play.
QtObject {
    function play() {}
    function playSfx() {}
}
