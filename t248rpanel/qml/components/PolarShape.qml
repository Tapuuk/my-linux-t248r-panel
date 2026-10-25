import QtQuick
import QtQuick.Shapes

// A rounded "cookie" polygon: r(θ) = 1 + a·cos(nθ), scaled so the outermost point touches the edge.
// Morphs between two [lobes, amplitude] pairs with `progress`.
Shape {
    id: root

    property var from: [9, 0.08]
    property var to: from
    property real progress: 1
    property color color: Colours.m3primaryContainer
    property color strokeColor: "transparent"
    property real strokeWidth: 0
    property int samples: 120

    readonly property var points: {
        const cx = width / 2, cy = height / 2;
        const R = Math.min(width, height) / 2 - strokeWidth / 2;
        const f = from, t = to, p = progress;
        const pts = [];
        for (let i = 0; i <= samples; i++) {
            const th = i / samples * Math.PI * 2;
            const r1 = (1 + f[1] * Math.cos(f[0] * th)) / (1 + f[1]);
            const r2 = (1 + t[1] * Math.cos(t[0] * th)) / (1 + t[1]);
            const r = R * (r1 + (r2 - r1) * p);
            pts.push(Qt.point(cx + r * Math.sin(th), cy - r * Math.cos(th)));
        }
        return pts;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeColor: root.strokeColor
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.RoundJoin

        Behavior on fillColor {
            CAnim {}
        }

        PathPolyline {
            path: root.points
        }
    }
}
