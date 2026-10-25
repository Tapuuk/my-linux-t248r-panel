import QtQuick
import QtQuick.Layouts

// Background for an item in a connected list: big corners at the ends of the group, small ones between.
StyledRect {
    property bool first
    property bool last
    readonly property real outer: Appearance.rounding.extraLarge - 8
    readonly property real inner: Appearance.rounding.extraSmall

    Layout.fillWidth: true
    color: Colours.m3surfaceContainerHigh
    topLeftRadius: first ? outer : inner
    topRightRadius: first ? outer : inner
    bottomLeftRadius: last ? outer : inner
    bottomRightRadius: last ? outer : inner
}
