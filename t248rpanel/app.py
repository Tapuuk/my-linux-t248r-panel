import os
import signal
import sys

# The QML customises every control, which only the Basic style allows.
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from . import APP_ID, APP_NAME, VERSION
from .setup import Setup
from .shifter import Shifter
from .system import System
from .theme import Theme
from .wheel import Wheel

HERE = os.path.dirname(os.path.realpath(__file__))


def _icon():
    for path in (f"/usr/share/icons/hicolor/scalable/apps/{APP_ID}.svg",
                 os.path.join(HERE, "..", "data", f"{APP_ID}.svg")):
        if os.path.exists(path):
            return QIcon(path)
    return QIcon.fromTheme(APP_ID)


def main():
    app = QGuiApplication(sys.argv)
    app.setApplicationName(APP_NAME)
    app.setApplicationVersion(VERSION)
    app.setOrganizationName("Tapuuk")
    app.setDesktopFileName(APP_ID)
    app.setWindowIcon(_icon())
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    for font in ("Rubik.ttf", "MaterialSymbolsRounded.ttf"):
        QFontDatabase.addApplicationFont(os.path.join(HERE, "assets", "fonts", font))

    theme = Theme(app)
    wheel = Wheel(app)
    shifter = Shifter(app)
    system = System(wheel, app)
    setup = Setup(wheel, app)
    setup.hintReceived.connect(system.addHint)
    setup.finished.connect(lambda _ok: system.refresh())

    engine = QQmlApplicationEngine()
    ctx = engine.rootContext()
    for name, obj in (("Theme", theme), ("Wheel", wheel), ("Shifter", shifter), ("System", system), ("Setup", setup)):
        ctx.setContextProperty(name, obj)
    ctx.setContextProperty("AppVersion", VERSION)
    ctx.setContextProperty("AssetsDir", QUrl.fromLocalFile(os.path.join(HERE, "assets") + "/").toString())

    engine.load(QUrl.fromLocalFile(os.path.join(HERE, "qml", "Main.qml")))
    if not engine.rootObjects():
        print("Could not load the interface. Check that the Qt Quick QML modules are installed.", file=sys.stderr)
        return 1
    code = app.exec()
    wheel.stopEffects()
    # QML bindings still reference the backend objects, so the engine has to go first.
    del engine
    return code
