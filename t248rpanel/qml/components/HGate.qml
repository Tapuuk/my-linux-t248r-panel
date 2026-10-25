import QtQuick
import QtQuick.Shapes

// TH8A/TH8S 7+R gate. Columns: 1/2, 3/4, 5/6, 7/R. The knob springs to the current gear.
Item {
    id: root

    property int gear: 0          // 0 neutral, 1..7, -1 reverse
    property bool active: true

    readonly property real colGap: Math.min(width * 0.8 / 3, (height - 40) * 0.55)
    readonly property real gateLeft: (width - colGap * 3) / 2
    readonly property real gateTop: Math.max(36, height * 0.14) + 6
    readonly property real gateBottom: height - gateTop
    readonly property real mid: height / 2
    readonly property real track: Math.max(14, colGap * 0.16)
    readonly property real knobSize: Math.max(40, track * 2.8)

    function gearPos(g: int): point {
        if (g === 0)
            return Qt.point(width / 2, mid);
        const col = g === -1 ? 3 : Math.floor((g - 1) / 2);
        const isTop = g !== -1 && (g % 2 === 1);
        return Qt.point(gateLeft + col * colGap, isTop ? gateTop : gateBottom);
    }

    readonly property point knobPos: gearPos(gear)

    implicitWidth: 420
    implicitHeight: 300

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.active ? Colours.mix(Colours.m3surfaceContainerHighest, Colours.m3outlineVariant, 0.45) : Colours.m3surfaceContainerHigh
            strokeWidth: root.track
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            Behavior on strokeColor {
                CAnim {}
            }

            startX: root.gateLeft
            startY: root.mid
            PathLine { x: root.gateLeft + root.colGap * 3; y: root.mid }
            PathMove { x: root.gateLeft; y: root.gateTop }
            PathLine { x: root.gateLeft; y: root.gateBottom }
            PathMove { x: root.gateLeft + root.colGap; y: root.gateTop }
            PathLine { x: root.gateLeft + root.colGap; y: root.gateBottom }
            PathMove { x: root.gateLeft + root.colGap * 2; y: root.gateTop }
            PathLine { x: root.gateLeft + root.colGap * 2; y: root.gateBottom }
            PathMove { x: root.gateLeft + root.colGap * 3; y: root.gateTop }
            PathLine { x: root.gateLeft + root.colGap * 3; y: root.gateBottom }
        }

        // The path the knob took, from the neutral bar to the gear
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.gear !== 0 && root.active ? Qt.alpha(Colours.m3primary, 0.35) : "transparent"
            strokeWidth: root.track
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            Behavior on strokeColor {
                CAnim {}
            }

            startX: root.width / 2
            startY: root.mid
            PathLine { x: knob.cx; y: root.mid }
            PathLine { x: knob.cx; y: knob.cy }
        }
    }

    Repeater {
        model: [1, 2, 3, 4, 5, 6, 7, -1]

        Item {
            id: label

            required property int modelData
            readonly property point p: root.gearPos(modelData)
            readonly property bool isTop: p.y < root.mid
            readonly property bool current: root.gear === modelData

            x: p.x - width / 2
            y: isTop ? p.y - height - root.knobSize / 2 + 2 : p.y + root.knobSize / 2 - 2
            width: 32
            height: 28

            StyledText {
                anchors.centerIn: parent
                text: label.modelData === -1 ? "R" : label.modelData
                color: label.current ? Colours.m3primary : Colours.m3onSurfaceVariant
                font.pixelSize: Appearance.font.size.titleMedium
                font.weight: label.current ? Font.DemiBold : Font.Medium
                scale: label.current ? 1.2 : 1

                Behavior on scale {
                    Anim {
                        type: Anim.FastSpatial
                    }
                }
            }
        }
    }

    Item {
        id: knob

        property real cx: root.knobPos.x
        property real cy: root.knobPos.y
        readonly property real d: root.knobSize

        // Moving along the gate: first sideways along neutral, then into the slot. Approximated with
        // a fast spring on y and a slightly slower one on x.
        Behavior on cx {
            Anim {
                type: Anim.FastSpatial
            }
        }
        Behavior on cy {
            Anim {
                type: Anim.DefaultSpatial
            }
        }

        x: cx - d / 2
        y: cy - d / 2
        width: d
        height: d

        StyledRect {
            anchors.fill: parent
            anchors.margins: -6
            radius: width / 2
            color: Qt.alpha(Colours.m3primary, 0.18)
            visible: root.active
        }

        PolarShape {
            anchors.fill: parent
            from: [9, 0.07]
            color: root.active ? Colours.m3primary : Colours.m3outline
            rotation: knob.cx * 0.6
        }

        StyledText {
            anchors.centerIn: parent
            text: root.gear === 0 ? "N" : root.gear === -1 ? "R" : root.gear
            color: root.active ? Colours.m3onPrimary : Colours.m3surface
            font.pixelSize: knob.d * 0.42
            font.weight: Font.DemiBold
        }
    }
}
