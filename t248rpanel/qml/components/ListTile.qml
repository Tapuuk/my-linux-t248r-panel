import QtQuick
import QtQuick.Layouts

// A row in a connected list: big outer corners on the first and last item, small ones between.
ConnectedRect {
    id: root

    property string icon
    property color iconColour: Colours.m3onSecondaryContainer
    property color iconBackground: Colours.m3secondaryContainer
    property real iconFill: 1
    property string title
    property string subtitle
    property bool clickable
    default property alias trailing: trailingRow.data

    signal clicked

    implicitHeight: Math.max(56, row.implicitHeight + Appearance.padding.medium * 2 + 2)

    StateLayer {
        visible: root.clickable
        onClicked: root.clicked()
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Appearance.padding.large
        anchors.rightMargin: Appearance.padding.large
        spacing: Appearance.spacing.large

        StyledRect {
            visible: root.icon !== ""
            implicitWidth: 40
            implicitHeight: 40
            radius: width / 2
            color: root.iconBackground

            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 22
                fill: root.iconFill
                color: root.iconColour
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: Appearance.font.size.bodyLarge
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtitle
                color: Colours.m3onSurfaceVariant
                font.pixelSize: Appearance.font.size.bodySmall
                wrapMode: Text.Wrap
            }
        }

        RowLayout {
            id: trailingRow

            spacing: Appearance.spacing.small
        }
    }
}
