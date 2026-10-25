pragma Singleton

import QtQuick

// Design tokens, matching the Caelestia shell's defaults (Material 3 Expressive).
QtObject {
    readonly property QtObject rounding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
        readonly property int full: 1000
    }

    readonly property QtObject spacing: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
    }

    readonly property QtObject padding: QtObject {
        readonly property int extraSmall: 4
        readonly property int small: 8
        readonly property int medium: 12
        readonly property int large: 16
        readonly property int largeIncreased: 20
        readonly property int extraLarge: 28
        readonly property int extraLargeIncreased: 32
        readonly property int extraExtraLarge: 48
    }

    readonly property QtObject font: QtObject {
        readonly property string family: "Rubik"
        readonly property string mono: "monospace"
        readonly property string icons: "Material Symbols Rounded"

        readonly property QtObject size: QtObject {
            readonly property int labelSmall: 11
            readonly property int labelMedium: 12
            readonly property int labelLarge: 14
            readonly property int bodySmall: 13
            readonly property int bodyMedium: 14
            readonly property int bodyLarge: 16
            readonly property int titleSmall: 15
            readonly property int titleMedium: 17
            readonly property int titleLarge: 22
            readonly property int headlineSmall: 24
            readonly property int headlineMedium: 28
            readonly property int headlineLarge: 32
            readonly property int displaySmall: 40
            readonly property int displayMedium: 52
        }
    }

    readonly property QtObject anim: QtObject {
        readonly property var standard: [0.2, 0, 0, 1, 1, 1]
        readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property var emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property var expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
        readonly property var expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
        readonly property var expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        readonly property var expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]

        readonly property QtObject durations: QtObject {
            readonly property int small: 200
            readonly property int normal: 400
            readonly property int large: 600
            readonly property int extraLarge: 1000
            readonly property int expressiveFastSpatial: 350
            readonly property int expressiveDefaultSpatial: 500
            readonly property int expressiveSlowSpatial: 650
            readonly property int expressiveFastEffects: 150
            readonly property int expressiveDefaultEffects: 200
            readonly property int expressiveSlowEffects: 300
        }
    }
}
