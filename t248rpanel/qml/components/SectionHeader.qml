import QtQuick
import QtQuick.Layouts

StyledText {
    Layout.fillWidth: true
    Layout.leftMargin: Appearance.padding.small
    color: Colours.m3onSurfaceVariant
    font.pixelSize: Appearance.font.size.labelLarge
    font.weight: Font.Medium
    elide: Text.ElideRight
}
