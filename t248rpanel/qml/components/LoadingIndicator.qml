import QtQuick

// Material 3 Expressive loading indicator: a spinning shape that springs from one cookie to the next.
Item {
    id: root

    property real size: 48
    property bool running: true
    property bool contained
    property color color: contained ? Colours.m3onPrimaryContainer : Colours.m3primary
    property color containerColor: Colours.m3primaryContainer

    readonly property var shapes: [[10, 0.07], [9, 0.09], [2, 0.16], [8, 0.05], [4, 0.12], [0, 0], [5, 0.1]]
    property int index: 0

    // Underdamped spring, same constants as the Caelestia indicator.
    readonly property real stiffness: 180
    readonly property real damping: 0.6
    property real t: 10
    property real baseRotation: 0
    property real morphRotation: 0

    implicitWidth: size
    implicitHeight: size

    function spring(t: real): var {
        const wn = Math.sqrt(stiffness);
        const za = damping * wn;
        const wd = wn * Math.sqrt(1 - damping * damping);
        const e = Math.exp(-za * t);
        return [1 - e * (Math.cos(wd * t) + za / wd * Math.sin(wd * t)), e * (wn * wn / wd) * Math.sin(wd * t)];
    }

    readonly property var springState: spring(t)

    StyledRect {
        anchors.fill: parent
        visible: root.contained
        radius: width / 2
        color: root.containerColor
    }

    PolarShape {
        id: shape

        anchors.centerIn: parent
        width: root.size * (root.contained ? 0.68 : 0.92)
        height: width
        samples: 96
        from: root.shapes[(root.index + root.shapes.length - 1) % root.shapes.length]
        to: root.shapes[root.index]
        progress: Math.min(1, root.springState[0])
        color: root.color
        rotation: root.baseRotation + root.morphRotation + root.springState[0] * 60
        scale: 1 + root.springState[1] * 0.012
    }

    Timer {
        interval: 650
        repeat: true
        running: root.running && root.visible
        onTriggered: {
            root.morphRotation = (root.morphRotation + 60) % 360;
            root.index = (root.index + 1) % root.shapes.length;
            root.t = 0;
        }
    }

    FrameAnimation {
        running: root.running && root.visible
        onTriggered: {
            root.t += frameTime;
            root.baseRotation = (root.baseRotation + frameTime * 360 / 4.666) % 360;
        }
    }
}
