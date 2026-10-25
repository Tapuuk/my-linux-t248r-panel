import QtQuick

// Small plain tooltip shown above its parent.
StyledRect {
    id: root

    property alias text: label.text
    property bool shown

    anchors.bottom: parent.top
    anchors.bottomMargin: 6
    anchors.horizontalCenter: parent.horizontalCenter
    z: 100
    implicitWidth: label.implicitWidth + 16
    implicitHeight: label.implicitHeight + 8
    radius: Appearance.rounding.extraSmall
    color: Colours.m3inverseSurface
    opacity: shown ? 1 : 0
    visible: opacity > 0
    scale: shown ? 1 : 0.9

    Behavior on opacity {
        SequentialAnimation {
            PauseAnimation {
                duration: root.shown ? 450 : 0
            }
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }

    StyledText {
        id: label

        anchors.centerIn: parent
        color: Colours.m3inverseOnSurface
        font.pixelSize: Appearance.font.size.labelMedium
    }
}
