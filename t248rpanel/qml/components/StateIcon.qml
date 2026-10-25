import QtQuick

// Icon for a check or step state, with a small loading indicator while running.
Item {
    id: root

    property string status: "pending"   // ok done missing warn error failed skipped pending running
    property int size: 24

    readonly property string icon: {
        switch (status) {
        case "ok":
        case "done": return "check_circle";
        case "missing": return "cancel";
        case "warn": return "warning";
        case "error":
        case "failed": return "error";
        case "skipped": return "remove";
        }
        return "circle";
    }
    readonly property color colour: {
        switch (status) {
        case "ok":
        case "done": return Colours.m3primary;
        case "missing": return Colours.m3onSurfaceVariant;
        case "warn": return Colours.m3tertiary;
        case "error":
        case "failed": return Colours.m3error;
        }
        return Colours.m3outline;
    }

    implicitWidth: size
    implicitHeight: size

    Icon {
        anchors.centerIn: parent
        visible: root.status !== "running"
        icon: root.icon
        size: root.size
        fill: root.status === "pending" || root.status === "skipped" ? 0 : 1
        color: root.colour
        scale: visible ? 1 : 0.5

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }

    LoadingIndicator {
        anchors.centerIn: parent
        visible: root.status === "running"
        running: visible
        size: root.size + 4
    }
}
