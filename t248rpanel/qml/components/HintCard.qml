import QtQuick
import QtQuick.Layouts

// A warning from System.hints, shown as a tonal card. Shell commands found in the text get a copy box.
StyledRect {
    id: root

    property string code
    property string text

    readonly property bool serious: code === "immutable" || code === "unsupported" || code === "no-network"
    readonly property color tint: serious ? Colours.m3errorContainer : Colours.m3tertiaryContainer
    readonly property color onTint: serious ? Colours.m3onErrorContainer : Colours.m3onTertiaryContainer

    readonly property string heading: {
        switch (code) {
        case "secureboot": return "Secure Boot needs one more step";
        case "reboot": return "Restart to finish";
        case "immutable": return "Read-only system";
        case "unsupported": return "Distro not recognized";
        case "no-network": return "No internet connection";
        }
        return "Heads up";
    }
    readonly property string icon: {
        switch (code) {
        case "secureboot": return "shield";
        case "reboot": return "restart_alt";
        case "immutable": return "lock";
        case "unsupported": return "info";
        }
        return "warning";
    }
    readonly property var commands: {
        const out = [];
        const re = /(sudo\s.+?)(?=\s+then\b|\s+and\b|\.(?:\s|$)|$)/g;
        let m;
        while ((m = re.exec(root.text)) !== null)
            out.push(m[1].trim());
        return out;
    }

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 40
    radius: Appearance.rounding.extraLarge
    color: tint

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        StyledRect {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 40
            implicitHeight: 40
            radius: 14
            color: Qt.alpha(root.onTint, 0.12)

            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 22
                fill: 1
                color: root.onTint
            }
        }

        ColumnLayout {
            id: col

            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: root.heading
                color: root.onTint
                font.pixelSize: Appearance.font.size.titleMedium
                font.weight: Font.Medium
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                text: root.text
                color: root.onTint
                opacity: 0.9
                font.pixelSize: Appearance.font.size.bodyMedium
                lineHeight: 1.15
                wrapMode: Text.Wrap
            }

            Repeater {
                model: root.commands

                CommandBox {
                    required property string modelData

                    Layout.topMargin: 4
                    command: modelData
                    tint: Qt.alpha(Colours.m3surfaceContainerLowest, Colours.dark ? 0.55 : 0.75)
                }
            }
        }
    }
}
