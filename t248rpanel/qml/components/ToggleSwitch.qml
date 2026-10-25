import QtQuick
import QtQuick.Shapes

// Material 3 switch: the thumb grows while pressed and carries a check or cross drawn with Shapes.
Item {
    id: root

    property bool checked
    property bool disabled
    readonly property bool pressed: mouse.pressed

    signal toggled(bool checked)

    function flip(): void {
        if (disabled)
            return;
        checked = !checked;
        toggled(checked);
    }

    implicitWidth: 52
    implicitHeight: 32
    activeFocusOnTab: !disabled
    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked
    Keys.onSpacePressed: flip()

    StyledRect {
        id: track

        anchors.fill: parent
        radius: height / 2
        color: {
            if (root.disabled)
                return root.checked ? Qt.alpha(Colours.m3onSurface, 0.12) : Qt.alpha(Colours.m3surfaceContainerHighest, 0.38);
            return root.checked ? Colours.m3primary : Colours.m3surfaceContainerHighest;
        }
        border.width: root.checked ? 0 : 2
        border.color: root.disabled ? Qt.alpha(Colours.m3onSurface, 0.12) : Colours.m3outline

        FocusRing {
            target: track
            visible: root.activeFocus
        }

        StyledRect {
            id: thumb

            property real d: root.pressed ? 28 : root.checked ? 24 : 16

            width: d
            height: d
            radius: d / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - (parent.height - width) / 2 : (parent.height - width) / 2
            color: {
                if (root.disabled)
                    return root.checked ? Colours.m3surface : Qt.alpha(Colours.m3onSurface, 0.38);
                return root.checked ? Colours.m3onPrimary : Colours.m3outline;
            }

            Behavior on x {
                Anim {
                    type: Anim.FastSpatial
                }
            }
            Behavior on d {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 40
                height: 40
                radius: 20
                color: root.checked ? Colours.m3primary : Colours.m3onSurface
                opacity: root.disabled ? 0 : root.pressed ? 0.12 : mouse.containsMouse ? 0.08 : 0
                z: -1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Shape {
                id: mark

                anchors.centerIn: parent
                width: 14
                height: 14
                opacity: root.checked ? 1 : 0
                scale: root.checked ? 1 : 0.4
                preferredRendererType: Shape.CurveRenderer

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

                ShapePath {
                    strokeWidth: 2.2
                    strokeColor: root.disabled ? Colours.m3onSurface : Colours.m3primary
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 1.5
                    startY: 7.5

                    PathLine {
                        x: 5.5
                        y: 11.5
                    }
                    PathLine {
                        x: 12.5
                        y: 3
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.flip()
    }
}
