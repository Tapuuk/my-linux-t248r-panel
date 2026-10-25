import QtQuick

// Round icon button. `checked` (with toggle) fills the icon and squares the shape a little.
StyledRect {
    id: root

    enum Type {
        Standard,
        Filled,
        Tonal,
        Outlined
    }

    property string icon
    property int type: IconButton.Standard
    property int size: 40
    property bool toggle
    property bool checked
    property bool disabled
    property string tooltip
    readonly property bool pressed: stateLayer.pressed
    readonly property alias hovered: stateLayer.containsMouse

    readonly property color contentColour: {
        if (disabled)
            return Qt.alpha(Colours.m3onSurface, 0.38);
        if (toggle && checked)
            return type === IconButton.Filled ? Colours.m3onPrimary : type === IconButton.Tonal ? Colours.m3onSecondary : Colours.m3primary;
        switch (type) {
        case IconButton.Filled: return Colours.m3onPrimary;
        case IconButton.Tonal: return Colours.m3onSecondaryContainer;
        }
        return Colours.m3onSurfaceVariant;
    }

    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: stateLayer.pressed ? Appearance.rounding.small + 2 : (toggle && checked) ? Appearance.rounding.medium + 2 : height / 2
    color: {
        if (disabled)
            return type === IconButton.Standard || type === IconButton.Outlined ? "transparent" : Qt.alpha(Colours.m3onSurface, 0.1);
        if (toggle && checked)
            return type === IconButton.Filled ? Colours.m3primary : type === IconButton.Tonal ? Colours.m3secondary : "transparent";
        switch (type) {
        case IconButton.Filled: return Colours.m3primary;
        case IconButton.Tonal: return Colours.m3secondaryContainer;
        }
        return "transparent";
    }
    border.width: type === IconButton.Outlined ? 1 : 0
    border.color: Colours.m3outlineVariant

    activeFocusOnTab: !disabled
    Accessible.role: Accessible.Button
    Accessible.name: tooltip || icon
    Keys.onSpacePressed: if (!disabled) root.clicked()

    Behavior on radius {
        Anim {
            type: Anim.FastSpatial
        }
    }

    StateLayer {
        id: stateLayer

        disabled: root.disabled
        color: root.contentColour
        onClicked: {
            if (root.toggle)
                root.checked = !root.checked;
            root.clicked();
        }
    }

    FocusRing {
        target: root
    }

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: Math.round(root.size * 0.55)
        color: root.contentColour
        fill: !root.toggle || root.checked ? 1 : 0
    }

    Tip {
        text: root.tooltip
        shown: root.tooltip !== "" && stateLayer.containsMouse && !stateLayer.pressed
    }
}
