"""Non-blocking evdev reading on the Qt event loop."""
import evdev
from PySide6.QtCore import QObject, QSocketNotifier, Signal


class EvdevSource(QObject):
    events = Signal(list)
    lost = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.device = None
        self.path = None
        self._notifier = None

    def open(self, path):
        if path == self.path and self.device:
            return True
        self.close()
        try:
            self.device = evdev.InputDevice(path)
        except OSError:
            return False
        self.path = path
        self._notifier = QSocketNotifier(self.device.fd, QSocketNotifier.Type.Read, self)
        self._notifier.activated.connect(self._read)
        return True

    def close(self):
        if self._notifier:
            self._notifier.setEnabled(False)
            self._notifier.deleteLater()
            self._notifier = None
        if self.device:
            try:
                self.device.close()
            except OSError:
                pass
        self.device = None
        self.path = None

    def writable(self):
        try:
            return bool(self.device) and self.device.fd >= 0 and _is_rw(self.device.fd)
        except OSError:
            return False

    def _read(self):
        try:
            batch = list(self.device.read())
        except BlockingIOError:
            return
        except OSError:
            self.close()
            self.lost.emit()
            return
        if batch:
            self.events.emit(batch)


def _is_rw(fd):
    import fcntl
    import os
    return fcntl.fcntl(fd, fcntl.F_GETFL) & os.O_ACCMODE == os.O_RDWR
