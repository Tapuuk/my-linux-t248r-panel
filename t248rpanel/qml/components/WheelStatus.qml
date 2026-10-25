import QtQuick

// Rail footer: a dot that tells you at a glance whether the wheel is there and has force feedback.
Item {
    id: root

    readonly property string level: !Wheel.connected ? "none" : Wheel.ffbReady ? "ready" : "partial"
    readonly property string tip: level === "none" ? "No wheel connected" : level === "ready" ? "Wheel connected, force feedback on" : "Wheel connected, no force feedback yet"

    width: 56
    height: 56

    StyledRect {
        anchors.centerIn: parent
        width: 48
        height: 48
        radius: 24
        color: root.level === "ready" ? Colours.m3primaryContainer : root.level === "partial" ? Colours.m3tertiaryContainer : Colours.m3surfaceContainerHigh

        Icon {
            anchors.centerIn: parent
            icon: "usb"
            size: 22
            fill: 1
            color: root.level === "ready" ? Colours.m3onPrimaryContainer : root.level === "partial" ? Colours.m3onTertiaryContainer : Colours.m3outline
        }

        StyledRect {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            width: 12
            height: 12
            radius: 6
            border.width: 2
            border.color: Colours.m3surface
            color: root.level === "ready" ? Colours.m3primary : root.level === "partial" ? Colours.m3tertiary : Colours.m3outline
            scale: root.level === "none" ? 0.8 : 1

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        MouseArea {
            id: hover

            anchors.fill: parent
            hoverEnabled: true
        }

        Tip {
            text: root.tip
            shown: hover.containsMouse
            anchors.bottom: undefined
            anchors.horizontalCenter: undefined
            anchors.left: parent.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
