import QtQuick
import QtQuick.Layouts

// A shell command in monospace with a copy button.
StyledRect {
    id: root

    property string command
    property color tint: Colours.m3surfaceContainerLowest
    property color onTint: Colours.m3onSurface

    Layout.fillWidth: true
    implicitHeight: Math.max(48, text.implicitHeight + 20)
    radius: Appearance.rounding.large
    color: tint

    StyledText {
        id: text

        anchors.left: parent.left
        anchors.right: copy.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Appearance.padding.large
        anchors.rightMargin: Appearance.padding.small
        text: root.command
        color: root.onTint
        font.family: Appearance.font.mono
        font.pixelSize: Appearance.font.size.bodyMedium
        wrapMode: Text.WrapAnywhere
    }

    IconButton {
        id: copy

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon: "content_copy"
        size: 40
        tooltip: "Copy"
        onClicked: Clipboard.copy(root.command, "Command copied")
    }
}
