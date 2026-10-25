import QtQuick

// Navigation rail. The active indicator is one pill that travels between items; its leading edge
// moves on the fast spatial spring and the trailing edge on the slower one, so it stretches as it goes.
Item {
    id: root

    property var model: []          // [{ icon, label }]
    property int currentIndex: 0
    default property alias footer: footerSlot.data

    readonly property real itemHeight: 64
    readonly property real itemSpacing: 8
    readonly property real indicatorHeight: 32
    readonly property real indicatorWidth: 56

    signal activated(int index)

    implicitWidth: 100

    function itemY(i: int): real {
        return items.y + i * (itemHeight + itemSpacing) + 4;
    }

    property real indicatorTop: 0
    property real indicatorBottom: indicatorHeight
    property bool movingDown: true

    function place(): void {
        const t = itemY(currentIndex);
        movingDown = t > indicatorTop;
        indicatorTop = t;
        indicatorBottom = t + indicatorHeight;
    }

    onCurrentIndexChanged: place()
    Component.onCompleted: place()

    Behavior on indicatorTop {
        Anim {
            type: root.movingDown ? Anim.DefaultSpatial : Anim.FastSpatial
        }
    }
    Behavior on indicatorBottom {
        Anim {
            type: root.movingDown ? Anim.FastSpatial : Anim.DefaultSpatial
        }
    }

    Item {
        id: header

        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: 56
        height: 56

        PolarShape {
            id: logoShape

            anchors.fill: parent
            from: [9, 0.07]
            color: Colours.m3primaryContainer
            rotation: logoSpin.angle
        }

        Icon {
            anchors.centerIn: parent
            icon: "search_hands_free"
            size: 28
            fill: 1
            weight: 500
            color: Colours.m3onPrimaryContainer
        }

        // A slow quarter turn whenever the page changes, like the wheel being nudged.
        QtObject {
            id: logoSpin

            property real angle: root.currentIndex * 40

            Behavior on angle {
                Anim {
                    type: Anim.SlowSpatial
                }
            }
        }
    }

    StyledRect {
        id: indicator

        x: (root.width - root.indicatorWidth) / 2
        y: root.indicatorTop
        width: root.indicatorWidth
        height: Math.max(root.indicatorHeight, root.indicatorBottom - root.indicatorTop)
        radius: root.indicatorHeight / 2
        color: Colours.m3secondaryContainer
    }

    Column {
        id: items

        anchors.top: header.bottom
        anchors.topMargin: 36
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: root.itemSpacing
        onYChanged: root.place()

        Repeater {
            model: root.model

            Item {
                id: item

                required property var modelData
                required property int index
                readonly property bool current: index === root.currentIndex

                width: items.width
                height: root.itemHeight
                activeFocusOnTab: true
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.label
                Keys.onSpacePressed: root.activated(index)
                Keys.onReturnPressed: root.activated(index)

                Item {
                    id: pill

                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 4
                    width: root.indicatorWidth
                    height: root.indicatorHeight

                    property real radius: height / 2

                    StateLayer {
                        id: stateLayer

                        color: item.current ? Colours.m3onSecondaryContainer : Colours.m3onSurfaceVariant
                        radius: pill.radius
                        onClicked: root.activated(item.index)
                    }

                    FocusRing {
                        target: pill
                        visible: item.activeFocus
                    }

                    Icon {
                        anchors.centerIn: parent
                        icon: item.modelData.icon
                        size: 24
                        fill: item.current ? 1 : 0
                        weight: item.current ? 500 : 400
                        color: item.current ? Colours.m3onSecondaryContainer : Colours.m3onSurfaceVariant
                        scale: stateLayer.pressed ? 0.88 : 1

                        Behavior on scale {
                            Anim {
                                type: Anim.FastSpatial
                            }
                        }
                    }
                }

                StyledText {
                    anchors.top: pill.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 2
                    horizontalAlignment: Text.AlignHCenter
                    text: item.modelData.label
                    color: item.current ? Colours.m3onSurface : Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.labelMedium
                    font.weight: item.current ? Font.DemiBold : Font.Medium
                    elide: Text.ElideRight
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activated(item.index)
                }
            }
        }
    }

    Item {
        id: footerSlot

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
