import QtQuick
import QtQuick.Shapes

// The T248R's face laid out like the real wheel. Coordinates are on a 720 x 340 canvas that scales to fit.
Item {
    id: root

    property var pressed: []
    property int hatX: 0
    property int hatY: 0
    property int encoderSlot: 0
    property bool active: true

    readonly property real k: Math.min(width / 720, height / 340)

    function isDown(n: int): bool {
        return root.pressed.indexOf(n) !== -1;
    }
    function anyDown(list: var): bool {
        for (const n of list)
            if (root.pressed.indexOf(n) !== -1)
                return true;
        return false;
    }

    implicitWidth: 720
    implicitHeight: 340

    Item {
        id: canvas

        width: 720
        height: 340
        anchors.centerIn: parent
        scale: root.k
        opacity: root.active ? 1 : 0.5

        // Faint outline of the rim and hub behind the buttons
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: Colours.m3outlineVariant
                strokeWidth: 2
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 4]

                PathAngleArc {
                    centerX: 360
                    centerY: 200
                    radiusX: 300
                    radiusY: 176
                    startAngle: 180 + 18
                    sweepAngle: 144
                }
            }
        }

        StyledRect {
            x: 250
            y: 34
            width: 220
            height: 270
            radius: 56
            color: Qt.alpha(Colours.m3surfaceContainerHighest, 0.45)
        }

        // Paddles
        MapButton {
            x: 6; y: 78; width: 52; height: 116
            label: "−"; labelSize: 26
            caption: "Paddle"
            down: root.isDown(1)
        }
        MapButton {
            x: 662; y: 78; width: 52; height: 116
            label: "+"; labelSize: 26
            caption: "Paddle"
            down: root.isDown(2)
        }

        // D-pad
        Item {
            x: 112; y: 46; width: 120; height: 120

            MapButton { x: 40; y: 0; width: 40; height: 44; icon: "keyboard_arrow_up"; down: root.hatY < 0 }
            MapButton { x: 40; y: 76; width: 40; height: 44; icon: "keyboard_arrow_down"; down: root.hatY > 0 }
            MapButton { x: 0; y: 40; width: 44; height: 40; icon: "keyboard_arrow_left"; down: root.hatX < 0 }
            MapButton { x: 76; y: 40; width: 44; height: 40; icon: "keyboard_arrow_right"; down: root.hatX > 0 }
            StyledRect { x: 46; y: 46; width: 28; height: 28; radius: 14; color: Colours.m3surfaceContainerHigh }
        }

        // Face buttons
        Item {
            x: 488; y: 46; width: 120; height: 120

            MapButton { x: 38; y: 0; width: 44; height: 44; symbol: "triangle"; down: root.isDown(3) }
            MapButton { x: 0; y: 38; width: 44; height: 44; symbol: "square"; down: root.isDown(4) }
            MapButton { x: 76; y: 38; width: 44; height: 44; symbol: "circle"; down: root.isDown(5) }
            MapButton { x: 38; y: 76; width: 44; height: 44; symbol: "cross"; down: root.isDown(6) }
        }

        // Shoulder style buttons under the clusters
        MapButton { x: 100; y: 206; width: 64; height: 40; label: "L2"; down: root.isDown(10) }
        MapButton { x: 180; y: 230; width: 64; height: 40; label: "L3"; down: root.isDown(22) }
        MapButton { x: 556; y: 206; width: 64; height: 40; label: "R2"; down: root.isDown(9) }
        MapButton { x: 476; y: 230; width: 64; height: 40; label: "R3"; down: root.isDown(23) }

        // Create and Options sit at the top corners of the hub
        MapButton { x: 270; y: 54; width: 56; height: 30; label: "Create"; labelSize: Appearance.font.size.labelSmall; down: root.isDown(7) }
        MapButton { x: 394; y: 54; width: 56; height: 30; label: "Options"; labelSize: Appearance.font.size.labelSmall; down: root.isDown(8) }

        // Screen with the encoder slot
        StyledRect {
            x: 310; y: 98; width: 100; height: 52
            radius: 16
            color: Colours.m3surfaceContainerLowest
            border.width: 1
            border.color: Colours.m3outlineVariant

            StyledText {
                anchors.centerIn: parent
                text: root.encoderSlot > 0 ? "E" + root.encoderSlot : "E–"
                color: Colours.m3primary
                font.pixelSize: Appearance.font.size.headlineSmall
                font.weight: Font.Medium
                animate: true
            }
        }

        MapButton { x: 336; y: 162; width: 48; height: 48; label: "PS"; down: root.isDown(13) }

        // Left thumb rocker: up picks the slot inside the wheel (never sent to the PC), down is EP.
        Column {
            x: 10; y: 230
            spacing: 6

            MapButton { width: 44; height: 40; icon: "sync"; down: false; opacity: 0.55 }
            MapButton { width: 44; height: 40; icon: "keyboard_arrow_down"; caption: "EP"; down: root.anyDown([11, 12, 24, 25]) }
        }

        // Right thumb rocker: E+ and E−.
        Column {
            x: 666; y: 230
            spacing: 6

            MapButton { width: 44; height: 40; icon: "add"; down: root.anyDown([14, 17, 19, 21]) }
            MapButton { width: 44; height: 40; icon: "remove"; caption: "E+ / E−"; down: root.anyDown([15, 16, 18, 20]) }
        }
    }
}
