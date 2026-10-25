import QtQuick

// NumberAnimation preset with the Material 3 Expressive curves and durations.
NumberAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects,
        EmphasizedDecel,
        EmphasizedAccel
    }

    property int type: Anim.DefaultSpatial

    duration: {
        const d = Appearance.anim.durations;
        switch (type) {
        case Anim.FastSpatial: return d.expressiveFastSpatial;
        case Anim.DefaultSpatial: return d.expressiveDefaultSpatial;
        case Anim.SlowSpatial: return d.expressiveSlowSpatial;
        case Anim.FastEffects: return d.expressiveFastEffects;
        case Anim.DefaultEffects: return d.expressiveDefaultEffects;
        case Anim.SlowEffects: return d.expressiveSlowEffects;
        case Anim.EmphasizedDecel: return d.normal;
        case Anim.EmphasizedAccel: return d.small;
        }
        return [d.small, d.normal, d.large, d.extraLarge][type % 4];
    }
    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        const a = Appearance.anim;
        switch (type) {
        case Anim.FastSpatial: return a.expressiveFastSpatial;
        case Anim.DefaultSpatial: return a.expressiveDefaultSpatial;
        case Anim.SlowSpatial: return a.expressiveSlowSpatial;
        case Anim.FastEffects: return a.expressiveFastEffects;
        case Anim.DefaultEffects: return a.expressiveDefaultEffects;
        case Anim.SlowEffects: return a.expressiveSlowEffects;
        case Anim.EmphasizedDecel: return a.emphasizedDecel;
        case Anim.EmphasizedAccel: return a.emphasizedAccel;
        }
        return type >= Anim.EmphasizedSmall ? a.emphasized : a.standard;
    }
}
