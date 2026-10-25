import QtQuick
import QtQuick.Layouts
import "../components"

Page {
    id: page

    readonly property bool wide: contentWidth > 760
    // Only the TH8A has a sequential mode and it reports the same USB ID as the TH8S, so the
    // up/down indicators appear once the shifter has sent a sequential shift this session.
    property bool seenSequential: false

    readonly property string gearName: Shifter.gear === 0 ? "N" : Shifter.gear === -1 ? "R" : Shifter.gear.toString()

    title: "Shifter"
    subtitle: Shifter.connected ? (seenSequential ? "Move the lever through the gates, or push and pull it in sequential mode." : "Move the lever through the gates. Everything here is live.") : "Thrustmaster TH8A and TH8S, plugged into your PC over USB."

    Component.onCompleted: seenSequential = Shifter.sequential !== ""

    Connections {
        target: Shifter

        function onSequentialChanged(): void {
            if (Shifter.sequential !== "")
                page.seenSequential = true;
        }
    }

    // Nothing connected
    Card {
        Layout.fillWidth: true
        visible: !Shifter.connected
        padding: 40

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 18

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 120
                implicitHeight: 120

                PolarShape {
                    anchors.fill: parent
                    from: [8, 0.07]
                    color: Colours.m3secondaryContainer
                    rotation: idleSpin.angle

                    QtObject {
                        id: idleSpin

                        property real angle: 0

                        NumberAnimation on angle {
                            from: 0
                            to: 360
                            duration: 24000
                            loops: Animation.Infinite
                            running: !Shifter.connected && page.visible
                        }
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    icon: "usb"
                    size: 48
                    fill: 1
                    color: Colours.m3onSecondaryContainer
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "No shifter found"
                font.pixelSize: Appearance.font.size.headlineMedium
            }

            StyledText {
                Layout.fillWidth: true
                Layout.maximumWidth: 520
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Plug the TH8A or TH8S into a USB port on your PC, not into the wheel base. It shows up here on its own and needs no setup."
                color: Colours.m3onSurfaceVariant
                font.pixelSize: Appearance.font.size.bodyLarge
                lineHeight: 1.15
                wrapMode: Text.Wrap
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        visible: Shifter.connected
        columns: page.wide ? 2 : 1
        columnSpacing: Appearance.spacing.large
        rowSpacing: Appearance.spacing.large

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 20

            CardTitle {
                text: "H-pattern"
                detail: "7 gears and reverse"
            }

            HGate {
                Layout.fillWidth: true
                Layout.preferredHeight: 340
                gear: Shifter.gear
                active: Shifter.connected
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 9
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.large

            // Current gear
            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 200
                radius: Appearance.rounding.extraLargeIncreased
                color: Shifter.gear === 0 ? Colours.m3surfaceContainer : Colours.m3primaryContainer

                StyledText {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 22
                    text: "Gear"
                    color: Shifter.gear === 0 ? Colours.m3onSurfaceVariant : Colours.m3onPrimaryContainer
                    font.pixelSize: Appearance.font.size.titleMedium
                }

                StyledText {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 10
                    text: page.gearName
                    color: Shifter.gear === 0 ? Colours.m3onSurfaceVariant : Colours.m3onPrimaryContainer
                    font.pixelSize: 112
                    font.weight: Font.Medium
                    scale: bump.value

                    QtObject {
                        id: bump

                        property real value: 1
                    }
                }

                Connections {
                    target: Shifter

                    function onGearChanged(): void {
                        bumpAnim.restart();
                    }
                }

                SequentialAnimation {
                    id: bumpAnim

                    NumberAnimation {
                        target: bump
                        property: "value"
                        to: 0.82
                        duration: 70
                        easing.type: Easing.OutQuad
                    }
                    Anim {
                        target: bump
                        property: "value"
                        to: 1
                        type: Anim.FastSpatial
                    }
                }
            }

            // Sequential, TH8A only
            Card {
                Layout.fillWidth: true
                visible: page.seenSequential
                spacing: 12

                CardTitle {
                    text: "Sequential"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { key: "up", icon: "keyboard_arrow_up", label: "Up" },
                            { key: "down", icon: "keyboard_arrow_down", label: "Down" }
                        ]

                        StyledRect {
                            id: seq

                            required property var modelData
                            readonly property bool on: Shifter.sequential === modelData.key

                            Layout.fillWidth: true
                            implicitHeight: 64
                            radius: on ? Appearance.rounding.large : 32
                            color: on ? Colours.m3primary : Colours.m3surfaceContainerHighest
                            scale: on ? 1.04 : 1

                            Behavior on radius {
                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }
                            Behavior on scale {
                                Anim {
                                    type: Anim.FastSpatial
                                }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Icon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: seq.modelData.icon
                                    size: 28
                                    fill: 1
                                    color: seq.on ? Colours.m3onPrimary : Colours.m3onSurfaceVariant
                                }
                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: seq.modelData.label
                                    color: seq.on ? Colours.m3onPrimary : Colours.m3onSurfaceVariant
                                    font.pixelSize: Appearance.font.size.titleMedium
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Push the lever forward or pull it back while the shifter is in sequential mode."
                    color: Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.bodySmall
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    // Device facts
    Card {
        Layout.fillWidth: true
        visible: Shifter.connected
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            ListTile {
                first: true
                icon: "usb"
                iconBackground: Colours.m3primaryContainer
                iconColour: Colours.m3onPrimaryContainer
                title: Shifter.model || "TH8A / TH8S shifter"
                subtitle: "Connected over USB. Games see it as its own controller."

                Chip {
                    icon: "check_circle"
                    text: "Connected"
                    tint: Colours.m3primaryContainer
                    onTint: Colours.m3onPrimaryContainer
                }
            }
            ListTile {
                last: true
                icon: "radio_button_checked"
                title: "Buttons pressed"
                subtitle: Shifter.pressed.length > 0 ? Shifter.pressed.join(", ") : "None"
            }
        }
    }
}
