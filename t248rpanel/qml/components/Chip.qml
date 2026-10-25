import QtQuick

// Small status pill with an optional leading icon.
StyledRect {
    id: root

    property string icon
    property string text
    property color tint: Colours.m3secondaryContainer
    property color onTint: Colours.m3onSecondaryContainer

    implicitHeight: 32
    implicitWidth: row.implicitWidth + (icon ? 24 : 28)
    radius: height / 2
    color: tint

    Row {
        id: row

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.icon ? -2 : 0
        spacing: 6

        Icon {
            visible: root.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            icon: root.icon
            size: 18
            fill: 1
            color: root.onTint
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.onTint
            font.pixelSize: Appearance.font.size.labelLarge
            font.weight: Font.Medium
        }
    }
}
