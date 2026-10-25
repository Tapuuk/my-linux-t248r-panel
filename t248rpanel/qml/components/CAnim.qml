import QtQuick

// Colour changes, including a whole scheme switch, fade with the slow effects curve.
ColorAnimation {
    duration: Appearance.anim.durations.expressiveSlowEffects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.anim.expressiveSlowEffects
}
