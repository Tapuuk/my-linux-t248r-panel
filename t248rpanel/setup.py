"""Runs the root helper through pkexec and turns its progress lines into steps for the UI."""
import os

from PySide6.QtCore import QObject, Property, QProcess, Signal, Slot

STEP_TITLES = {
    "tools": "Install build tools and kernel headers",
    "driver": "Build the force feedback driver",
    "rules": "Set wheel permissions and auto PC mode",
    "options": "Save force feedback defaults",
    "activate": "Turn on force feedback for your wheel",
    "uninstall": "Remove the driver, rules and settings",
    "switch": "Switch the wheel to PC mode",
}
SETUP_STEPS = ["tools", "driver", "rules", "options", "activate"]
OPTION_KEYS = {"range", "gain", "spring_level", "damper_level", "friction_level", "open_mode", "timer_msecs"}
LOG_LIMIT = 200_000


def helper_path():
    pkg = os.path.dirname(os.path.realpath(__file__))
    for candidate in (os.path.join(pkg, "..", "t248r-panel-helper"),          # installed
                      os.path.join(pkg, "..", "helper", "t248r-panel-helper")):  # running from the repo
        if os.path.isfile(candidate):
            return os.path.realpath(candidate)
    return ""


class Setup(QObject):
    changed = Signal()
    logChanged = Signal()
    finished = Signal(bool)
    hintReceived = Signal(str, str)

    def __init__(self, wheel, parent=None):
        super().__init__(parent)
        self._wheel = wheel
        self._steps = []
        self._log = ""
        self._error = ""
        self._buffer = ""
        self._proc = None

    def _start(self, args, step_ids):
        if self._proc:
            return
        helper = helper_path()
        if not helper:
            self._fail("The setup helper is missing. Reinstall the app.")
            return
        self._steps = [{"id": i, "title": STEP_TITLES[i], "state": "pending", "text": ""} for i in step_ids]
        self._error = ""
        self._append(f"$ pkexec {helper} {' '.join(args)}\n")
        self._proc = QProcess(self)
        self._proc.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        self._proc.readyReadStandardOutput.connect(self._read)
        self._proc.finished.connect(self._done)
        self._proc.errorOccurred.connect(self._error_occurred)
        self._proc.start("pkexec", [helper, *args])
        self.changed.emit()

    def _read(self):
        self._buffer += bytes(self._proc.readAllStandardOutput()).decode(errors="replace")
        *lines, self._buffer = self._buffer.split("\n")
        for line in lines:
            self._handle(line.rstrip("\r"))

    def _handle(self, line):
        if line.startswith("@@step "):
            parts = line.split(" ", 3)
            if len(parts) >= 3:
                sid, state = parts[1], parts[2]
                text = parts[3] if len(parts) > 3 else ""
                step = next((s for s in self._steps if s["id"] == sid), None)
                if step is None and sid in STEP_TITLES:
                    step = {"id": sid, "title": STEP_TITLES[sid], "state": "pending", "text": ""}
                    self._steps.append(step)
                if step:
                    step["state"], step["text"] = state, text
                    if state == "failed":
                        self._error = text or f"{STEP_TITLES.get(sid, sid)} failed"
                    self._steps = [dict(s) for s in self._steps]
                    self.changed.emit()
            return
        if line.startswith("@@hint "):
            parts = line.split(" ", 2)
            if len(parts) == 3:
                self.hintReceived.emit(parts[1], parts[2])
            return
        self._append(line + "\n")

    def _append(self, text):
        self._log = (self._log + text)[-LOG_LIMIT:]
        self.logChanged.emit()

    def _done(self, code, _status):
        if self._buffer:
            self._handle(self._buffer)
            self._buffer = ""
        ok = code == 0
        if code in (126, 127) and not any(s["state"] != "pending" for s in self._steps):
            self._error = "You closed the password prompt, so nothing changed."
        elif not ok and not self._error:
            self._error = f"Setup stopped with an error (code {code}). The log has the details."
        if not ok:
            for s in self._steps:
                if s["state"] in ("pending", "running"):
                    s["state"] = "skipped" if s["state"] == "pending" else "failed"
            self._steps = [dict(s) for s in self._steps]
        self._proc.deleteLater()
        self._proc = None
        self.changed.emit()
        self.finished.emit(ok)
        self._wheel.poll()

    def _error_occurred(self, err):
        if err == QProcess.ProcessError.FailedToStart:
            self._fail("pkexec isn't available, so the app can't ask for your password. Install polkit.")
            self._proc = None

    def _fail(self, message):
        self._error = message
        self._append(message + "\n")
        self.changed.emit()
        self.finished.emit(False)

    @Slot(bool)
    def runAll(self, autoPc):
        self._start(["setup"] + ([] if autoPc else ["--no-auto-pc"]), SETUP_STEPS)

    @Slot("QVariantMap")
    def saveDefaults(self, values):
        args = []
        for k, v in values.items():
            if k in OPTION_KEYS:
                args.append(f"{k}={int(v)}")
        if args:
            self._start(["write-options", *sorted(args)], ["options"])

    @Slot()
    def dismiss(self):
        if not self._proc:
            self._steps, self._error = [], ""
            self.changed.emit()

    @Slot()
    def uninstall(self):
        self._start(["uninstall"], ["uninstall"])

    @Slot()
    def switchToPc(self):
        info = self._wheel.info
        if info and info.get("mode") in ("ps1", "ps2"):
            self._start(["switch-to-pc", str(int(info["busnum"])), str(int(info["devnum"]))], ["switch"])

    running = Property(bool, lambda s: s._proc is not None, notify=changed)
    steps = Property("QVariantList", lambda s: s._steps, notify=changed)
    log = Property(str, lambda s: s._log, notify=logChanged)
    lastError = Property(str, lambda s: s._error, notify=changed)
