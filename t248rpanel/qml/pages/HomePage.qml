import QtQuick
import QtQuick.Layouts
import "../components"

Page {
    id: page

    signal navigate(int index)

    readonly property bool psMode: Wheel.connected && (Wheel.mode === "ps1" || Wheel.mode === "ps2")
    readonly property bool hasSteps: Setup.running || Setup.steps.length > 0
    readonly property bool setupFailed: !Setup.running && (Setup.lastError !== "" || Setup.steps.some(s => s.state === "failed"))
    readonly property bool wide: contentWidth > 820

    title: System.allGood ? "Your wheel is ready" : "Set up your wheel"
    subtitle: System.allGood ? "Force feedback is on. Try it on the Wheel test page." : "A few things are needed before games can use force feedback. One button does all of it."

    // Hero: the wheel and its state
    StyledRect {
        Layout.fillWidth: true
        implicitHeight: heroRow.implicitHeight + 56
        radius: Appearance.rounding.extraLargeIncreased
        color: Colours.m3surfaceContainer

        RowLayout {
            id: heroRow

            anchors.fill: parent
            anchors.margins: 28
            spacing: 32

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 176
                implicitHeight: 176

                PolarShape {
                    id: heroShape

                    anchors.fill: parent
                    from: [9, 0.06]
                    color: page.psMode ? Colours.m3tertiaryContainer : Wheel.connected ? Colours.m3primaryContainer : Colours.m3surfaceContainerHighest
                    rotation: Wheel.steeringDegrees * 0.25
                }

                SteeringWheel {
                    anchors.centerIn: parent
                    width: 132
                    height: 132
                    angle: Wheel.connected ? Math.max(-135, Math.min(135, Wheel.steeringDegrees)) : 0
                    active: Wheel.connected
                    screenText: Wheel.encoderSlot > 0 ? "E" + Wheel.encoderSlot : ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 12

                StyledText {
                    Layout.fillWidth: true
                    text: "THRUSTMASTER"
                    color: Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.labelMedium
                    font.weight: Font.Medium
                    font.letterSpacing: 1.6
                    visible: Wheel.connected
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: -6
                    text: !Wheel.connected ? "No wheel found" : Wheel.isT248r ? "T248R" : (Wheel.product || "Thrustmaster wheel")
                    font.pixelSize: Appearance.font.size.displaySmall
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    animate: true
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 560
                    text: {
                        if (!Wheel.connected)
                            return "Plug the T248R into a USB port on your PC. It shows up here on its own.";
                        if (page.psMode)
                            return "The wheel is in PlayStation mode, so Linux can't use its force feedback. Switch it to PC mode; the wheel restarts and is back in a few seconds.";
                        if (Wheel.driver === "tmff2")
                            return "PC mode, with the force feedback driver. Games on this computer can steer the wheel.";
                        return "PC mode. The wheel works as a controller, but the generic driver can't do force feedback. Setup below installs the right one.";
                    }
                    color: Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.bodyLarge
                    lineHeight: 1.15
                    wrapMode: Text.Wrap
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 8
                    visible: Wheel.connected

                    Chip {
                        icon: page.psMode ? "gamepad" : "window"
                        text: page.psMode ? "PlayStation mode" : "PC mode"
                        tint: page.psMode ? Colours.m3tertiaryContainer : Colours.m3secondaryContainer
                        onTint: page.psMode ? Colours.m3onTertiaryContainer : Colours.m3onSecondaryContainer
                    }
                    Chip {
                        icon: "memory"
                        text: Wheel.firmware ? "Firmware " + Wheel.firmware : "Firmware shows after setup"
                        tint: Colours.m3surfaceContainerHighest
                        onTint: Colours.m3onSurfaceVariant
                    }
                    Chip {
                        visible: !page.psMode
                        icon: Wheel.driver === "tmff2" ? "bolt" : "warning"
                        text: Wheel.driver === "tmff2" ? "Force feedback driver active" : Wheel.driver === "hid-generic" ? "Generic driver, no force feedback" : "No driver"
                        tint: Wheel.driver === "tmff2" ? Colours.m3primaryContainer : Colours.m3errorContainer
                        onTint: Wheel.driver === "tmff2" ? Colours.m3onPrimaryContainer : Colours.m3onErrorContainer
                    }
                }

                TextButton {
                    Layout.topMargin: 6
                    visible: page.psMode
                    type: TextButton.Filled
                    icon: "sync_alt"
                    text: "Switch to PC mode"
                    disabled: Setup.running
                    busy: Setup.running && Setup.steps.some(s => s.id === "switch")
                    onClicked: Setup.switchToPc()
                }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: page.wide ? 2 : 1
        columnSpacing: Appearance.spacing.large
        rowSpacing: Appearance.spacing.large

        // Setup checklist and the one big button
        Card {
            Layout.fillWidth: true
            Layout.preferredWidth: 10
            Layout.alignment: Qt.AlignTop

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        text: "Setup"
                        font.pixelSize: Appearance.font.size.titleLarge
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: {
                            const left = System.checks.filter(c => c.state !== "ok").length;
                            if (left === 0)
                                return "Everything is in place.";
                            return left === 1 ? "One thing left to do." : left + " things left to do.";
                        }
                        color: Colours.m3onSurfaceVariant
                        font.pixelSize: Appearance.font.size.bodyMedium
                        animate: true
                    }
                }

                IconButton {
                    icon: "refresh"
                    tooltip: "Check again"
                    onClicked: System.refresh()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: System.checks

                    ListTile {
                        required property var modelData
                        required property int index

                        first: index === 0
                        last: index === System.checks.length - 1
                        icon: {
                            switch (modelData.id) {
                            case "tools": return "construction";
                            case "driver": return "deployed_code";
                            case "rules": return "shield";
                            case "active": return "bolt";
                            }
                            return "settings";
                        }
                        iconBackground: modelData.state === "ok" ? Colours.m3primaryContainer : Colours.m3surfaceContainerHighest
                        iconColour: modelData.state === "ok" ? Colours.m3onPrimaryContainer : Colours.m3onSurfaceVariant
                        title: modelData.title
                        subtitle: modelData.detail

                        StateIcon {
                            status: modelData.state
                        }
                    }
                }
            }

            TextButton {
                Layout.fillWidth: true
                Layout.topMargin: 4
                size: TextButton.Large
                type: System.allGood ? TextButton.Tonal : TextButton.Filled
                icon: System.allGood ? "refresh" : "build"
                text: Setup.running ? "Working…" : System.allGood ? "Run setup again" : "Set up everything"
                disabled: Setup.running || !System.supported
                busy: Setup.running
                onClicked: Setup.runAll(true)
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: System.supported ? "Asks for your password once. The first run takes a few minutes while the driver builds." : "Setup can't run on this system. The note on this page explains why."
                color: Colours.m3onSurfaceVariant
                font.pixelSize: Appearance.font.size.bodySmall
                wrapMode: Text.Wrap
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 10
            Layout.alignment: Qt.AlignTop
            spacing: Appearance.spacing.large

            // Progress of the current or last helper run
            Card {
                id: progress

                property bool logOpen

                Layout.fillWidth: true
                visible: page.hasSteps

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Item {
                        implicitWidth: 56
                        implicitHeight: 56

                        LoadingIndicator {
                            anchors.fill: parent
                            visible: Setup.running
                            running: Setup.running
                            contained: true
                            size: 56
                        }

                        StyledRect {
                            anchors.fill: parent
                            visible: !Setup.running
                            radius: 28
                            color: page.setupFailed ? Colours.m3errorContainer : Colours.m3primaryContainer

                            Icon {
                                anchors.centerIn: parent
                                icon: page.setupFailed ? "error" : "done"
                                size: 28
                                fill: 1
                                weight: 600
                                color: page.setupFailed ? Colours.m3onErrorContainer : Colours.m3onPrimaryContainer
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: Setup.running ? "Working on it" : page.setupFailed ? "That didn't finish" : "All done"
                            font.pixelSize: Appearance.font.size.titleLarge
                            elide: Text.ElideRight
                            animate: true
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                if (Setup.running) {
                                    const s = Setup.steps.find(s => s.state === "running");
                                    return s ? s.title : "Waiting for your password";
                                }
                                if (page.setupFailed)
                                    return "The details below say what went wrong. You can run it again.";
                                return "You can test force feedback on the Wheel test page.";
                            }
                            color: Colours.m3onSurfaceVariant
                            font.pixelSize: Appearance.font.size.bodyMedium
                            wrapMode: Text.Wrap
                            animate: true
                        }
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignTop
                        visible: !Setup.running
                        icon: "close"
                        tooltip: "Close"
                        onClicked: Setup.dismiss()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: Setup.steps

                        ConnectedRect {
                            required property var modelData
                            required property int index

                            first: index === 0
                            last: index === Setup.steps.length - 1
                            implicitHeight: stepRow.implicitHeight + 24
                            color: modelData.state === "running" ? Colours.m3secondaryContainer : Colours.m3surfaceContainerHigh

                            RowLayout {
                                id: stepRow

                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14

                                StateIcon {
                                    status: modelData.state
                                    size: 22
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        color: modelData.state === "pending" || modelData.state === "skipped" ? Colours.m3onSurfaceVariant : modelData.state === "running" ? Colours.m3onSecondaryContainer : Colours.m3onSurface
                                        font.pixelSize: Appearance.font.size.bodyMedium
                                        font.weight: modelData.state === "running" ? Font.Medium : Font.Normal
                                        wrapMode: Text.Wrap
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: modelData.text || ""
                                        color: modelData.state === "failed" ? Colours.m3error : Colours.m3onSurfaceVariant
                                        font.pixelSize: Appearance.font.size.bodySmall
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    visible: Setup.lastError !== "" && !Setup.running
                    implicitHeight: errText.implicitHeight + 28
                    radius: Appearance.rounding.large
                    color: Colours.m3errorContainer

                    StyledText {
                        id: errText

                        anchors.fill: parent
                        anchors.margins: 14
                        text: Setup.lastError
                        color: Colours.m3onErrorContainer
                        font.pixelSize: Appearance.font.size.bodyMedium
                        wrapMode: Text.Wrap
                    }
                }

                // Expandable log
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        TextButton {
                            type: TextButton.Text
                            size: TextButton.Small
                            icon: progress.logOpen ? "expand_less" : "expand_more"
                            text: progress.logOpen ? "Hide details" : "Show details"
                            onClicked: progress.logOpen = !progress.logOpen
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        IconButton {
                            visible: progress.logOpen
                            icon: "content_copy"
                            size: 36
                            tooltip: "Copy log"
                            onClicked: Clipboard.copy(Setup.log, "Log copied")
                        }
                    }

                    StyledRect {
                        id: logBox

                        Layout.fillWidth: true
                        Layout.preferredHeight: progress.logOpen ? Math.min(260, logText.implicitHeight + 24) : 0
                        visible: Layout.preferredHeight > 0.5
                        radius: Appearance.rounding.large
                        color: Colours.m3surfaceContainerLowest
                        clip: true

                        Behavior on Layout.preferredHeight {
                            Anim {
                                type: Anim.DefaultSpatial
                            }
                        }

                        Flickable {
                            id: logFlick

                            anchors.fill: parent
                            anchors.margins: 12
                            contentWidth: width
                            contentHeight: logText.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            ScrollBar.vertical: ScrollBar {}

                            TextEdit {
                                id: logText

                                width: logFlick.width
                                text: Setup.log || "Nothing yet."
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.WrapAnywhere
                                color: Colours.m3onSurfaceVariant
                                selectionColor: Colours.m3primaryContainer
                                selectedTextColor: Colours.m3onPrimaryContainer
                                font.family: Appearance.font.mono
                                font.pixelSize: Appearance.font.size.labelMedium

                                onTextChanged: Qt.callLater(() => logFlick.contentY = Math.max(0, logFlick.contentHeight - logFlick.height))
                            }
                        }
                    }
                }
            }

            Repeater {
                model: System.hints

                HintCard {
                    required property var modelData

                    code: modelData.code
                    text: modelData.text
                }
            }

            // Plain facts about this computer
            Card {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: "This computer"
                    font.pixelSize: Appearance.font.size.titleLarge
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    ListTile {
                        first: true
                        icon: "terminal"
                        title: System.distroName
                        subtitle: System.supported ? "Supported" : System.immutable ? "Read-only system" : "Not recognized"
                    }
                    ListTile {
                        last: true
                        icon: "memory"
                        title: "Kernel " + System.kernel
                        subtitle: "The force feedback driver is built for the kernel you are running."
                    }
                }
            }
        }
    }
}
