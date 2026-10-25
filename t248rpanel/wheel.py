"""The T248R: connection state, live input, tunables and force feedback tests."""
import os

from evdev import ecodes as e, ff
from PySide6.QtCore import QObject, Property, QTimer, Signal, Slot

from . import devices, usbctl
from .evsource import EvdevSource

OPTIONS_FILE = "/etc/modprobe.d/my-linux-t248r-panel.conf"
PEDALS = {e.ABS_RZ: "throttle", e.ABS_Y: "brake", e.ABS_THROTTLE: "clutch"}
PEDAL_MAX = 1023
STEER_MAX = 65535

# Thrustmaster button number -> encoder slot (E1..E4)
ENCODER_SLOT = {11: 1, 14: 1, 15: 1, 12: 2, 16: 2, 17: 2, 24: 3, 18: 3, 19: 3, 25: 4, 20: 4, 21: 4}


def button_number(code):
    if e.BTN_TRIGGER <= code <= e.BTN_DEAD:
        return code - e.BTN_TRIGGER + 1
    if e.BTN_TRIGGER_HAPPY1 <= code <= e.BTN_TRIGGER_HAPPY40:
        return code - e.BTN_TRIGGER_HAPPY1 + 17
    return None


class Wheel(QObject):
    statusChanged = Signal()
    inputChanged = Signal()
    tunablesChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self.info = None
        self._firmware = ""
        self._fw_key = None
        self._tunables = {}
        self._reset_input()

        self._src = EvdevSource(self)
        self._src.events.connect(self._on_events)
        self._src.lost.connect(self.poll)

        # Input arrives far faster than the screen refreshes; publish at most ~60 times a second.
        self._publish = QTimer(self, singleShot=True, interval=16)
        self._publish.timeout.connect(self.inputChanged)

        self._effects = []
        self._stop_timer = QTimer(self, singleShot=True)
        self._stop_timer.timeout.connect(self.stopEffects)

        self._poller = QTimer(self, interval=1500)
        self._poller.timeout.connect(self.poll)
        self._poller.start()
        self.poll()

    def _reset_input(self):
        self._steer = 0.0
        self._pedals = {"throttle": 0.0, "brake": 0.0, "clutch": 0.0}
        self._pressed = set()
        self._hat = [0, 0]
        self._slot = 0

    @Slot()
    def poll(self):
        info = devices.find_wheel()
        old = self.info
        self.info = info
        if not info:
            if old:
                self._src.close()
                self._reset_input()
                self._firmware, self._fw_key, self._tunables = "", None, {}
                self.statusChanged.emit()
                self.inputChanged.emit()
                self.tunablesChanged.emit()
            return

        if info.get("event") and info["event"] != self._src.path:
            if self._src.open(info["event"]):
                self._load_initial()

        key = (info["busnum"], info["devnum"])
        if key != self._fw_key:
            self._fw_key = key
            self._firmware = self._query_firmware(info)

        tunables = devices.read_tunables(info)
        if tunables != self._tunables:
            self._tunables = tunables
            self.tunablesChanged.emit()

        if old is None or any(old.get(k) != info.get(k) for k in ("pid", "driver", "event", "devnum")):
            self.statusChanged.emit()

    def _query_firmware(self, info):
        try:
            return usbctl.read_firmware(usbctl.node_path(info["busnum"], info["devnum"])) or ""
        except OSError:
            # No write access to the USB node until the panel's udev rule is installed.
            return ""

    def _load_initial(self):
        dev = self._src.device
        try:
            for code, name in PEDALS.items():
                self._pedals[name] = self._pedal(dev.absinfo(code).value)
            self._steer = self._steering(dev.absinfo(e.ABS_X).value)
            self._pressed = {n for n in map(button_number, dev.active_keys()) if n}
        except OSError:
            pass
        self.inputChanged.emit()

    @staticmethod
    def _pedal(raw):
        return max(0.0, min(1.0, (PEDAL_MAX - raw) / PEDAL_MAX))

    @staticmethod
    def _steering(raw):
        return max(-1.0, min(1.0, (raw - STEER_MAX / 2) / (STEER_MAX / 2)))

    def _on_events(self, batch):
        for ev in batch:
            if ev.type == e.EV_ABS:
                if ev.code == e.ABS_X:
                    self._steer = self._steering(ev.value)
                elif ev.code in PEDALS:
                    self._pedals[PEDALS[ev.code]] = self._pedal(ev.value)
                elif ev.code == e.ABS_HAT0X:
                    self._hat[0] = ev.value
                elif ev.code == e.ABS_HAT0Y:
                    self._hat[1] = ev.value
            elif ev.type == e.EV_KEY:
                n = button_number(ev.code)
                if n is None:
                    continue
                if ev.value:
                    self._pressed.add(n)
                    self._slot = ENCODER_SLOT.get(n, self._slot)
                else:
                    self._pressed.discard(n)
        if not self._publish.isActive():
            self._publish.start()

    # --- force feedback tests -------------------------------------------------------------

    def _ffb_device(self):
        dev = self._src.device
        if not dev or not self.ffbReady:
            return None
        return dev

    @Slot(str, float)
    def playEffect(self, kind, strength):
        dev = self._ffb_device()
        if not dev:
            return
        self.stopEffects()
        strength = max(0.0, min(1.0, strength))
        level = int(0x7FFF * strength)
        length = 1500
        no_env = ff.Envelope(0, 0, 0, 0)

        if kind in ("left", "right"):
            # Direction 0x4000 is along the wheel's axis. Measured on the T248R: a positive level turns it left.
            body = ff.EffectType(ff_constant_effect=ff.Constant(level if kind == "left" else -level, no_env))
            effect = ff.Effect(e.FF_CONSTANT, -1, 0x4000, ff.Trigger(0, 0), ff.Replay(length, 0), body)
        elif kind == "spring":
            length = 4000
            cond = ff.Condition(0xFFFF, 0xFFFF, level, level, 0, 0)
            body = ff.EffectType(ff_condition_effect=(ff.Condition * 2)(cond, cond))
            effect = ff.Effect(e.FF_SPRING, -1, 0, ff.Trigger(0, 0), ff.Replay(length, 0), body)
        elif kind == "rumble":
            length = 1200
            wave = ff.Periodic(e.FF_SINE, 60, level, 0, 0, no_env)
            body = ff.EffectType(ff_periodic_effect=wave)
            effect = ff.Effect(e.FF_PERIODIC, -1, 0x4000, ff.Trigger(0, 0), ff.Replay(length, 0), body)
        else:
            return

        try:
            dev.write(e.EV_FF, e.FF_GAIN, 0xFFFF)
            eid = dev.upload_effect(effect)
            self._effects.append(eid)
            dev.write(e.EV_FF, eid, 1)
        except OSError:
            return
        self._stop_timer.start(length + 200)

    @Slot()
    def stopEffects(self):
        dev = self._src.device
        for eid in self._effects:
            try:
                dev.write(e.EV_FF, eid, 0)
                dev.erase_effect(eid)
            except (OSError, AttributeError):
                pass
        self._effects = []

    # --- tunables -------------------------------------------------------------------------

    @Slot(str, int, result=bool)
    def setTunable(self, key, value):
        ok = devices.write_tunable(self.info, key, value)
        if ok:
            self._tunables[key] = int(value)
            self.tunablesChanged.emit()
        return ok

    # --- properties -----------------------------------------------------------------------

    def _get(self, key, default=None):
        return (self.info or {}).get(key, default)

    def _ffb_ready(self):
        dev = self._src.device
        if not dev or self._get("driver") != devices.DRIVER_FFB:
            return False
        try:
            return e.EV_FF in dev.capabilities() and self._src.writable()
        except OSError:
            return False

    def _range(self):
        return self._tunables.get("range", 900)

    @staticmethod
    def _open_mode():
        # The module parameter itself is root-only; the saved options file is readable by everyone.
        try:
            with open(OPTIONS_FILE) as f:
                for word in f.read().split():
                    if word.startswith("open_mode="):
                        return int(word.split("=", 1)[1])
        except (OSError, ValueError):
            pass
        return 1

    connected = Property(bool, lambda s: s.info is not None, notify=statusChanged)
    mode = Property(str, lambda s: s._get("mode", ""), notify=statusChanged)
    isT248r = Property(bool, lambda s: bool(s._get("is_t248r")), notify=statusChanged)
    product = Property(str, lambda s: s._get("product", ""), notify=statusChanged)
    firmware = Property(str, lambda s: s._firmware, notify=statusChanged)
    driver = Property(str, lambda s: s._get("driver") or "", notify=statusChanged)
    ffbReady = Property(bool, _ffb_ready, notify=statusChanged)

    steering = Property(float, lambda s: s._steer, notify=inputChanged)
    steeringDegrees = Property(float, lambda s: s._steer * s._range() / 2, notify=inputChanged)
    range = Property(int, _range, notify=tunablesChanged)
    throttle = Property(float, lambda s: s._pedals["throttle"], notify=inputChanged)
    brake = Property(float, lambda s: s._pedals["brake"], notify=inputChanged)
    clutch = Property(float, lambda s: s._pedals["clutch"], notify=inputChanged)
    pressed = Property("QVariantList", lambda s: sorted(s._pressed), notify=inputChanged)
    hatX = Property(int, lambda s: s._hat[0], notify=inputChanged)
    hatY = Property(int, lambda s: s._hat[1], notify=inputChanged)
    encoderSlot = Property(int, lambda s: s._slot, notify=inputChanged)

    tunables = Property("QVariantMap", lambda s: dict(s._tunables), notify=tunablesChanged)
    openMode = Property(int, lambda s: s._open_mode(), notify=tunablesChanged)
    tunablesWritable = Property(bool, lambda s: bool(s._get("tunables")) and all(
        os.access(p, os.W_OK) for p in s._get("tunables").values()), notify=tunablesChanged)
