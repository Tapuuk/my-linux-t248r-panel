import QtQuick
import QtQuick.Layouts
import "../components"

Page {
    id: page

    signal navigate(int index)

    property real strength: 0.5
    readonly property bool wide: contentWidth > 760

    readonly property string ffbReason: {
        if (!Wheel.connected)
            return "Plug in your wheel to test force feedback.";
        if (Wheel.mode !== "pc")
            return "The wheel is in PlayStation mode. Switch it to PC mode on Home first.";
        if (Wheel.driver !== "tmff2")
            return "The wheel uses the generic driver, which has no force feedback. Run setup on Home first.";
        return "The wheel isn't ready for force feedback yet. Give it a few seconds, or run setup again on Home.";
    }

    title: "Wheel test"
    subtitle: Wheel.connected ? "Turn the wheel, press the pedals and buttons. Everything here is live." : "Plug in your wheel to see its input live."

    GridLayout {
        Layout.fillWidth: true
        columns: page.wide ? 2 : 1
        columnSpacing: Appearance.spacing.large
        rowSpacing: Appearance.spacing.large

        // Steering
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 14

            CardTitle {
                text: "Steering"
                detail: "Range " + Wheel.range + "°"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 24

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 230
                    implicitWidth: 230

                    StyledRect {
                        anchors.centerIn: parent
                        width: 230
                        height: 230
                        radius: 115
                        color: Colours.m3surfaceContainerHigh
                    }

                    SteeringWheel {
                        anchors.centerIn: parent
                        width: 210
                        height: 210
                        angle: Wheel.steeringDegrees
                        active: Wheel.connected
                        screenText: Wheel.encoderSlot > 0 ? "E" + Wheel.encoderSlot : ""
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 150
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            const d = Math.round(Wheel.steeringDegrees);
                            return (d < 0 ? "−" : "") + Math.abs(d) + "°";
                        }
                        font.pixelSize: Appearance.font.size.displayMedium
                        font.weight: Font.Medium
                        font.features: ({ "tnum": 1 })
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Math.abs(Wheel.steeringDegrees) < 0.5 ? "Centered" : Wheel.steeringDegrees < 0 ? "Left" : "Right"
                        color: Colours.m3onSurfaceVariant
                        font.pixelSize: Appearance.font.size.bodyLarge
                    }

                    // Centre-out bar: how far you are towards full lock
                    Item {
                        Layout.fillWidth: true
                        Layout.topMargin: 16
                        implicitHeight: 12

                        StyledRect {
                            anchors.fill: parent
                            radius: 6
                            color: Colours.m3surfaceContainerHighest
                        }
                        StyledRect {
                            readonly property real half: parent.width / 2
                            x: Wheel.steering < 0 ? half + Wheel.steering * half : half
                            width: Math.abs(Wheel.steering) * half
                            height: parent.height
                            radius: 6
                            color: Colours.m3primary
                        }
                        StyledRect {
                            x: parent.width / 2 - 1
                            width: 2
                            height: parent.height + 6
                            y: -3
                            radius: 1
                            color: Colours.m3outline
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            text: "−" + Math.round(Wheel.range / 2) + "°"
                            color: Colours.m3outline
                            font.pixelSize: Appearance.font.size.labelSmall
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: Math.round(Wheel.range / 2) + "°"
                            color: Colours.m3outline
                            font.pixelSize: Appearance.font.size.labelSmall
                        }
                    }
                }
            }
        }

        // Pedals
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 10

            CardTitle {
                text: "Pedals"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 230
                spacing: 12

                Item {
                    Layout.fillWidth: true
                }
                PedalBar {
                    Layout.fillHeight: true
                    label: "Clutch"
                    value: Wheel.clutch
                    tint: Colours.m3tertiary
                    active: Wheel.connected
                }
                PedalBar {
                    Layout.fillHeight: true
                    label: "Brake"
                    value: Wheel.brake
                    tint: Colours.m3error
                    active: Wheel.connected
                }
                PedalBar {
                    Layout.fillHeight: true
                    label: "Throttle"
                    value: Wheel.throttle
                    tint: Colours.m3primary
                    active: Wheel.connected
                }
                Item {
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Buttons
    Card {
        Layout.fillWidth: true

        CardTitle {
            text: "Buttons"
            detail: Wheel.pressed.length > 0 ? "Pressed: " + Wheel.pressed.join(", ") : "Press any button on the wheel"
        }

        ButtonMap {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(340, width * 340 / 720)
            pressed: Wheel.pressed
            hatX: Wheel.hatX
            hatY: Wheel.hatY
            encoderSlot: Wheel.encoderSlot
            active: Wheel.connected
        }

        StyledText {
            Layout.fillWidth: true
            text: "EP, E+ and E− send a different button for each encoder slot, E1 to E4. The selector above EP picks the slot on the wheel's screen; the wheel never sends that press to the computer."
            color: Colours.m3onSurfaceVariant
            font.pixelSize: Appearance.font.size.bodySmall
            wrapMode: Text.Wrap
        }
    }

    // Force feedback test
    Card {
        Layout.fillWidth: true

        CardTitle {
            text: "Force feedback test"
            detail: Wheel.ffbReady ? "Hold the wheel lightly" : ""
        }

        StyledRect {
            Layout.fillWidth: true
            visible: !Wheel.ffbReady
            implicitHeight: reasonRow.implicitHeight + 24
            radius: Appearance.rounding.large
            color: Colours.m3surfaceContainerHigh

            RowLayout {
                id: reasonRow

                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 8
                spacing: 12

                Icon {
                    icon: "info"
                    size: 22
                    color: Colours.m3onSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    text: page.ffbReason
                    color: Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.bodyMedium
                    wrapMode: Text.Wrap
                }
                TextButton {
                    visible: Wheel.connected
                    type: TextButton.Text
                    text: "Go to Home"
                    onClicked: page.navigate(0)
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            TextButton {
                type: TextButton.Tonal
                icon: "rotate_left"
                text: "Pull left"
                disabled: !Wheel.ffbReady
                onClicked: Wheel.playEffect("left", page.strength)
            }
            TextButton {
                type: TextButton.Tonal
                icon: "rotate_right"
                text: "Pull right"
                disabled: !Wheel.ffbReady
                onClicked: Wheel.playEffect("right", page.strength)
            }
            TextButton {
                type: TextButton.Tonal
                icon: "sync"
                text: "Center spring"
                disabled: !Wheel.ffbReady
                onClicked: Wheel.playEffect("spring", page.strength)
            }
            TextButton {
                type: TextButton.Tonal
                icon: "vibration"
                text: "Rumble"
                disabled: !Wheel.ffbReady
                onClicked: Wheel.playEffect("rumble", page.strength)
            }
            TextButton {
                type: TextButton.Outlined
                icon: "close"
                text: "Stop"
                disabled: !Wheel.ffbReady
                onClicked: Wheel.stopEffects()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            StyledText {
                text: "Strength"
                color: Wheel.ffbReady ? Colours.m3onSurface : Qt.alpha(Colours.m3onSurface, 0.38)
                font.pixelSize: Appearance.font.size.bodyLarge
            }
            StyledSlider {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: page.strength
                enabled: Wheel.ffbReady
                valueText: Math.round(value * 100) + "%"
                onMoved: page.strength = value
            }
            StyledText {
                Layout.preferredWidth: 48
                horizontalAlignment: Text.AlignRight
                text: Math.round(page.strength * 100) + "%"
                color: Wheel.ffbReady ? Colours.m3onSurfaceVariant : Qt.alpha(Colours.m3onSurface, 0.38)
                font.pixelSize: Appearance.font.size.bodyLarge
                font.features: ({ "tnum": 1 })
            }
        }
    }
}
