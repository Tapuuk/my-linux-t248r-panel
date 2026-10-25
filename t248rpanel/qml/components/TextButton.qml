import QtQuick

// Material 3 Expressive button. A pill at rest that squares off while pressed.
StyledRect {
    id: root

    enum Type {
        Filled,
        Tonal,
        Outlined,
        Text,
        Danger,
        DangerTonal
    }

    enum Size {
        Small,
        Medium,
        Large
    }

    property string text
    property string icon
    property int type: TextButton.Filled
    property int size: TextButton.Medium
    property bool busy
    property bool disabled
    // Text-type buttons on tinted surfaces need the surface's own on-colour.
    property color accent: Colours.m3primary
    property alias hovered: stateLayer.containsMouse
    readonly property bool pressed: stateLayer.pressed

    readonly property real baseHeight: size === TextButton.Large ? 64 : size === TextButton.Small ? 36 : 44
    readonly property real hPad: size === TextButton.Large ? 32 : size === TextButton.Small ? 16 : 22
    readonly property int labelSize: size === TextButton.Large ? Appearance.font.size.titleMedium : size === TextButton.Small ? Appearance.font.size.labelLarge : Appearance.font.size.labelLarge + 1
    readonly property int iconSize: size === TextButton.Large ? 26 : size === TextButton.Small ? 18 : 20

    readonly property color containerColour: {
        switch (type) {
        case TextButton.Filled: return Colours.m3primary;
        case TextButton.Tonal: return Colours.m3secondaryContainer;
        case TextButton.Danger: return Colours.m3error;
        case TextButton.DangerTonal: return Colours.m3errorContainer;
        }
        return "transparent";
    }
    readonly property color contentColour: {
        if (disabled)
            return Qt.alpha(Colours.m3onSurface, 0.38);
        switch (type) {
        case TextButton.Filled: return Colours.m3onPrimary;
        case TextButton.Tonal: return Colours.m3onSecondaryContainer;
        case TextButton.Outlined: return Colours.m3onSurfaceVariant;
        case TextButton.Danger: return Colours.m3onError;
        case TextButton.DangerTonal: return Colours.m3onErrorContainer;
        }
        return root.accent;
    }

    signal clicked

    implicitHeight: baseHeight
    implicitWidth: row.implicitWidth + hPad * 2
    radius: stateLayer.pressed ? (size === TextButton.Large ? Appearance.rounding.large : Appearance.rounding.small + 2) : height / 2
    color: disabled && type !== TextButton.Text && type !== TextButton.Outlined ? Qt.alpha(Colours.m3onSurface, 0.1) : containerColour
    border.width: type === TextButton.Outlined ? 1 : 0
    border.color: disabled ? Qt.alpha(Colours.m3onSurface, 0.12) : Colours.m3outlineVariant

    activeFocusOnTab: !disabled
    Accessible.role: Accessible.Button
    Accessible.name: text
    Keys.onSpacePressed: if (!disabled) root.clicked()
    Keys.onReturnPressed: if (!disabled) root.clicked()

    Behavior on radius {
        Anim {
            type: Anim.FastSpatial
        }
    }

    StateLayer {
        id: stateLayer

        disabled: root.disabled || root.busy
        color: root.contentColour
        onClicked: root.clicked()
    }

    FocusRing {
        target: root
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: root.size === TextButton.Large ? 12 : 8

        Item {
            visible: root.icon !== "" || root.busy
            width: root.iconSize
            height: root.iconSize
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                visible: !root.busy
                icon: root.icon
                size: root.iconSize
                fill: 1
                color: root.contentColour
            }

            LoadingIndicator {
                anchors.centerIn: parent
                visible: root.busy
                running: root.busy
                size: root.iconSize + 4
                color: root.contentColour
            }
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.contentColour
            font.pixelSize: root.labelSize
            font.weight: Font.Medium
        }
    }
}
