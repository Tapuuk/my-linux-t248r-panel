pragma Singleton

import QtQuick

// Material 3 colour roles from Theme.colors (the user's Caelestia scheme or the built-in one).
// Every role is a typed colour with a fallback, so a missing key never breaks a binding.
QtObject {
    id: root

    readonly property var source: typeof Theme !== "undefined" && Theme ? Theme.colors : ({})
    readonly property bool dark: typeof Theme !== "undefined" && Theme ? Theme.dark : true

    readonly property color m3primary: pick("primary", "#ffb4a9")
    readonly property color m3onPrimary: pick("onPrimary", "#690003")
    readonly property color m3primaryContainer: pick("primaryContainer", "#930007")
    readonly property color m3onPrimaryContainer: pick("onPrimaryContainer", "#ffdad5")
    readonly property color m3secondary: pick("secondary", "#e7bdb7")
    readonly property color m3onSecondary: pick("onSecondary", "#442926")
    readonly property color m3secondaryContainer: pick("secondaryContainer", "#5d3f3b")
    readonly property color m3onSecondaryContainer: pick("onSecondaryContainer", "#ffdad5")
    readonly property color m3tertiary: pick("tertiary", "#dfc38c")
    readonly property color m3onTertiary: pick("onTertiary", "#3e2e04")
    readonly property color m3tertiaryContainer: pick("tertiaryContainer", "#574419")
    readonly property color m3onTertiaryContainer: pick("onTertiaryContainer", "#fcdfa6")
    readonly property color m3error: pick("error", "#ffb4ab")
    readonly property color m3onError: pick("onError", "#690005")
    readonly property color m3errorContainer: pick("errorContainer", "#93000a")
    readonly property color m3onErrorContainer: pick("onErrorContainer", "#ffdad6")
    readonly property color m3surface: pick("surface", "#1a1110")
    readonly property color m3onSurface: pick("onSurface", "#f1dfdc")
    readonly property color m3surfaceVariant: pick("surfaceVariant", "#534341")
    readonly property color m3onSurfaceVariant: pick("onSurfaceVariant", "#d8c2be")
    readonly property color m3surfaceContainerLowest: pick("surfaceContainerLowest", "#140c0b")
    readonly property color m3surfaceContainerLow: pick("surfaceContainerLow", "#231918")
    readonly property color m3surfaceContainer: pick("surfaceContainer", "#271d1c")
    readonly property color m3surfaceContainerHigh: pick("surfaceContainerHigh", "#322826")
    readonly property color m3surfaceContainerHighest: pick("surfaceContainerHighest", "#3d3231")
    readonly property color m3surfaceBright: pick("surfaceBright", "#423735")
    readonly property color m3surfaceDim: pick("surfaceDim", "#1a1110")
    readonly property color m3outline: pick("outline", "#a08c89")
    readonly property color m3outlineVariant: pick("outlineVariant", "#534341")
    readonly property color m3inverseSurface: pick("inverseSurface", "#f1dfdc")
    readonly property color m3inverseOnSurface: pick("inverseOnSurface", "#392e2c")
    readonly property color m3inversePrimary: pick("inversePrimary", "#ae2f24")
    readonly property color m3shadow: pick("shadow", "#000000")
    readonly property color m3scrim: pick("scrim", "#000000")

    function pick(key, fallback) {
        const v = root.source ? root.source[key] : undefined;
        return v ? v : fallback;
    }

    // Blend two colours; t = 0 gives a, t = 1 gives b.
    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }
}
