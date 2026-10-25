import QtQuick
import QtQuick.Layouts
import "../components"

Page {
    id: page

    signal navigate(int index)
    signal uninstallRequested

    readonly property bool wide: contentWidth > 820

    title: "Help"
    subtitle: "Fixes for the usual problems, and a way back if you want to undo everything."

    GridLayout {
        Layout.fillWidth: true
        columns: page.wide ? 2 : 1
        columnSpacing: Appearance.spacing.large
        rowSpacing: Appearance.spacing.large

        HelpCard {
            Layout.preferredWidth: 10
            icon: "vibration"
            title: "No force feedback in a game"
            steps: [
                "Test here first. If Pull left and Pull right work on the Wheel test page, the driver is fine and the game is the problem.",
                "In Steam, open the game's Properties, then Controller, and turn Steam Input off for that game.",
                "Some Proton games only send force feedback with a particular Proton version. Try another one under Properties, then Compatibility.",
                "If the buttons work but nothing pushes back, turn on Keep the wheel awake on the Force feedback page."
            ]

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextButton {
                    type: TextButton.Tonal
                    size: TextButton.Small
                    icon: "search_hands_free"
                    text: "Wheel test"
                    onClicked: page.navigate(1)
                }
                TextButton {
                    type: TextButton.Tonal
                    size: TextButton.Small
                    icon: "tune"
                    text: "Force feedback"
                    onClicked: page.navigate(3)
                }
            }
        }

        HelpCard {
            Layout.preferredWidth: 10
            icon: "search_hands_free"
            title: "Wheel not found"
            steps: [
                "Plug the wheel straight into the PC, not through a hub or the monitor.",
                "Wait until the wheel has finished turning to calibrate, then give it a few seconds.",
                "If it shows up in PlayStation mode, Home has a button to switch it to PC mode.",
                "Still nothing? Run setup on Home. It adds the permissions this app and your games need."
            ]

            TextButton {
                type: TextButton.Tonal
                size: TextButton.Small
                icon: "home"
                text: "Go to Home"
                onClicked: page.navigate(0)
            }
        }
    }

    HelpCard {
        icon: "window"
        title: "Recover the wheel with Windows"
        intro: "If the wheel stops responding or a firmware update failed, Thrustmaster's own tools can fix it. You need a Windows PC with the Thrustmaster drivers installed."

        GridLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            columns: page.wide ? 2 : 1
            columnSpacing: Appearance.spacing.large
            rowSpacing: Appearance.spacing.large

            StepList {
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                Layout.alignment: Qt.AlignTop
                title: "Firmware recovery"
                steps: [
                    "Hold the SETTINGS button on the wheel.",
                    "Keep holding it while you plug the USB cable into the PC, for about 5 seconds.",
                    "Open My Thrustmaster Panel and choose FIRMWARE RECOVERY.",
                    "Click OPEN FIRMWARE UPDATER, then OK, and let it finish."
                ]
            }

            StepList {
                Layout.fillWidth: true
                Layout.preferredWidth: 10
                Layout.alignment: Qt.AlignTop
                title: "Recalibrate the center"
                steps: [
                    "Turn the wheel fully left.",
                    "Turn it fully right.",
                    "Bring it back to the center.",
                    "Hold SHARE/CREATE, MODE and OPTIONS together for 5 seconds."
                ]
            }
        }
    }

    Card {
        Layout.fillWidth: true
        spacing: 12

        CardTitle {
            text: "Tools"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            ListTile {
                first: true
                icon: "troubleshoot"
                title: "Copy diagnostic report"
                subtitle: "Your distro, kernel, wheel and driver state as plain text, ready to paste into a bug report."
                clickable: true
                onClicked: Clipboard.copy(System.report(), "Report copied")

                Icon {
                    icon: "content_copy"
                    size: 22
                    color: Colours.m3onSurfaceVariant
                }
            }
            ListTile {
                last: true
                icon: "delete_forever"
                iconBackground: Colours.m3errorContainer
                iconColour: Colours.m3onErrorContainer
                title: "Undo everything"
                subtitle: "Removes the driver, the wheel permissions and saved settings."
                clickable: !Setup.running
                onClicked: page.uninstallRequested()

                Icon {
                    icon: "arrow_forward"
                    size: 22
                    color: Colours.m3onSurfaceVariant
                }
            }
        }
    }

    // About
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: aboutRow.implicitHeight + 56
        radius: Appearance.rounding.extraLargeIncreased
        color: Colours.m3surfaceContainer

        RowLayout {
            id: aboutRow

            anchors.fill: parent
            anchors.margins: 28
            spacing: 24

            Item {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 72
                implicitHeight: 72

                PolarShape {
                    anchors.fill: parent
                    from: [9, 0.07]
                    color: Colours.m3primaryContainer
                }
                Icon {
                    anchors.centerIn: parent
                    icon: "search_hands_free"
                    size: 36
                    fill: 1
                    color: Colours.m3onPrimaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    text: "My Linux T248R Panel"
                    font.pixelSize: Appearance.font.size.headlineSmall
                    wrapMode: Text.Wrap
                }
                StyledText {
                    Layout.fillWidth: true
                    text: "Version " + (typeof AppVersion !== "undefined" ? AppVersion : "") + ". MIT License, © Tapuuk."
                    color: Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.bodyMedium
                    wrapMode: Text.Wrap
                }
                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: "Force feedback comes from hid-tmff2 by Kimplul, licensed under GPL-2.0. This app downloads, builds and installs it for you."
                    font.pixelSize: Appearance.font.size.bodyMedium
                    lineHeight: 1.15
                    wrapMode: Text.Wrap
                }
                StyledText {
                    Layout.fillWidth: true
                    text: "Thrustmaster and T248R are trademarks of Guillemot Corporation. This app is not affiliated with or endorsed by Guillemot Corporation."
                    color: Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.bodySmall
                    lineHeight: 1.15
                    wrapMode: Text.Wrap
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 8

                    TextButton {
                        type: TextButton.Outlined
                        size: TextButton.Small
                        icon: "code"
                        text: "Source code"
                        onClicked: Qt.openUrlExternally("https://github.com/Tapuuk/my-linux-t248r-panel")
                    }
                    TextButton {
                        type: TextButton.Outlined
                        size: TextButton.Small
                        icon: "open_in_new"
                        text: "hid-tmff2"
                        onClicked: Qt.openUrlExternally("https://github.com/Kimplul/hid-tmff2")
                    }
                }
            }
        }
    }
}
