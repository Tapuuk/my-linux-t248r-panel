import QtQuick
import QtQuick.Layouts

// Numbered steps, each number in a small tonal cookie.
ColumnLayout {
    id: root

    property string title
    property var steps: []
    property bool numbered: true

    spacing: 10

    StyledText {
        Layout.fillWidth: true
        visible: root.title !== ""
        text: root.title
        font.pixelSize: Appearance.font.size.titleMedium
        font.weight: Font.Medium
    }

    Repeater {
        model: root.steps

        RowLayout {
            id: stepRow

            required property string modelData
            required property int index

            Layout.fillWidth: true
            spacing: 12

            Item {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 28
                implicitHeight: 28

                PolarShape {
                    anchors.fill: parent
                    visible: root.numbered
                    from: [6, 0.08]
                    samples: 60
                    color: Colours.m3secondaryContainer
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: root.numbered
                    text: stepRow.index + 1
                    color: Colours.m3onSecondaryContainer
                    font.pixelSize: Appearance.font.size.labelLarge
                    font.weight: Font.DemiBold
                }
                StyledRect {
                    anchors.centerIn: parent
                    visible: !root.numbered
                    width: 8
                    height: 8
                    radius: 4
                    color: Colours.m3primary
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: stepRow.modelData
                color: Colours.m3onSurfaceVariant
                font.pixelSize: Appearance.font.size.bodyMedium
                lineHeight: 1.15
                wrapMode: Text.Wrap
            }
        }
    }
}
