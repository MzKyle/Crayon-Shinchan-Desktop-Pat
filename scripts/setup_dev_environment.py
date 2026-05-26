#!/usr/bin/env python3
"""Set up local Python dependencies and print desktop integration checks."""

from __future__ import annotations

import argparse
import os
import platform
import shutil
import subprocess
import sys
import venv
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
VENV = ROOT / ".venv"


def run(cmd: list[str]) -> None:
    print("+", " ".join(cmd))
    subprocess.check_call(cmd, cwd=ROOT)


def venv_python() -> Path:
    if platform.system() == "Windows":
        return VENV / "Scripts" / "python.exe"
    return VENV / "bin" / "python"


def has_local_godot() -> bool:
    return any((ROOT / "tools" / "godot").glob("Godot_v*_linux.x86_64"))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-install", action="store_true", help="Only print environment checks.")
    args = parser.parse_args()

    python = venv_python()
    if not args.skip_install:
        if not VENV.exists():
            venv.EnvBuilder(with_pip=True).create(VENV)
        run([str(python), "-m", "pip", "install", "--upgrade", "pip"])
        run([str(python), "-m", "pip", "install", "-r", str(ROOT / "requirements.txt")])

    system = platform.system()
    if system == "Linux" and not (shutil.which("wl-copy") or shutil.which("xclip")):
        print("Linux PNG clipboard copy needs wl-copy or xclip. Install one with your package manager.")
    elif system == "Darwin":
        print("macOS global hotkeys may need Accessibility permission for the packaged helper.")
    elif system == "Windows":
        print("Windows helper uses PowerShell/.NET for PNG clipboard copy.")

    if not (os.environ.get("GODOT_BIN") or shutil.which("godot4") or shutil.which("godot") or has_local_godot()):
        print("Godot was not found on PATH. Set GODOT_BIN or run the platform setup script before packaging.")
    print(f"Python environment ready: {python}" if python.exists() else f"Python environment will be created at: {python}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
