import QtQuick
import QtQuick.Controls.Basic as C

C.ScrollBar {
    id: root

    padding: 4
    minimumSize: 0.08

    contentItem: StyledRect {
        implicitWidth: root.pressed ? 8 : 6
        radius: width / 2
        color: root.pressed ? Colours.m3onSurfaceVariant : Colours.m3outline
        opacity: root.policy === C.ScrollBar.AlwaysOn || (root.active && root.size < 1) ? (root.hovered || root.pressed ? 0.9 : 0.6) : 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on implicitWidth {
            Anim {
                type: Anim.FastSpatial
            }
        }
    }

    background: Item {}
}
