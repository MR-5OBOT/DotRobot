import QtQuick
import QtQuick.Shapes

/**
 * Concave shoulders that flare a top-docked panel into the screen edge, so the
 * pill reads as a notch hanging from the bezel rather than a floating capsule.
 * Anchor it to the panel's top edge with the panel's width: each ear of radius
 * `r` hangs just outside the left and right sides, filled with `color`. Each ear
 * reaches `overlap` px into the panel so the two anti-aliased edges never leave
 * a hairline seam between them.
 */
Item {
    id: root

    property real r: 14
    property color color: "black"
    property real overlap: 1

    height: r

    Shape {
        x: -root.r
        width: root.r + root.overlap
        height: root.r
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.color
            startX: 0
            startY: 0
            PathLine { x: root.r + root.overlap; y: 0 }
            PathLine { x: root.r + root.overlap; y: root.r }
            PathLine { x: root.r; y: root.r }
            PathArc { x: 0; y: 0; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
        }
    }

    Shape {
        x: root.width - root.overlap
        width: root.r + root.overlap
        height: root.r
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.color
            startX: root.r + root.overlap
            startY: 0
            PathLine { x: 0; y: 0 }
            PathLine { x: 0; y: root.r }
            PathLine { x: root.overlap; y: root.r }
            PathArc { x: root.r + root.overlap; y: 0; radiusX: root.r; radiusY: root.r; direction: PathArc.Clockwise }
        }
    }
}
