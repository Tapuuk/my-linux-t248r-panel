import QtQuick
import QtQuick.Layouts

// Troubleshooting card: icon, title, optional intro and numbered steps, then any extra content.
Card {
    id: root

    property string icon
    property string title
    property string intro
    property var steps: []

    Layout.fillWidth: true
    Layout.fillHeight: true

    RowLayout {
        Layout.fillWidth: true
        spacing: 14

        StyledRect {
            implicitWidth: 44
            implicitHeight: 44
            radius: 16
            color: Colours.m3secondaryContainer

            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 24
                fill: 1
                color: Colours.m3onSecondaryContainer
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: root.title
            font.pixelSize: Appearance.font.size.titleLarge
            wrapMode: Text.Wrap
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.intro !== ""
        text: root.intro
        color: Colours.m3onSurfaceVariant
        font.pixelSize: Appearance.font.size.bodyMedium
        lineHeight: 1.15
        wrapMode: Text.Wrap
    }

    StepList {
        Layout.fillWidth: true
        visible: root.steps.length > 0
        steps: root.steps
    }

    Item {
        Layout.fillHeight: true
    }
}
