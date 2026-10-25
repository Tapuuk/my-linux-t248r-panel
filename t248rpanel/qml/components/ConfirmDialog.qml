import QtQuick
import QtQuick.Layouts

// Modal dialog over a scrim. Springs in from slightly smaller.
Item {
    id: root

    property string icon: "warning"
    property string title
    property string text
    property string confirmText: "Confirm"
    property string cancelText: "Cancel"
    property bool danger
    property bool shown

    signal accepted

    function open(): void {
        shown = true;
        cancelBtn.forceActiveFocus();
    }

    function close(): void {
        shown = false;
    }

    anchors.fill: parent
    z: 900
    visible: scrim.opacity > 0

    Keys.onEscapePressed: close()

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: Colours.m3scrim
        opacity: root.shown ? 0.45 : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    StyledRect {
        id: panel

        anchors.centerIn: parent
        width: Math.min(440, root.width - 48)
        height: col.implicitHeight + 48
        radius: Appearance.rounding.extraLarge
        color: Colours.m3surfaceContainerHigh
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.88

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: col

            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Icon {
                Layout.alignment: Qt.AlignHCenter
                icon: root.icon
                size: 28
                fill: 1
                color: root.danger ? Colours.m3error : Colours.m3secondary
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.title
                font.pixelSize: Appearance.font.size.headlineSmall
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                text: root.text
                color: Colours.m3onSurfaceVariant
                font.pixelSize: Appearance.font.size.bodyMedium
                lineHeight: 1.15
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: 8
                spacing: 8

                TextButton {
                    id: cancelBtn

                    type: TextButton.Text
                    text: root.cancelText
                    onClicked: root.close()
                }

                TextButton {
                    type: root.danger ? TextButton.Danger : TextButton.Filled
                    text: root.confirmText
                    onClicked: {
                        root.close();
                        root.accepted();
                    }
                }
            }
        }
    }
}
