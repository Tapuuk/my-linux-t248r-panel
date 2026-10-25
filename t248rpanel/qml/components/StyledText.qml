import QtQuick

Text {
    id: root

    // Cross-fade when the text changes, for values that update now and then.
    property bool animate: false

    color: Colours.m3onSurface
    font.family: Appearance.font.family
    font.pixelSize: Appearance.font.size.bodyMedium
    textFormat: Text.PlainText
    wrapMode: Text.NoWrap

    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.FastEffects
            }
            PropertyAction {}
            Anim {
                target: root
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }
}
