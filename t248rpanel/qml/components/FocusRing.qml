import QtQuick

// Keyboard focus outline that follows the target's (possibly animated) radius.
Rectangle {
    required property Item target

    anchors.fill: parent
    anchors.margins: -3
    radius: (target.radius ?? 0) + 3
    color: "transparent"
    border.width: 2
    border.color: Colours.m3secondary
    visible: target.activeFocus
}
