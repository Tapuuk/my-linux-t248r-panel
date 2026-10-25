import QtQuick

// A button on the button map. Lights up and springs when pressed on the wheel.
StyledRect {
    id: root

    property bool down
    property string label
    property string icon
    property string symbol      // triangle square circle cross
    property string caption     // optional text under the button
    property real labelSize: Appearance.font.size.labelLarge

    readonly property color onColour: down ? Colours.m3onPrimary : Colours.m3onSurfaceVariant

    implicitWidth: 44
    implicitHeight: 44
    radius: down ? Math.min(width, height) * 0.32 : Math.min(width, height) / 2
    color: down ? Colours.m3primary : Colours.m3surfaceContainerHighest
    scale: down ? 1.1 : 1

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }
    Behavior on radius {
        Anim {
            type: Anim.FastSpatial
        }
    }

    StyledText {
        anchors.centerIn: parent
        visible: root.label !== ""
        text: root.label
        color: root.onColour
        font.pixelSize: root.labelSize
        font.weight: Font.Medium
    }

    Icon {
        anchors.centerIn: parent
        visible: root.icon !== ""
        icon: root.icon
        size: 22
        fill: root.down ? 1 : 0
        color: root.onColour
    }

    PsSymbol {
        anchors.centerIn: parent
        visible: root.symbol !== ""
        kind: root.symbol || "cross"
        width: root.width * 0.42
        height: width
        color: root.onColour
        lineWidth: 2.2
    }

    StyledText {
        anchors.top: parent.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.caption !== ""
        text: root.caption
        color: root.down ? Colours.m3primary : Colours.m3outline
        font.pixelSize: Appearance.font.size.labelSmall
        font.weight: Font.Medium
        scale: 1 / root.scale
    }
}
