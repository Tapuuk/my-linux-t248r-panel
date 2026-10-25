import QtQuick
import QtQuick.Shapes

// The T248R from the front: round rim with the red top stripe, three spokes and the hub with its screen.
Item {
    id: root

    property real angle: 0
    property string screenText: ""
    property bool active: true

    readonly property real s: Math.min(width, height)
    readonly property real c: s / 2
    readonly property real rimR: s * 0.43
    readonly property real rimT: s * 0.085

    readonly property color rimColour: active ? Colours.m3onSurfaceVariant : Qt.alpha(Colours.m3onSurfaceVariant, 0.4)
    readonly property color spokeColour: Colours.mix(Colours.m3onSurfaceVariant, Colours.m3surfaceContainerHighest, active ? 0.55 : 0.8)
    readonly property color hubColour: active ? Colours.m3surfaceContainerHighest : Colours.m3surfaceContainerHigh
    readonly property color stripeColour: active ? Colours.m3error : Qt.alpha(Colours.m3error, 0.4)

    implicitWidth: 260
    implicitHeight: 260

    Item {
        id: body

        width: root.s
        height: root.s
        anchors.centerIn: parent
        rotation: root.angle

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // Spoke plate across the middle and the bottom spoke, like the T248R's wide centre section.
            ShapePath {
                fillColor: root.spokeColour
                strokeColor: "transparent"
                joinStyle: ShapePath.RoundJoin

                Behavior on fillColor {
                    CAnim {}
                }

                PathPolyline {
                    path: {
                        const c = root.c, s = root.s, R = root.rimR - root.rimT * 0.2;
                        const top = c - s * 0.075, bot = c + s * 0.125, w = s * 0.075;
                        return [Qt.point(c - R, top + s * 0.04), Qt.point(c - s * 0.2, top), Qt.point(c + s * 0.2, top),
                                Qt.point(c + R, top + s * 0.04), Qt.point(c + R, bot - s * 0.01), Qt.point(c + s * 0.17, bot),
                                Qt.point(c + w, c + s * 0.2), Qt.point(c + w * 0.8, c + R), Qt.point(c - w * 0.8, c + R),
                                Qt.point(c - w, c + s * 0.2), Qt.point(c - s * 0.17, bot), Qt.point(c - R, bot - s * 0.01),
                                Qt.point(c - R, top + s * 0.04)];
                    }
                }
            }

            // Rim
            ShapePath {
                fillColor: "transparent"
                strokeColor: root.rimColour
                strokeWidth: root.rimT
                capStyle: ShapePath.FlatCap

                Behavior on strokeColor {
                    CAnim {}
                }

                PathAngleArc {
                    centerX: root.c
                    centerY: root.c
                    radiusX: root.rimR
                    radiusY: root.rimR
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            // Red centre marker at the top of the rim
            ShapePath {
                fillColor: "transparent"
                strokeColor: root.stripeColour
                strokeWidth: root.rimT + 1
                capStyle: ShapePath.FlatCap

                Behavior on strokeColor {
                    CAnim {}
                }

                PathAngleArc {
                    centerX: root.c
                    centerY: root.c
                    radiusX: root.rimR
                    radiusY: root.rimR
                    startAngle: -90 - 5
                    sweepAngle: 10
                }
            }
        }

        // Hub
        StyledRect {
            id: hub

            x: root.c - width / 2
            y: root.c - height / 2 + root.s * 0.03
            width: root.s * 0.3
            height: root.s * 0.27
            radius: root.s * 0.07
            color: root.hubColour

            StyledRect {
                id: screen

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.17
                width: parent.width * 0.42
                height: parent.height * 0.3
                radius: height * 0.3
                color: !root.active ? Colours.m3surfaceContainer : Colours.dark ? Colours.m3surfaceContainerLowest : Colours.m3inverseSurface

                StyledText {
                    anchors.centerIn: parent
                    text: root.screenText
                    color: Colours.dark ? Colours.m3primary : Colours.m3inversePrimary
                    font.pixelSize: Math.max(8, parent.height * 0.6)
                    font.weight: Font.Medium
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: screen.bottom
                anchors.topMargin: parent.height * 0.13
                spacing: parent.width * 0.07

                Repeater {
                    model: 3

                    StyledRect {
                        required property int index

                        width: hub.width * (index === 1 ? 0.14 : 0.09)
                        height: width
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Colours.m3outlineVariant
                    }
                }
            }
        }
    }
}
