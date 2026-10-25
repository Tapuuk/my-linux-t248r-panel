import QtQuick
import QtQuick.Layouts

// Card heading with an optional detail on the right.
RowLayout {
    id: root

    property string text
    property string detail

    Layout.fillWidth: true
    spacing: 12

    StyledText {
        Layout.fillWidth: true
        text: root.text
        font.pixelSize: Appearance.font.size.titleLarge
        elide: Text.ElideRight
    }

    StyledText {
        visible: text !== ""
        Layout.maximumWidth: 380
        text: root.detail
        color: Colours.m3onSurfaceVariant
        font.pixelSize: Appearance.font.size.bodySmall
        elide: Text.ElideRight
    }
}
