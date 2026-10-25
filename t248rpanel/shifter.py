"""TH8A / TH8S shifters plugged into the PC by USB."""
from evdev import ecodes as e
from PySide6.QtCore import QObject, Property, QTimer, Signal, Slot

from . import devices
from .evsource import EvdevSource
from .wheel import button_number

REVERSE = 8
SEQ_UP, SEQ_DOWN = 9, 10


class Shifter(QObject):
    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.info = None
        self._pressed = set()
        self._src = EvdevSource(self)
        self._src.events.connect(self._on_events)
        self._src.lost.connect(self.poll)
        self._poller = QTimer(self, interval=1500)
        self._poller.timeout.connect(self.poll)
        self._poller.start()
        self.poll()

    @Slot()
    def poll(self):
        found = devices.find_shifters()
        info = found[0] if found else None
        changed = (info or {}).get("event") != (self.info or {}).get("event")
        self.info = info
        if not info:
            self._src.close()
            self._pressed.clear()
        elif info.get("event") and self._src.open(info["event"]):
            try:
                self._pressed = {n for n in map(button_number, self._src.device.active_keys()) if n}
            except OSError:
                pass
        if changed:
            self.changed.emit()

    def _on_events(self, batch):
        for ev in batch:
            if ev.type == e.EV_KEY:
                n = button_number(ev.code)
                if n is None:
                    continue
                if ev.value:
                    self._pressed.add(n)
                else:
                    self._pressed.discard(n)
        self.changed.emit()

    def _gear(self):
        for n in sorted(self._pressed):
            if 1 <= n <= 7:
                return n
            if n == REVERSE:
                return -1
        return 0

    def _sequential(self):
        if SEQ_UP in self._pressed:
            return "up"
        if SEQ_DOWN in self._pressed:
            return "down"
        return ""

    connected = Property(bool, lambda s: s.info is not None, notify=changed)
    model = Property(str, lambda s: (s.info or {}).get("model", ""), notify=changed)
    gear = Property(int, _gear, notify=changed)
    pressed = Property("QVariantList", lambda s: sorted(s._pressed), notify=changed)
    sequential = Property(str, _sequential, notify=changed)
