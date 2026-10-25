"""USB control transfers through usbfs, without libusb.

Vendor requests skip the kernel's interface-claim check, so these work while
the wheel's HID interface is bound to a driver.
"""
import ctypes
import fcntl
import os

# struct usbdevfs_ctrltransfer { u8 bRequestType, bRequest; u16 wValue, wIndex, wLength; u32 timeout; void *data; }
class _CtrlTransfer(ctypes.Structure):
    _fields_ = [
        ("bRequestType", ctypes.c_uint8),
        ("bRequest", ctypes.c_uint8),
        ("wValue", ctypes.c_uint16),
        ("wIndex", ctypes.c_uint16),
        ("wLength", ctypes.c_uint16),
        ("timeout", ctypes.c_uint32),
        ("data", ctypes.c_void_p),
    ]


def _iowr(kind, nr, size):
    return (3 << 30) | (size << 16) | (ord(kind) << 8) | nr


USBDEVFS_CONTROL = _iowr("U", 0, ctypes.sizeof(_CtrlTransfer))


def node_path(busnum, devnum):
    return f"/dev/bus/usb/{int(busnum):03d}/{int(devnum):03d}"


def control(path, request_type, request, value=0, index=0, length=0, timeout_ms=1000):
    """Run one control transfer. Returns the bytes read for IN requests, b"" for OUT."""
    buf = ctypes.create_string_buffer(max(length, 1))
    xfer = _CtrlTransfer(request_type, request, value, index, length, timeout_ms,
                         ctypes.cast(buf, ctypes.c_void_p).value if length else None)
    fd = os.open(path, os.O_RDWR)
    try:
        got = fcntl.ioctl(fd, USBDEVFS_CONTROL, xfer)
    finally:
        os.close(fd)
    return buf.raw[:got] if request_type & 0x80 else b""


# Requests used by Thrustmaster's own driver (seen in its USB traffic).
def read_firmware(path):
    """0xc1/0x56 answers `56 <minor> <major> ..`, e.g. 56 17 01 = v1.23."""
    data = control(path, 0xC1, 0x56, length=8)
    if len(data) >= 3 and data[0] == 0x56:
        return f"{data[2]}.{data[1]:02d}"
    return None


def read_model(path):
    """0xc1/0x49 identify reply; byte 7 is the model (0x10 = T248R, 0x0a = T248)."""
    data = control(path, 0xC1, 0x49, length=16)
    return data[7] if len(data) >= 8 and data[0] == 0x49 else None


def switch_to_pc_mode(path):
    """The same command the Windows driver sends to a T248R left in PlayStation mode."""
    control(path, 0x41, 0x53, value=0x000B)
