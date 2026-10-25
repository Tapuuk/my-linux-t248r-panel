import QtQuick

// One pedal as a tall pill that fills from the bottom.
Item {
    id: root

    property string label
    property real value: 0
    property color tint: Colours.m3primary
    property color onTint: Colours.m3onPrimary
    property bool active: true

    implicitWidth: 72
    implicitHeight: 260

    StyledText {
        id: percent

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        text: Math.round(root.value * 100) + "%"
        color: root.value > 0.01 ? Colours.m3onSurface : Colours.m3onSurfaceVariant
        font.pixelSize: Appearance.font.size.titleMedium
        font.weight: Font.Medium
        font.features: ({ "tnum": 1 })
    }

    StyledRect {
        id: track

        anchors.top: percent.bottom
        anchors.topMargin: 10
        anchors.bottom: name.top
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(root.width, 64)
        radius: Appearance.rounding.extraLarge - 4
        color: Colours.m3surfaceContainerHighest
        clip: true

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            readonly property real full: parent.height - 8
            height: full * root.value
            radius: Math.min(parent.radius - 4, height / 2)
            visible: height > 1
            color: root.active ? root.tint : Qt.alpha(Colours.m3onSurface, 0.12)
        }
    }

    StyledText {
        id: name

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        text: root.label
        color: Colours.m3onSurfaceVariant
        font.pixelSize: Appearance.font.size.labelLarge
        font.weight: Font.Medium
    }
}
