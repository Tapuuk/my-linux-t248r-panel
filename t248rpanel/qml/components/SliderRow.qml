import QtQuick
import QtQuick.Layouts

// One tunable in a connected list: icon, name, a short explanation, the value, and the slider.
ConnectedRect {
    id: root

    property string icon
    property string title
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property real value
    property var format: v => Math.round(v).toString()
    property string description
    property list<real> presets
    readonly property alias dragging: slider.pressed

    signal moved(real value)

    implicitHeight: body.implicitHeight + 32

    ColumnLayout {
        id: body

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            StyledRect {
                implicitWidth: 40
                implicitHeight: 40
                radius: 20
                color: Colours.m3secondaryContainer

                Icon {
                    anchors.centerIn: parent
                    icon: root.icon
                    size: 22
                    fill: 1
                    color: Colours.m3onSecondaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: Appearance.font.size.bodyLarge
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.description
                    color: Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.bodySmall
                    wrapMode: Text.Wrap
                }
            }

            StyledRect {
                implicitWidth: Math.max(64, valueText.implicitWidth + 24)
                implicitHeight: 32
                radius: 16
                color: Colours.m3surfaceContainerHighest

                StyledText {
                    id: valueText

                    anchors.centerIn: parent
                    text: root.format(slider.value)
                    font.pixelSize: Appearance.font.size.labelLarge
                    font.weight: Font.Medium
                    font.features: ({ "tnum": 1 })
                }
            }
        }

        StyledSlider {
            id: slider

            Layout.fillWidth: true
            Layout.leftMargin: 54
            value: root.value
            valueText: root.format(value)
            onMoved: root.moved(value)
        }

        // Connected button group: small inner corners, and the picked one morphs into a full pill.
        Row {
            Layout.leftMargin: 54
            Layout.topMargin: 6
            Layout.bottomMargin: 2
            visible: root.presets.length > 0
            spacing: 2

            Repeater {
                model: root.presets

                StyledRect {
                    id: seg

                    required property real modelData
                    required property int index
                    readonly property bool selected: Math.round(slider.value) === Math.round(modelData)
                    readonly property bool first: index === 0
                    readonly property bool last: index === root.presets.length - 1
                    readonly property real outer: height / 2
                    readonly property real inner: selected ? height / 2 : segLayer.pressed ? 4 : 8

                    implicitWidth: segLabel.implicitWidth + (selected ? 36 : 28)
                    implicitHeight: 40
                    topLeftRadius: first || selected ? outer : inner
                    bottomLeftRadius: first || selected ? outer : inner
                    topRightRadius: last || selected ? outer : inner
                    bottomRightRadius: last || selected ? outer : inner
                    color: selected ? Colours.m3primary : Colours.m3secondaryContainer

                    Behavior on implicitWidth {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                    Behavior on topLeftRadius {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                    Behavior on bottomLeftRadius {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                    Behavior on topRightRadius {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }
                    Behavior on bottomRightRadius {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    StateLayer {
                        id: segLayer

                        color: seg.selected ? Colours.m3onPrimary : Colours.m3onSecondaryContainer
                        onClicked: root.moved(seg.modelData)
                    }

                    StyledText {
                        id: segLabel

                        anchors.centerIn: parent
                        text: root.format(seg.modelData)
                        color: seg.selected ? Colours.m3onPrimary : Colours.m3onSecondaryContainer
                        font.pixelSize: Appearance.font.size.labelLarge
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
