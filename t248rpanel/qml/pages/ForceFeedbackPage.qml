import QtQuick
import QtQuick.Layouts
import "../components"

Page {
    id: page

    signal navigate(int index)

    readonly property var defaults: ({
            range: 900,
            gain: 40000,
            spring_level: 30,
            damper_level: 30,
            friction_level: 30,
            open_mode: 1
        })
    readonly property bool live: Wheel.connected && Wheel.tunablesWritable
    readonly property bool saving: Setup.running && Setup.steps.some(s => s.id === "options")
    property bool keepAwake: Wheel.openMode === 0
    property var pending: ({})

    function current(key: string): real {
        const t = Wheel.tunables;
        return t && t[key] !== undefined ? t[key] : defaults[key];
    }

    // Slider moves arrive many times a second; write to sysfs at most every 120 ms.
    function queue(key: string, value: real): void {
        if (!live)
            return;
        const p = pending;
        p[key] = Math.round(value);
        pending = p;
        applyTimer.restart();
    }

    function values(): var {
        return {
            range: Math.round(rangeRow.value),
            gain: Math.round(gainRow.value),
            spring_level: Math.round(springRow.value),
            damper_level: Math.round(damperRow.value),
            friction_level: Math.round(frictionRow.value),
            open_mode: keepAwake ? 0 : 1
        };
    }

    function reset(): void {
        for (const row of [rangeRow, gainRow, springRow, damperRow, frictionRow]) {
            row.value = defaults[row.key];
            queue(row.key, row.value);
        }
        keepAwake = false;
    }

    title: "Force feedback"
    subtitle: "How the wheel feels in every game. Changes apply right away."

    Timer {
        id: applyTimer

        interval: 120
        onTriggered: {
            const p = page.pending;
            page.pending = {};
            for (const k in p)
                Wheel.setTunable(k, p[k]);
        }
    }

    // Follow changes made elsewhere, except on the slider you are dragging.
    Connections {
        target: Wheel

        function onTunablesChanged(): void {
            for (const row of [rangeRow, gainRow, springRow, damperRow, frictionRow])
                if (!row.dragging && page.pending[row.key] === undefined)
                    row.value = page.current(row.key);
        }
    }

    StyledRect {
        Layout.fillWidth: true
        visible: !page.live
        implicitHeight: noteRow.implicitHeight + 36
        radius: Appearance.rounding.extraLarge
        color: Colours.m3tertiaryContainer

        RowLayout {
            id: noteRow

            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 12
            spacing: 16

            Icon {
                icon: "info"
                size: 24
                fill: 1
                color: Colours.m3onTertiaryContainer
            }
            StyledText {
                Layout.fillWidth: true
                text: !Wheel.connected ? "Plug in your wheel to change these live. You can still pick values and save them as defaults." : "Live changes need the force feedback driver. You can still pick values and save them as defaults."
                color: Colours.m3onTertiaryContainer
                font.pixelSize: Appearance.font.size.bodyMedium
                wrapMode: Text.Wrap
            }
            TextButton {
                visible: Wheel.connected
                type: TextButton.Text
                accent: Colours.m3onTertiaryContainer
                text: "Set up"
                onClicked: page.navigate(0)
            }
        }
    }

    Card {
        Layout.fillWidth: true
        spacing: 12

        CardTitle {
            text: "Wheel"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            SliderRow {
                id: rangeRow

                readonly property string key: "range"

                first: true
                icon: "rotate_right"
                title: "Rotation"
                description: "How far the wheel turns, lock to lock. The wheel's own setting must be on AUTO for this to work. Most games want 900°."
                from: 40
                to: 900
                stepSize: 10
                presets: [180, 360, 540, 900]
                value: page.current(key)
                format: v => Math.round(v) + "°"
                onMoved: v => {
                    value = v;
                    page.queue(key, v);
                }
            }
            SliderRow {
                id: gainRow

                readonly property string key: "gain"

                last: true
                icon: "bolt"
                title: "Strength"
                description: "Overall force feedback strength."
                from: 0
                to: 65535
                stepSize: 655.35
                value: page.current(key)
                format: v => Math.round(v / 65535 * 100) + "%"
                onMoved: v => {
                    value = v;
                    page.queue(key, v);
                }
            }
        }
    }

    Card {
        Layout.fillWidth: true
        spacing: 12

        CardTitle {
            text: "Effects"
            detail: "Used by games that ask for them"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            SliderRow {
                id: springRow

                readonly property string key: "spring_level"

                first: true
                icon: "sync"
                title: "Spring"
                description: "Pull back to the center."
                from: 0
                to: 100
                stepSize: 1
                value: page.current(key)
                format: v => Math.round(v) + "%"
                onMoved: v => {
                    value = v;
                    page.queue(key, v);
                }
            }
            SliderRow {
                id: damperRow

                readonly property string key: "damper_level"

                icon: "speed"
                title: "Damper"
                description: "Resistance that grows the faster you turn."
                from: 0
                to: 100
                stepSize: 1
                value: page.current(key)
                format: v => Math.round(v) + "%"
                onMoved: v => {
                    value = v;
                    page.queue(key, v);
                }
            }
            SliderRow {
                id: frictionRow

                readonly property string key: "friction_level"

                last: true
                icon: "tune"
                title: "Friction"
                description: "Steady resistance, like a heavy steering rack."
                from: 0
                to: 100
                stepSize: 1
                value: page.current(key)
                format: v => Math.round(v) + "%"
                onMoved: v => {
                    value = v;
                    page.queue(key, v);
                }
            }
        }
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: awakeRow.implicitHeight + 44
        radius: Appearance.rounding.extraLarge
        color: Colours.m3surfaceContainer

        Item {
            readonly property real radius: Appearance.rounding.extraLarge

            anchors.fill: parent

            StateLayer {
                onClicked: awake.flip()
            }

            RowLayout {
                id: awakeRow

                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 14

                StyledRect {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 20
                    color: page.keepAwake ? Colours.m3primaryContainer : Colours.m3secondaryContainer

                    Icon {
                        anchors.centerIn: parent
                        icon: "power_settings_new"
                        size: 22
                        fill: 1
                        color: page.keepAwake ? Colours.m3onPrimaryContainer : Colours.m3onSecondaryContainer
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        text: "Keep the wheel awake"
                        font.pixelSize: Appearance.font.size.bodyLarge
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: "Turn this on if buttons work in a game but you feel no force feedback. The wheel stays ready all the time, so its fan keeps running. Takes effect when you save."
                        color: Colours.m3onSurfaceVariant
                        font.pixelSize: Appearance.font.size.bodySmall
                        lineHeight: 1.1
                        wrapMode: Text.Wrap
                    }
                }

                ToggleSwitch {
                    id: awake

                    checked: page.keepAwake
                    onToggled: c => page.keepAwake = c
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 12

        TextButton {
            type: TextButton.Filled
            icon: "save"
            text: "Save as default"
            disabled: Setup.running
            busy: page.saving
            onClicked: Setup.saveDefaults(page.values())
        }
        TextButton {
            type: TextButton.Outlined
            icon: "restart_alt"
            text: "Reset"
            onClicked: page.reset()
        }
        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            text: "Saving makes these the starting values every time you plug in the wheel. It asks for your password once."
            color: Colours.m3onSurfaceVariant
            font.pixelSize: Appearance.font.size.bodySmall
            wrapMode: Text.Wrap
        }
    }
}
