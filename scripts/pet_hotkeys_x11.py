#!/usr/bin/env python3
"""Tiny X11 global hotkey bridge for the Godot desktop pet."""

from __future__ import annotations

import argparse
import ctypes
import ctypes.util
import socket
import sys
from dataclasses import dataclass


KEY_PRESS = 2
GRAB_MODE_ASYNC = 1
SHIFT_MASK = 1 << 0
LOCK_MASK = 1 << 1
CONTROL_MASK = 1 << 2
MOD1_MASK = 1 << 3
MOD2_MASK = 1 << 4
MOD4_MASK = 1 << 6
X_ERROR_HANDLER = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_void_p, ctypes.c_void_p)
_ERROR_HANDLER_REF = None


@dataclass(frozen=True)
class Hotkey:
    command: str
    shortcut: str
    keysym: int
    keycode: int
    modifiers: int


class XKeyEvent(ctypes.Structure):
    _fields_ = [
        ("type", ctypes.c_int),
        ("serial", ctypes.c_ulong),
        ("send_event", ctypes.c_int),
        ("display", ctypes.c_void_p),
        ("window", ctypes.c_ulong),
        ("root", ctypes.c_ulong),
        ("subwindow", ctypes.c_ulong),
        ("time", ctypes.c_ulong),
        ("x", ctypes.c_int),
        ("y", ctypes.c_int),
        ("x_root", ctypes.c_int),
        ("y_root", ctypes.c_int),
        ("state", ctypes.c_uint),
        ("keycode", ctypes.c_uint),
        ("same_screen", ctypes.c_int),
    ]


class XEvent(ctypes.Union):
    _fields_ = [
        ("type", ctypes.c_int),
        ("xkey", XKeyEvent),
        ("pad", ctypes.c_long * 24),
    ]


def load_x11() -> ctypes.CDLL:
    path = ctypes.util.find_library("X11")
    if not path:
        raise RuntimeError("libX11 not found")
    lib = ctypes.CDLL(path)
    lib.XOpenDisplay.argtypes = [ctypes.c_char_p]
    lib.XOpenDisplay.restype = ctypes.c_void_p
    lib.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
    lib.XDefaultRootWindow.restype = ctypes.c_ulong
    lib.XStringToKeysym.argtypes = [ctypes.c_char_p]
    lib.XStringToKeysym.restype = ctypes.c_ulong
    lib.XKeysymToKeycode.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
    lib.XKeysymToKeycode.restype = ctypes.c_uint
    lib.XGrabKey.argtypes = [
        ctypes.c_void_p,
        ctypes.c_int,
        ctypes.c_uint,
        ctypes.c_ulong,
        ctypes.c_int,
        ctypes.c_int,
        ctypes.c_int,
    ]
    lib.XGrabKey.restype = ctypes.c_int
    lib.XUngrabKey.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_uint, ctypes.c_ulong]
    lib.XSync.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lib.XNextEvent.argtypes = [ctypes.c_void_p, ctypes.POINTER(XEvent)]
    lib.XCloseDisplay.argtypes = [ctypes.c_void_p]
    lib.XSetErrorHandler.argtypes = [X_ERROR_HANDLER]
    return lib


def parse_shortcut(lib: ctypes.CDLL, display: ctypes.c_void_p, command: str, shortcut: str) -> Hotkey:
    parts = [part.strip() for part in shortcut.split("+") if part.strip()]
    if not parts:
        raise ValueError(f"empty shortcut for {command}")
    modifiers = 0
    key_name = parts[-1]
    for part in parts[:-1]:
        lower = part.lower()
        if lower in ("ctrl", "control"):
            modifiers |= CONTROL_MASK
        elif lower == "shift":
            modifiers |= SHIFT_MASK
        elif lower in ("alt", "option"):
            modifiers |= MOD1_MASK
        elif lower in ("super", "meta", "win", "command"):
            modifiers |= MOD4_MASK
        else:
            raise ValueError(f"unknown modifier '{part}' in {shortcut}")

    x11_name = normalize_key_name(key_name)
    keysym = int(lib.XStringToKeysym(x11_name.encode("utf-8")))
    if keysym == 0 and len(key_name) == 1:
        keysym = int(lib.XStringToKeysym(key_name.lower().encode("utf-8")))
    if keysym == 0:
        raise ValueError(f"unknown key '{key_name}' in {shortcut}")
    keycode = int(lib.XKeysymToKeycode(display, keysym))
    if keycode == 0:
        raise ValueError(f"no keycode for {shortcut}")
    return Hotkey(command, shortcut, keysym, keycode, modifiers)


def normalize_key_name(name: str) -> str:
    aliases = {
        "Esc": "Escape",
        "Return": "Return",
        "Enter": "Return",
        "Space": "space",
        "PgUp": "Page_Up",
        "PageUp": "Page_Up",
        "PgDown": "Page_Down",
        "PageDown": "Page_Down",
        "Plus": "plus",
        "Minus": "minus",
    }
    if name in aliases:
        return aliases[name]
    if len(name) == 1:
        return name.lower()
    return name


def grab_hotkeys(lib: ctypes.CDLL, display: ctypes.c_void_p, root: int, hotkeys: list[Hotkey]) -> None:
    global _ERROR_HANDLER_REF
    _ERROR_HANDLER_REF = X_ERROR_HANDLER(lambda _display, _event: 0)
    lib.XSetErrorHandler(_ERROR_HANDLER_REF)
    ignored_locks = (0, LOCK_MASK, MOD2_MASK, LOCK_MASK | MOD2_MASK)
    for hotkey in hotkeys:
        for extra in ignored_locks:
            lib.XGrabKey(
                display,
                hotkey.keycode,
                hotkey.modifiers | extra,
                root,
                True,
                GRAB_MODE_ASYNC,
                GRAB_MODE_ASYNC,
            )
    lib.XSync(display, False)


def run(args: argparse.Namespace) -> int:
    lib = load_x11()
    display = lib.XOpenDisplay(None)
    if not display:
        print("Unable to open X11 display.", file=sys.stderr)
        return 1
    root = int(lib.XDefaultRootWindow(display))
    hotkeys = [
        parse_shortcut(lib, display, "screenshot", args.screenshot),
        parse_shortcut(lib, display, "paste_pin", args.paste_pin),
        parse_shortcut(lib, display, "close_pin", args.close_pin),
    ]
    grab_hotkeys(lib, display, root, hotkeys)
    by_key = {(hotkey.keycode, hotkey.modifiers): hotkey.command for hotkey in hotkeys}
    sender = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    event = XEvent()
    try:
        while True:
            lib.XNextEvent(display, ctypes.byref(event))
            if event.type != KEY_PRESS:
                continue
            state = int(event.xkey.state) & ~(LOCK_MASK | MOD2_MASK)
            command = by_key.get((int(event.xkey.keycode), state))
            if command:
                sender.sendto(command.encode("utf-8"), ("127.0.0.1", args.port))
    finally:
        sender.close()
        lib.XCloseDisplay(display)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--screenshot", required=True)
    parser.add_argument("--paste-pin", required=True)
    parser.add_argument("--close-pin", required=True)
    return parser.parse_args()


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args()))
    except Exception as exc:
        print(f"pet_hotkeys_x11.py: {exc}", file=sys.stderr)
        raise SystemExit(1)
