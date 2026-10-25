"""Material 3 colours. Follows the user's Caelestia scheme live when there is one."""
import json
import os

from PySide6.QtCore import QFileSystemWatcher, QObject, Property, Qt, QTimer, Signal
from PySide6.QtGui import QGuiApplication

# Built from a deep red seed, close to the T248R's accent stripe.
DARK = {
    "primary": "ffb4a9", "onPrimary": "690003", "primaryContainer": "930007", "onPrimaryContainer": "ffdad5",
    "secondary": "e7bdb7", "onSecondary": "442926", "secondaryContainer": "5d3f3b", "onSecondaryContainer": "ffdad5",
    "tertiary": "dfc38c", "onTertiary": "3e2e04", "tertiaryContainer": "574419", "onTertiaryContainer": "fcdfa6",
    "error": "ffb4ab", "onError": "690005", "errorContainer": "93000a", "onErrorContainer": "ffdad6",
    "surface": "1a1110", "onSurface": "f1dfdc", "surfaceVariant": "534341", "onSurfaceVariant": "d8c2be",
    "surfaceDim": "1a1110", "surfaceBright": "423735",
    "surfaceContainerLowest": "140c0b", "surfaceContainerLow": "231918", "surfaceContainer": "271d1c",
    "surfaceContainerHigh": "322826", "surfaceContainerHighest": "3d3231",
    "outline": "a08c89", "outlineVariant": "534341", "inverseSurface": "f1dfdc", "inverseOnSurface": "392e2c",
    "inversePrimary": "ae2f24", "shadow": "000000", "scrim": "000000",
}

LIGHT = {
    "primary": "ae2f24", "onPrimary": "ffffff", "primaryContainer": "ffdad5", "onPrimaryContainer": "410001",
    "secondary": "775652", "onSecondary": "ffffff", "secondaryContainer": "ffdad5", "onSecondaryContainer": "2c1512",
    "tertiary": "705c2e", "onTertiary": "ffffff", "tertiaryContainer": "fcdfa6", "onTertiaryContainer": "261a00",
    "error": "ba1a1a", "onError": "ffffff", "errorContainer": "ffdad6", "onErrorContainer": "410002",
    "surface": "fff8f6", "onSurface": "231918", "surfaceVariant": "f5ddd9", "onSurfaceVariant": "534341",
    "surfaceDim": "e8d6d3", "surfaceBright": "fff8f6",
    "surfaceContainerLowest": "ffffff", "surfaceContainerLow": "fff0ee", "surfaceContainer": "fceae7",
    "surfaceContainerHigh": "f6e4e1", "surfaceContainerHighest": "f1dfdc",
    "outline": "857370", "outlineVariant": "d8c2be", "inverseSurface": "392e2c", "inverseOnSurface": "ffedea",
    "inversePrimary": "ffb4a9", "shadow": "000000", "scrim": "000000",
}


def _caelestia_scheme_path():
    state = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    return os.path.join(state, "caelestia", "scheme.json")


class Theme(QObject):
    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._colors = {}
        self._dark = True
        self._source = "builtin"
        self._path = _caelestia_scheme_path()

        # Caelestia replaces the file on every wallpaper change, so watch the folder too.
        self._watcher = QFileSystemWatcher(self)
        self._watcher.fileChanged.connect(self._schedule)
        self._watcher.directoryChanged.connect(self._schedule)
        self._debounce = QTimer(self, singleShot=True, interval=150)
        self._debounce.timeout.connect(self.reload)
        QGuiApplication.styleHints().colorSchemeChanged.connect(self._schedule)
        self.reload()

    def _schedule(self, *_):
        self._debounce.start()

    def _system_prefers_dark(self):
        return QGuiApplication.styleHints().colorScheme() != Qt.ColorScheme.Light

    def reload(self):
        scheme = None
        try:
            with open(self._path) as f:
                scheme = json.load(f)
        except (OSError, ValueError):
            pass

        if scheme and isinstance(scheme.get("colours"), dict):
            dark = scheme.get("mode", "dark") != "light"
            colors = dict(DARK if dark else LIGHT)
            colors.update({k: v for k, v in scheme["colours"].items() if isinstance(v, str)})
            source = "caelestia"
        else:
            dark = self._system_prefers_dark()
            colors = dict(DARK if dark else LIGHT)
            source = "builtin"

        self._colors = {k: "#" + v.lstrip("#") for k, v in colors.items()}
        self._dark, self._source = dark, source
        self._rewatch()
        self.changed.emit()

    def _rewatch(self):
        folder = os.path.dirname(self._path)
        for p in (folder, self._path):
            if os.path.exists(p) and p not in self._watcher.files() + self._watcher.directories():
                self._watcher.addPath(p)

    colors = Property("QVariantMap", lambda self: self._colors, notify=changed)
    dark = Property(bool, lambda self: self._dark, notify=changed)
    source = Property(str, lambda self: self._source, notify=changed)
