import QtQuick
import QtQuick.Layouts

// Tonal surface container with a column layout inside.
StyledRect {
    id: root

    default property alias content: layout.data
    property real padding: Appearance.padding.extraLarge - 4
    property alias spacing: layout.spacing

    implicitWidth: layout.implicitWidth + padding * 2
    implicitHeight: layout.implicitHeight + padding * 2
    radius: Appearance.rounding.extraLarge
    color: Colours.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Appearance.spacing.large
    }
}
