#!/usr/bin/python3
"""Starts My Linux T248R Panel with a Python that can load PySide6 and evdev.

The system Python is used when it has everything. Some distros (Ubuntu 24.04,
Debian 12) don't package PySide6, so on those a private venv is created once
and a pinned PySide6-Essentials is installed into it from PyPI.

Standard library only: this file must run before PySide6 is known to exist.
"""

import fcntl
import json
import os
import platform
import shutil
import subprocess
import sys
import time

APP_NAME = "My Linux T248R Panel"
APP_SLUG = "my-linux-t248r-panel"
APP_ID = "io.github.tapuuk.T248RPanel"

PYSIDE_VERSION = "6.12.0"
DOWNLOAD_SIZE = "about 85 MB"
# sha256 of the PyPI Linux wheels. pip refuses anything else.
WHEEL_HASHES = {
    "PySide6-Essentials": [
        "16f4b5e41daf49235ae048458243da9efe5f3d8040f9cc5aa454ce69893d3bd9",  # x86_64
        "08c5841063fc1df69b7fa1ee405f539e66576a83fc48004be3e2c5e35ccbfa69",  # aarch64
    ],
    "shiboken6": [
        "3bde565bb0890044b5c7f63808adddede5abc241e9395a2bfed61919884d6240",  # x86_64
        "ff72a72b3277b418902d562b987b33a6f6818bed9fe40a49d634d09bc67f620e",  # aarch64
    ],
}
WHEEL_MACHINES = ("x86_64", "aarch64")

MIN_PYTHON = (3, 10)
MIN_QT = (6, 5)
# openSUSE builds PySide6 for one Python only, which may not be "python3".
CANDIDATES = ["python3"] + [f"python3.{minor}" for minor in range(14, 9, -1)]
QML_MODULES = [
    "QtQuick", "QtQuick/Controls/Basic", "QtQuick/Layouts", "QtQuick/Shapes",
    "QtQuick/Effects", "QtQuick/Templates", "QtQuick/Window", "QtQml/WorkerScript",
]

APP_DIR = os.path.dirname(os.path.realpath(__file__))

# Runs inside each candidate interpreter and prints one JSON line.
PROBE = r"""
import json, os, sys
r = {"py": list(sys.version_info[:3]), "evdev": False, "pyside": None, "qt": None,
     "qml_missing": [], "error": ""}
try:
    import evdev
    r["evdev"] = True
except Exception as e:
    r["error"] = "evdev: %s" % e
try:
    import PySide6, PySide6.QtQuick
    from PySide6.QtCore import QLibraryInfo, qVersion
    r["pyside"] = PySide6.__version__
    r["qt"] = qVersion()
    roots = [QLibraryInfo.path(QLibraryInfo.LibraryPath.QmlImportsPath)]
    for var in ("QML_IMPORT_PATH", "QML2_IMPORT_PATH"):
        roots += [p for p in os.environ.get(var, "").split(os.pathsep) if p]
    for mod in sys.argv[1:]:
        if not any(os.path.isfile(os.path.join(root, mod, "qmldir")) for root in roots):
            r["qml_missing"].append(mod.replace("/", "."))
except Exception as e:
    r["error"] = (r["error"] + "; " if r["error"] else "") + "PySide6: %s" % e
print(json.dumps(r))
"""


def log(msg):
    print(f"{APP_SLUG}: {msg}", file=sys.stderr, flush=True)


def version_tuple(text):
    out = []
    for part in str(text).split(".")[:3]:
        digits = "".join(ch for ch in part if ch.isdigit())
        out.append(int(digits) if digits else 0)
    return tuple(out)


def child_env():
    env = dict(os.environ)
    env["PYTHONPATH"] = APP_DIR
    # Keeps the current directory off sys.path (Python 3.11+).
    env["PYTHONSAFEPATH"] = "1"
    env.pop("PYTHONHOME", None)
    return env


def probe(python, timeout=30):
    """Returns what `python` can import, or None if it doesn't run."""
    try:
        out = subprocess.run([python, "-c", PROBE, *QML_MODULES], cwd="/", env=child_env(),
                             capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.SubprocessError):
        return None
    for line in reversed(out.stdout.splitlines()):
        try:
            return json.loads(line)
        except ValueError:
            continue
    return None


def problems(info):
    """Lists why an interpreter can't run the app. Empty means it can."""
    if info is None:
        return ["does not run"]
    found = []
    if tuple(info["py"][:2]) < MIN_PYTHON:
        found.append("Python %d.%d is too old" % tuple(info["py"][:2]))
    if not info["evdev"]:
        found.append("no evdev")
    if not info["pyside"]:
        found.append("no PySide6.QtQuick")
    elif version_tuple(info["qt"])[:2] < MIN_QT:
        found.append(f"Qt {info['qt']} is too old")
    if info["qml_missing"]:
        found.append("missing QML modules " + ", ".join(info["qml_missing"]))
    return found


def system_candidates(which=shutil.which, realpath=os.path.realpath):
    seen, out = set(), []
    for name in CANDIDATES:
        path = which(name)
        if not path:
            continue
        real = realpath(path)
        if real in seen:
            continue
        seen.add(real)
        out.append(path)
    return out


def pick_system(candidates, probe_fn=probe):
    """Returns (chosen path or None, [(path, info)] for every candidate probed)."""
    probed = []
    for path in candidates:
        info = probe_fn(path)
        probed.append((path, info))
        if not problems(info):
            return path, probed
        log(f"{path}: " + "; ".join(problems(info)))
    return None, probed


def pick_venv_base(probed):
    """The newest interpreter that is recent enough and already has evdev."""
    good = [(tuple(i["py"]), p) for p, i in probed
            if i is not None and tuple(i["py"][:2]) >= MIN_PYTHON and i["evdev"]]
    if not good:
        return None
    return max(good)[1]


def data_dir():
    base = os.environ.get("XDG_DATA_HOME") or os.path.join(os.path.expanduser("~"), ".local", "share")
    return os.path.join(base, APP_SLUG)


def venv_paths(root=None):
    root = root or data_dir()
    venv = os.path.join(root, "venv")
    return {
        "root": root,
        "venv": venv,
        "python": os.path.join(venv, "bin", "python3"),
        "marker": os.path.join(venv, "t248r-panel.json"),
        "lock": os.path.join(root, "venv.lock"),
        "log": os.path.join(root, "venv-install.log"),
    }


def venv_ready(paths, probe_fn=probe):
    try:
        with open(paths["marker"]) as f:
            marker = json.load(f)
    except (OSError, ValueError):
        return False
    if marker.get("pyside") != PYSIDE_VERSION or not os.path.exists(paths["python"]):
        return False
    return not problems(probe_fn(paths["python"]))


# Desktop feedback. Each helper quietly does nothing when its tool is missing.

def have_display():
    return bool(os.environ.get("WAYLAND_DISPLAY") or os.environ.get("DISPLAY"))


def prefer_kdialog():
    desktop = os.environ.get("XDG_CURRENT_DESKTOP", "").upper()
    return "KDE" in desktop and shutil.which("kdialog")


def show_error(text):
    log(text)
    if not have_display():
        return
    try:
        if prefer_kdialog():
            subprocess.run(["kdialog", "--title", APP_NAME, "--error", text])
        elif shutil.which("zenity"):
            subprocess.run(["zenity", "--error", "--title", APP_NAME, "--no-wrap", "--text", text])
        elif shutil.which("kdialog"):
            subprocess.run(["kdialog", "--title", APP_NAME, "--error", text])
        elif shutil.which("notify-send"):
            subprocess.run(["notify-send", "-u", "critical", "-a", APP_NAME, "-i", APP_ID, APP_NAME, text])
    except OSError:
        pass


def notify(text):
    if have_display() and shutil.which("notify-send"):
        try:
            subprocess.run(["notify-send", "-a", APP_NAME, "-i", APP_ID, APP_NAME, text])
        except OSError:
            pass


class Progress:
    """A busy dialog while the venv is built: zenity, kdialog, or a notification."""

    def __init__(self, text):
        self.kind = None
        self.proc = None
        self.kdialog_ref = None
        if not have_display():
            log(text)
            return
        try:
            if prefer_kdialog() or (not shutil.which("zenity") and shutil.which("kdialog")):
                out = subprocess.run(["kdialog", "--title", APP_NAME, "--progressbar", text, "0"],
                                     capture_output=True, text=True, timeout=10)
                self.kdialog_ref = out.stdout.split()
                self.kind = "kdialog" if len(self.kdialog_ref) == 2 else None
            elif shutil.which("zenity"):
                self.proc = subprocess.Popen(
                    ["zenity", "--progress", "--pulsate", "--auto-close", "--title", APP_NAME,
                     "--width", "420", "--text", text],
                    stdin=subprocess.PIPE, text=True)
                self.kind = "zenity"
        except (OSError, subprocess.SubprocessError):
            self.kind = None
        if self.kind is None:
            log(text)
            notify(text)

    def set_text(self, text):
        if self.kind == "zenity" and self.proc.poll() is None:
            try:
                self.proc.stdin.write(f"# {text}\n")
                self.proc.stdin.flush()
            except OSError:
                pass

    def cancelled(self):
        # Only zenity has a Cancel button here.
        return self.kind == "zenity" and self.proc.poll() is not None

    def close(self):
        if self.kind == "zenity":
            if self.proc.poll() is None:
                try:
                    self.proc.stdin.write("100\n")
                    self.proc.stdin.close()
                except OSError:
                    pass
                try:
                    self.proc.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    self.proc.terminate()
        elif self.kind == "kdialog":
            service, path = self.kdialog_ref
            closed = False
            if shutil.which("gdbus"):
                closed = subprocess.run(
                    ["gdbus", "call", "--session", "--dest", service, "--object-path", path,
                     "--method", "org.kde.kdialog.ProgressDialog.close"],
                    capture_output=True).returncode == 0
            if not closed:
                try:
                    os.kill(int(service.rsplit("-", 1)[1]), 15)
                except (ValueError, IndexError, OSError):
                    pass
        self.kind = None


def pip_requirements():
    lines = []
    for name, hashes in WHEEL_HASHES.items():
        lines.append(f"{name}=={PYSIDE_VERSION} " + " ".join(f"--hash=sha256:{h}" for h in hashes))
    return "\n".join(lines) + "\n"


def run_watched(cmd, logf, progress, steps):
    """Runs cmd with output going to logf. Updates the dialog text from `steps`
    (substring -> text). Returns the exit code, or None if the user cancelled."""
    start = logf.tell()
    proc = subprocess.Popen(cmd, stdout=logf, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, cwd="/")
    shown = set()
    while proc.poll() is None:
        if progress.cancelled():
            proc.terminate()
            proc.wait()
            return None
        try:
            with open(logf.name, errors="replace") as f:
                f.seek(start)
                seen = f.read()
        except OSError:
            seen = ""
        for needle, text in steps:
            if needle in seen and needle not in shown:
                shown.add(needle)
                progress.set_text(text)
        time.sleep(0.3)
    return proc.returncode


def venv_missing_text():
    return (f"{APP_NAME} needs Python's venv module to set itself up, and it isn't installed.\n\n"
            "On Debian and Ubuntu, install it with:\n"
            "    sudo apt install python3-venv\n\n"
            "Then start the app again.")


def build_venv(base, paths):
    """Creates the venv and installs PySide6 into it. Returns True on success."""
    os.makedirs(paths["root"], exist_ok=True)
    if os.path.lexists(paths["venv"]):
        shutil.rmtree(paths["venv"], ignore_errors=True)

    progress = Progress(f"Setting up {APP_NAME} for the first time.\n"
                        f"This downloads PySide6 ({DOWNLOAD_SIZE}) and only happens once.")
    ok = False
    try:
        with open(paths["log"], "w") as logf:
            logf.write(f"base interpreter: {base}\n")
            logf.flush()
            rc = run_watched([base, "-m", "venv", "--system-site-packages", paths["venv"]],
                             logf, progress, [])
            if rc is None:
                return False
            if rc != 0:
                progress.close()
                with open(paths["log"], errors="replace") as f:
                    text = f.read()
                if "ensurepip" in text or "No module named venv" in text:
                    show_error(venv_missing_text())
                else:
                    show_error(f"{APP_NAME} couldn't create its Python environment.\n"
                               f"Details are in {paths['log']}")
                return False

            req = os.path.join(paths["root"], "requirements.txt")
            with open(req, "w") as f:
                f.write(pip_requirements())
            progress.set_text(f"Downloading PySide6 ({DOWNLOAD_SIZE})...")
            rc = run_watched(
                [paths["python"], "-m", "pip", "install", "--disable-pip-version-check", "--no-input",
                 "--no-cache-dir", "--ignore-installed", "--only-binary", ":all:", "--require-hashes",
                 "--progress-bar", "off", "-r", req],
                logf, progress,
                [("Downloading", f"Downloading PySide6 ({DOWNLOAD_SIZE})..."),
                 ("Installing collected packages", "Installing PySide6...")])
            if rc is None:
                return False
            if rc != 0:
                progress.close()
                show_error(f"{APP_NAME} couldn't download PySide6.\n"
                           "Check your internet connection, then start the app again.\n"
                           f"Details are in {paths['log']}")
                return False

            progress.set_text("Checking the installation...")
            info = probe(paths["python"], timeout=60)
            if problems(info):
                progress.close()
                show_error(f"PySide6 was installed but doesn't load: {'; '.join(problems(info))}.\n"
                           f"Details: {(info or {}).get('error', '')}\n"
                           f"You can delete {paths['venv']} and start the app again.")
                return False
            with open(paths["marker"], "w") as f:
                json.dump({"pyside": PYSIDE_VERSION, "base": base, "python": info["py"]}, f)
            ok = True
            return True
    finally:
        progress.close()
        if not ok and os.path.lexists(paths["venv"]) and not os.path.exists(paths["marker"]):
            shutil.rmtree(paths["venv"], ignore_errors=True)


def install_hint():
    return ("Install PySide6 from your distro instead:\n"
            "    Arch: sudo pacman -S pyside6 python-evdev\n"
            "    Fedora: sudo dnf install python3-pyside6 python3-evdev\n"
            "    openSUSE: sudo zypper install python313-pyside6 python313-evdev\n"
            "    Debian 13, Ubuntu 25.04 and newer: sudo apt install python3-evdev python3-pyside6.qtquick\n"
            "        python3-pyside6.qtquickcontrols2 qml6-module-qtquick-controls qml6-module-qtquick-layouts\n"
            "        qml6-module-qtquick-shapes qml6-module-qtquick-effects")


def ensure_venv(probed, paths=None):
    """Returns a venv python ready to run the app, or None after telling the user why not."""
    paths = paths or venv_paths()
    if venv_ready(paths):
        return paths["python"]

    base = pick_venv_base(probed)
    if base is None:
        if any(i and i["pyside"] for _, i in probed):
            show_error(f"{APP_NAME} needs the Python evdev module.\n"
                       "Install python3-evdev (python-evdev on Arch, python313-evdev on openSUSE).")
        else:
            show_error(f"{APP_NAME} needs Python 3.10 or newer with the evdev module.\n"
                       "Install python3-evdev from your distro, then start the app again.")
        return None
    if platform.machine() not in WHEEL_MACHINES:
        show_error(f"PySide6 isn't packaged by your distro, and there's no ready-made build "
                   f"for {platform.machine()} to download.\n\n" + install_hint())
        return None

    os.makedirs(paths["root"], exist_ok=True)
    with open(paths["lock"], "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            # Another copy of the app is already setting up; wait for it.
            log("waiting for another launcher to finish setting up")
            fcntl.flock(lock, fcntl.LOCK_EX)
        if venv_ready(paths):
            return paths["python"]
        if not build_venv(base, paths):
            return None
    notify(f"{APP_NAME} is ready.")
    return paths["python"]


def app_command(python, argv):
    return [python, "-m", "t248rpanel", *argv]


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    # DRY_RUN only reports the choice. SETUP_ONLY also builds the venv if needed.
    dry_run = os.environ.get("T248R_PANEL_DRY_RUN") == "1"
    setup_only = os.environ.get("T248R_PANEL_SETUP_ONLY") == "1"

    forced = os.environ.get("T248R_PANEL_PYTHON")
    if forced:
        python = shutil.which(forced) or forced
    else:
        python = None
        probed = []
        if os.environ.get("T248R_PANEL_VENV") != "1":
            python, probed = pick_system(system_candidates())
        if python is None:
            if not probed:
                probed = [(p, probe(p)) for p in system_candidates()]
            if dry_run:
                paths = venv_paths()
                state = "ready" if venv_ready(paths) else f"would build from {pick_venv_base(probed)}"
                print(f"venv {paths['venv']}: {state}")
                return 0
            python = ensure_venv(probed)
            if python is None:
                return 1

    cmd = app_command(python, argv)
    if dry_run or setup_only:
        print(" ".join(cmd))
        return 0
    try:
        os.execve(python, cmd, child_env())
    except OSError as e:
        show_error(f"Couldn't start {python}: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
