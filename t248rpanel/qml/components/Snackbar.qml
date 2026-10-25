import QtQuick

// Short message at the bottom of the window.
StyledRect {
    id: root

    property bool shown
    property bool error

    function show(message: string, isError: bool): void {
        label.text = message;
        error = isError;
        shown = true;
        hideTimer.restart();
    }

    anchors.horizontalCenter: parent.horizontalCenter
    y: shown ? parent.height - height - 24 : parent.height + 8
    z: 1000
    width: Math.min(parent.width - 48, row.implicitWidth + 40)
    height: 52
    radius: Appearance.rounding.large
    color: Colours.m3inverseSurface
    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on y {
        Anim {
            type: Anim.FastSpatial
        }
    }
    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Timer {
        id: hideTimer

        interval: 3200
        onTriggered: root.shown = false
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 12

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            icon: root.error ? "error" : "check_circle"
            size: 20
            fill: 1
            color: root.error ? Colours.m3errorContainer : Colours.m3inversePrimary
        }

        StyledText {
            id: label

            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.parent.width - 140)
            color: Colours.m3inverseOnSurface
            font.pixelSize: Appearance.font.size.bodyMedium
            elide: Text.ElideRight
        }
    }
}
