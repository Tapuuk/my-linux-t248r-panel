import QtQuick
import QtQuick.Shapes

// Hover tint plus a radial ripple from the press point, clipped to the parent's corner radii.
MouseArea {
    id: root

    property bool disabled
    property color color: Colours.m3onSurface
    property real hoverOpacity: 0.08
    property bool manualHover

    property real radius: parent && parent.radius !== undefined ? parent.radius : 0
    property real topLeftRadius: parent && parent.topLeftRadius !== undefined ? parent.topLeftRadius : radius
    property real topRightRadius: parent && parent.topRightRadius !== undefined ? parent.topRightRadius : radius
    property real bottomLeftRadius: parent && parent.bottomLeftRadius !== undefined ? parent.bottomLeftRadius : radius
    property real bottomRightRadius: parent && parent.bottomRightRadius !== undefined ? parent.bottomRightRadius : radius

    property real pressX: width / 2
    property real pressY: height / 2
    property real circleRadius
    property real endRadiusAtPress: 1
    readonly property real endRadius: {
        const dx = Math.max(pressX, width - pressX);
        const dy = Math.max(pressY, height - pressY);
        return Math.max(1, Math.sqrt(dx * dx + dy * dy) * 1.3);
    }

    function clampR(r: real): real {
        return Math.max(0, Math.min(r, width / 2, height / 2));
    }

    function clamp01(v: real): real {
        return Math.max(0.01, Math.min(0.99, v));
    }

    function ripple(x: real, y: real): void {
        pressX = x;
        pressY = y;
        fadeAnim.stop();
        circleRadius = 0;
        circle.opacity = 0.12;
        endRadiusAtPress = endRadius;
        rippleAnim.restart();
    }

    anchors.fill: parent
    enabled: !disabled
    hoverEnabled: true
    cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

    onPressed: e => ripple(e.x, e.y)
    onPressedChanged: {
        if (!pressed && !rippleAnim.running && circle.opacity > 0)
            fadeAnim.start();
    }
    onCircleRadiusChanged: {
        if (!pressed && circleRadius >= endRadiusAtPress * 0.99 && !fadeAnim.running)
            fadeAnim.start();
    }

    NumberAnimation {
        id: rippleAnim

        target: root
        property: "circleRadius"
        to: root.endRadius
        alwaysRunToEnd: true
        duration: Appearance.anim.durations.expressiveSlowEffects * 2
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.standard
    }

    Anim {
        id: fadeAnim

        target: circle
        property: "opacity"
        to: 0
        type: Anim.SlowEffects
    }

    Rectangle {
        anchors.fill: parent
        color: root.color
        opacity: root.disabled ? 0 : (root.containsMouse || root.manualHover) ? root.hoverOpacity : 0
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Shape {
        id: circle

        anchors.fill: parent
        opacity: 0
        visible: opacity > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.pressX
                centerY: root.pressY
                centerRadius: Math.max(0.01, root.circleRadius)
                focalX: centerX
                focalY: centerY

                GradientStop {
                    position: 0
                    color: Qt.alpha(root.color, 1)
                }
                GradientStop {
                    position: root.clamp01(1 - 0.2 * root.endRadius / Math.max(1, root.circleRadius))
                    color: Qt.alpha(root.color, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.alpha(root.color, Math.max(0, Math.min(1, (root.circleRadius / root.endRadius - 0.9) / 0.1)))
                }
            }

            startX: root.clampR(root.topLeftRadius)
            startY: 0

            PathLine {
                x: root.width - root.clampR(root.topRightRadius)
                y: 0
            }
            PathArc {
                relativeX: root.clampR(root.topRightRadius)
                relativeY: root.clampR(root.topRightRadius)
                radiusX: root.clampR(root.topRightRadius)
                radiusY: root.clampR(root.topRightRadius)
            }
            PathLine {
                x: root.width
                y: root.height - root.clampR(root.bottomRightRadius)
            }
            PathArc {
                relativeX: -root.clampR(root.bottomRightRadius)
                relativeY: root.clampR(root.bottomRightRadius)
                radiusX: root.clampR(root.bottomRightRadius)
                radiusY: root.clampR(root.bottomRightRadius)
            }
            PathLine {
                x: root.clampR(root.bottomLeftRadius)
                y: root.height
            }
            PathArc {
                relativeX: -root.clampR(root.bottomLeftRadius)
                relativeY: -root.clampR(root.bottomLeftRadius)
                radiusX: root.clampR(root.bottomLeftRadius)
                radiusY: root.clampR(root.bottomLeftRadius)
            }
            PathLine {
                x: 0
                y: root.clampR(root.topLeftRadius)
            }
            PathArc {
                x: root.clampR(root.topLeftRadius)
                y: 0
                radiusX: root.clampR(root.topLeftRadius)
                radiusY: root.clampR(root.topLeftRadius)
            }
        }
    }
}
