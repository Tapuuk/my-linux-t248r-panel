import QtQuick

// A Material Symbols Rounded glyph. `fill` animates between outlined (0) and filled (1).
StyledText {
    id: root

    property string icon
    property real fill: 0
    property int size: 24
    property int weight: 400
    property int grade: Colours.dark ? -25 : 0

    text: Icons.glyph(icon)
    font.family: Appearance.font.icons
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": Math.round(root.fill * 100) / 100,
            "wght": root.weight,
            "GRAD": root.grade,
            "opsz": Math.max(20, Math.min(48, root.size))
        })
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on fill {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
