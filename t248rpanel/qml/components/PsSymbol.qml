import QtQuick
import QtQuick.Shapes

// PlayStation face button symbols drawn as strokes, so they don't depend on font coverage.
Shape {
    id: root

    property string kind: "cross"   // triangle square circle cross
    property color color: Colours.m3onSurface
    property real lineWidth: 2

    implicitWidth: 16
    implicitHeight: 16
    preferredRendererType: Shape.CurveRenderer

    readonly property real w: width
    readonly property real h: height
    readonly property real m: lineWidth

    ShapePath {
        strokeColor: root.color
        strokeWidth: root.lineWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin

        PathPolyline {
            path: {
                const w = root.w, h = root.h, m = root.m;
                switch (root.kind) {
                case "triangle":
                    return [Qt.point(w / 2, m), Qt.point(w - m, h - m * 1.4), Qt.point(m, h - m * 1.4), Qt.point(w / 2, m)];
                case "square":
                    return [Qt.point(m * 1.3, m * 1.3), Qt.point(w - m * 1.3, m * 1.3), Qt.point(w - m * 1.3, h - m * 1.3), Qt.point(m * 1.3, h - m * 1.3), Qt.point(m * 1.3, m * 1.3)];
                case "circle": {
                    const pts = [];
                    for (let i = 0; i <= 40; i++) {
                        const a = i / 40 * Math.PI * 2;
                        pts.push(Qt.point(w / 2 + (w / 2 - m) * Math.cos(a), h / 2 + (h / 2 - m) * Math.sin(a)));
                    }
                    return pts;
                }
                }
                return [Qt.point(m * 1.3, m * 1.3), Qt.point(w - m * 1.3, h - m * 1.3)];
            }
        }
    }

    // Second stroke of the cross
    ShapePath {
        strokeColor: root.kind === "cross" ? root.color : "transparent"
        strokeWidth: root.lineWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        startX: root.w - root.m * 1.3
        startY: root.m * 1.3

        PathLine {
            x: root.m * 1.3
            y: root.h - root.m * 1.3
        }
    }
}
