"""What the PC needs for force feedback, checked without root."""
import glob
import os
import platform
import shutil
import subprocess

from PySide6.QtCore import QObject, Property, QTimer, Signal, Slot

from . import APP_NAME, VERSION, devices

RULES_FILE = "/etc/udev/rules.d/70-my-linux-t248r-panel.rules"
OPTIONS_FILE = "/etc/modprobe.d/my-linux-t248r-panel.conf"
MODULE = "hid-tmff-new"
SECURE_BOOT_VAR = "/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c"

FAMILIES = {
    "arch": {"arch", "cachyos", "endeavouros", "manjaro", "garuda", "artix", "steamos"},
    "debian": {"debian", "ubuntu", "linuxmint", "pop", "zorin", "elementary", "kali", "neon", "raspbian"},
    "fedora": {"fedora", "nobara", "ultramarine", "rhel", "centos", "rocky", "almalinux"},
    "suse": {"opensuse", "opensuse-tumbleweed", "opensuse-leap", "suse", "sles"},
}


def os_release():
    data = {}
    for path in ("/etc/os-release", "/usr/lib/os-release"):
        try:
            with open(path) as f:
                for line in f:
                    k, _, v = line.strip().partition("=")
                    if k:
                        data[k] = v.strip().strip('"')
            break
        except OSError:
            continue
    return data


def distro_family(rel):
    ids = [rel.get("ID", "")] + rel.get("ID_LIKE", "").split()
    for i in ids:
        for fam, members in FAMILIES.items():
            if i in members or i.startswith("opensuse"):
                return "suse" if i.startswith("opensuse") else fam
    return "unknown"


def is_immutable():
    return os.path.exists("/run/ostree-booted") or os.path.exists("/usr/bin/steamos-readonly")


def secure_boot_on():
    try:
        with open(SECURE_BOOT_VAR, "rb") as f:
            return f.read()[-1:] == b"\x01"
    except OSError:
        return False


def signatures_enforced():
    """Unsigned modules are refused under sig_enforce or kernel lockdown, not by Secure Boot itself."""
    try:
        with open("/sys/module/module/parameters/sig_enforce") as f:
            if f.read().strip() == "Y":
                return True
    except OSError:
        pass
    try:
        with open("/sys/kernel/security/lockdown") as f:
            return "[none]" not in f.read()
    except OSError:
        return False


def module_file():
    try:
        out = subprocess.run(["modinfo", "-n", MODULE], capture_output=True, text=True, timeout=5)
        return out.stdout.strip() if out.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def module_params():
    try:
        out = subprocess.run(["modinfo", "-F", "parm", MODULE], capture_output=True, text=True, timeout=5)
        return {line.split(":", 1)[0] for line in out.stdout.splitlines()}
    except (OSError, subprocess.TimeoutExpired):
        return set()


def module_version():
    try:
        out = subprocess.run(["modinfo", "-F", "version", MODULE], capture_output=True, text=True, timeout=5)
        return out.stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


class System(QObject):
    changed = Signal()

    def __init__(self, wheel, parent=None):
        super().__init__(parent)
        self._wheel = wheel
        rel = os_release()
        self._name = rel.get("PRETTY_NAME") or rel.get("NAME") or "Linux"
        self._family = distro_family(rel)
        self._immutable = is_immutable()
        self._kernel = platform.release()
        self._checks = []
        self._hints = []
        self._extra_hints = {}
        wheel.statusChanged.connect(self.refresh)
        self._timer = QTimer(self, interval=4000)
        self._timer.timeout.connect(self.refresh)
        self._timer.start()
        self.refresh()

    @Slot(str, str)
    def addHint(self, code, text):
        self._extra_hints[code] = text
        self.refresh()

    @Slot()
    def refresh(self):
        k = self._kernel
        headers = os.path.isdir(f"/lib/modules/{k}/build")
        dkms = bool(shutil.which("dkms"))
        compiler = bool(shutil.which("gcc") and shutil.which("make"))
        git = bool(shutil.which("git"))
        tools_ok = headers and compiler and git
        missing = [n for n, ok in (("kernel headers", headers), ("compiler", compiler), ("git", git)) if not ok]

        modfile = module_file()
        loaded = os.path.isdir("/sys/module/hid_tmff_new")
        rules = os.path.exists(RULES_FILE)
        wheel = self._wheel.info

        # An earlier build carried a patch that was later dropped; it still works but should be replaced.
        outdated = bool(modfile) and "plain_encoders" in module_params()
        if not modfile:
            driver = {"state": "missing", "detail": "hid-tmff2 is not installed for this kernel"}
        elif outdated:
            driver = {"state": "warn", "detail": "A newer version is ready. Run setup again to update it."}
        else:
            driver = {"state": "ok", "detail": "hid-tmff2 is built for this kernel" + (" and loaded" if loaded else "")}

        checks = [
            {"id": "tools", "title": "Build tools and kernel headers",
             "state": "ok" if tools_ok else "missing",
             "detail": f"Ready for kernel {k}" + ("" if dkms else ", without DKMS") if tools_ok
             else "Missing: " + ", ".join(missing)},
            {"id": "driver", "title": "Force feedback driver", **driver},
            {"id": "rules", "title": "Wheel permissions and PC mode",
             "state": "ok" if rules else "missing",
             "detail": "Installed" if rules else "Lets games and this app reach the wheel and switches it to PC mode"},
        ]
        if not wheel:
            active = {"state": "warn", "detail": "Plug in your T248R to check this"}
        elif wheel["mode"] != "pc":
            active = {"state": "warn", "detail": "The wheel is in PlayStation mode. Switch it to PC mode."}
        elif wheel["driver"] == devices.DRIVER_FFB:
            active = {"state": "ok", "detail": "Your wheel uses the force feedback driver"}
        else:
            active = {"state": "missing", "detail": f"Your wheel uses {wheel['driver'] or 'no driver'}, so games get no force feedback"}
        checks.append({"id": "active", "title": "Force feedback on your wheel", **active})

        hints = []
        if self._immutable:
            hints.append({"code": "immutable", "text": "This system has a read-only root, so the driver can't be installed from here."})
        if self._family == "unknown":
            hints.append({"code": "unsupported", "text": "Your distro isn't recognized. Setup may still work if it uses pacman, apt, dnf or zypper."})
        if signatures_enforced() and modfile and not loaded:
            hints.append({"code": "secureboot", "text":
                          "Secure Boot is on and the driver isn't loaded. Run: sudo mokutil --import /var/lib/dkms/mok.pub "
                          "then reboot and choose Enroll MOK."})
        for code, text in self._extra_hints.items():
            if all(h["code"] != code for h in hints):
                hints.append({"code": code, "text": text})

        if checks != self._checks or hints != self._hints:
            self._checks, self._hints = checks, hints
            self.changed.emit()

    @Slot(result=str)
    def report(self):
        w = self._wheel.info or {}
        lines = [
            f"{APP_NAME} {VERSION}",
            f"Distro: {self._name} ({self._family}), kernel {self._kernel}",
            f"Secure Boot: {'on' if secure_boot_on() else 'off'}, module signatures enforced: {signatures_enforced()}",
            f"Wheel: {'connected' if w else 'not connected'}",
        ]
        if w:
            lines += [
                f"  USB {devices.VENDOR}:{w['pid']} bcdDevice {w['bcd']} ({w['product']}), mode {w['mode']}",
                f"  T248R: {w['is_t248r']}, driver: {w['driver']}, event: {w['event']}, autosuspend: {w['autosuspend']}",
                f"  Firmware: {self._wheel.firmware or 'unknown'}, tunables: {devices.read_tunables(w)}",
            ]
        for s in devices.find_shifters():
            lines.append(f"Shifter: {devices.VENDOR}:{s['pid']} {s['product']}, driver {s['driver']}")
        lines.append(f"Driver module: {module_file() or 'not installed'} {module_version()}")
        lines.append(f"Module loaded: {os.path.isdir('/sys/module/hid_tmff_new')}")
        for p in glob.glob("/sys/module/hid_tmff_new/parameters/*"):
            try:
                with open(p) as f:
                    lines.append(f"  {os.path.basename(p)} = {f.read().strip()}")
            except OSError:
                pass
        lines.append(f"Rules: {'installed' if os.path.exists(RULES_FILE) else 'missing'}")
        lines.append(f"Options: {open(OPTIONS_FILE).read().strip() if os.path.exists(OPTIONS_FILE) else 'none'}")
        for c in self._checks:
            lines.append(f"Check {c['id']}: {c['state']} - {c['detail']}")
        return "\n".join(lines)

    distroName = Property(str, lambda s: s._name, constant=True)
    family = Property(str, lambda s: s._family, constant=True)
    supported = Property(bool, lambda s: s._family != "unknown" and not s._immutable, constant=True)
    immutable = Property(bool, lambda s: s._immutable, constant=True)
    kernel = Property(str, lambda s: s._kernel, constant=True)
    checks = Property("QVariantList", lambda s: s._checks, notify=changed)
    hints = Property("QVariantList", lambda s: s._hints, notify=changed)
    allGood = Property(bool, lambda s: all(c["state"] == "ok" for c in s._checks), notify=changed)
