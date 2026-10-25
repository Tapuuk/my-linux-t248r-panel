"""Find the T248R and Thrustmaster shifters through sysfs. Read-only, no root needed."""
import glob
import os

VENDOR = "044f"

PC_MODE = "b696"
PS_MODE_1 = "b66d"
PS_MODE_2 = "b69d"
WHEEL_PIDS = {PC_MODE: "pc", PS_MODE_1: "ps1", PS_MODE_2: "ps2"}

# bcdDevice tells the T248 family apart; Thrustmaster's driver calls the T248R "Monza".
T248R_BCD = "0249"
T248_BCDS = {"0248", "0251"}

# TH8A, TH8S and the older T500 RS shifter all show up as "T500 RS Gear Shift".
SHIFTER_PIDS = {"b660": "TH8A / TH8S"}

DRIVER_FFB = "tmff2"
TUNABLES = ("range", "gain", "spring_level", "damper_level", "friction_level")


def _read(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def _usb_devices():
    for d in glob.glob("/sys/bus/usb/devices/*"):
        if _read(f"{d}/idVendor") == VENDOR:
            yield d


def _hid_dir(usb_dir):
    """The HID device of the first interface, e.g. .../3-1.3:1.0/0003:044F:B696.000F"""
    for intf in sorted(glob.glob(f"{usb_dir}/{os.path.basename(usb_dir)}:*")):
        for hid in glob.glob(f"{intf}/0003:044F:*"):
            return hid
    return None


def _event_node(hid_dir):
    if not hid_dir:
        return None
    for ev in glob.glob(f"{hid_dir}/input/input*/event*"):
        return f"/dev/input/{os.path.basename(ev)}"
    return None


def _driver(path):
    link = f"{path}/driver"
    return os.path.basename(os.path.realpath(link)) if os.path.exists(link) else None


def _usb_info(d):
    pid = _read(f"{d}/idProduct")
    return {
        "sysfs": d,
        "pid": pid,
        "bcd": _read(f"{d}/bcdDevice"),
        "product": _read(f"{d}/product", ""),
        "busnum": _read(f"{d}/busnum"),
        "devnum": _read(f"{d}/devnum"),
        "autosuspend": _read(f"{d}/power/control"),
    }


def find_wheel():
    for d in _usb_devices():
        info = _usb_info(d)
        if info["pid"] not in WHEEL_PIDS:
            continue
        hid = _hid_dir(d)
        info.update(
            mode=WHEEL_PIDS[info["pid"]],
            is_t248r=info["bcd"] == T248R_BCD,
            is_t248=info["bcd"] in T248_BCDS,
            hid=hid,
            driver=_driver(hid) if hid else None,
            event=_event_node(hid),
            tunables={k: f"{hid}/{k}" for k in TUNABLES if hid and os.path.exists(f"{hid}/{k}")},
        )
        return info
    return None


def find_shifters():
    out = []
    for d in _usb_devices():
        info = _usb_info(d)
        if info["pid"] in SHIFTER_PIDS:
            hid = _hid_dir(d)
            info.update(model=SHIFTER_PIDS[info["pid"]], hid=hid,
                        driver=_driver(hid) if hid else None, event=_event_node(hid))
            out.append(info)
    return out


def read_tunables(wheel):
    vals = {}
    for k, p in (wheel or {}).get("tunables", {}).items():
        v = _read(p)
        if v is not None and v.lstrip("-").isdigit():
            vals[k] = int(v)
    return vals


def write_tunable(wheel, key, value):
    """Works without root once the panel's udev rule has made the files writable."""
    path = (wheel or {}).get("tunables", {}).get(key)
    if not path:
        return False
    try:
        with open(path, "w") as f:
            f.write(str(int(value)))
        return True
    except OSError:
        return False
