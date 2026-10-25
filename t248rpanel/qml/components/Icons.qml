pragma Singleton

import QtQuick
import "iconmap.js" as IconMap

QtObject {
    // The icon font only has the glyphs listed in the map. Unknown names fall back to the
    // font's ligatures, which render nothing if the glyph isn't in the subset.
    function glyph(name: string): string {
        const cp = IconMap.codepoints[name];
        return cp ? String.fromCodePoint(cp) : name;
    }
}
