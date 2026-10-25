import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as C

// Scrolling page with a large title. Content is centred and capped in width.
Item {
    id: root

    property string title
    property string subtitle
    property real maxContentWidth: 1040
    default property alias content: column.data
    readonly property alias flickable: flick
    readonly property real contentWidth: column.width

    Flickable {
        id: flick

        anchors.fill: parent
        contentWidth: width
        contentHeight: inner.implicitHeight + 64
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        C.ScrollBar.vertical: ScrollBar {}

        Item {
            id: inner

            x: Math.max(32, (flick.width - width) / 2)
            y: 28
            width: Math.min(root.maxContentWidth, flick.width - 64)
            implicitHeight: head.implicitHeight + column.implicitHeight + 28

            ColumnLayout {
                id: head

                width: parent.width
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: Appearance.font.size.headlineLarge
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.subtitle
                    color: Colours.m3onSurfaceVariant
                    font.pixelSize: Appearance.font.size.bodyLarge
                    wrapMode: Text.Wrap
                }
            }

            ColumnLayout {
                id: column

                anchors.top: head.bottom
                anchors.topMargin: 28
                width: parent.width
                spacing: Appearance.spacing.large
            }
        }
    }
}
