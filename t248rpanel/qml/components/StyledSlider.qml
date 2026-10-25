import QtQuick
import QtQuick.Controls.Basic as C

// Material 3 Expressive slider: a thick active track, a gap, a thin handle, a gap, the inactive track
// and a stop dot at the end. The value bubble shows while dragging.
C.Slider {
    id: root

    property string valueText: Math.round(value).toString()
    property bool disabledLook: !enabled

    readonly property color activeColour: disabledLook ? Qt.alpha(Colours.m3onSurface, 0.38) : Colours.m3primary
    readonly property color inactiveColour: disabledLook ? Qt.alpha(Colours.m3onSurface, 0.12) : Colours.m3secondaryContainer
    readonly property real trackHeight: 16
    readonly property real gap: 6
    readonly property real handleWidth: pressed ? 2 : 4
    readonly property real handleX: leftPadding + visualPosition * (availableWidth - 4)

    implicitWidth: 240
    implicitHeight: 44
    padding: 0
    leftPadding: 0
    rightPadding: 0
    live: true

    background: Item {
        x: root.leftPadding
        y: root.topPadding
        width: root.availableWidth
        height: root.availableHeight

        StyledRect {
            id: active

            anchors.verticalCenter: parent.verticalCenter
            x: 0
            width: Math.max(0, root.handleX - root.leftPadding - root.gap)
            height: root.trackHeight
            color: root.activeColour
            topLeftRadius: height / 2
            bottomLeftRadius: height / 2
            topRightRadius: 2
            bottomRightRadius: 2
            visible: width > 1
        }

        StyledRect {
            id: inactive

            anchors.verticalCenter: parent.verticalCenter
            x: root.handleX - root.leftPadding + 4 + root.gap
            width: Math.max(0, parent.width - x)
            height: root.trackHeight
            color: root.inactiveColour
            topRightRadius: height / 2
            bottomRightRadius: height / 2
            topLeftRadius: 2
            bottomLeftRadius: 2
            visible: width > 1

            StyledRect {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 6
                width: 4
                height: 4
                radius: 2
                visible: parent.width > 16
                color: root.activeColour
            }
        }
    }

    handle: Item {
        x: root.handleX
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 4
        height: 44

        StyledRect {
            anchors.centerIn: parent
            width: root.handleWidth
            height: parent.height
            radius: width / 2
            color: root.activeColour

            Behavior on width {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        FocusRing {
            target: parent
            visible: root.activeFocus && !root.pressed
            radius: 4
        }

        StyledRect {
            id: bubble

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 6
            width: Math.max(48, bubbleText.implicitWidth + 24)
            height: 40
            radius: height / 2
            color: Colours.m3inverseSurface
            opacity: root.pressed ? 1 : 0
            scale: root.pressed ? 1 : 0.6
            transformOrigin: Item.Bottom
            visible: opacity > 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            StyledText {
                id: bubbleText

                anchors.centerIn: parent
                text: root.valueText
                color: Colours.m3inverseOnSurface
                font.pixelSize: Appearance.font.size.labelLarge
                font.weight: Font.Medium
            }
        }
    }

    HoverHandler {
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
