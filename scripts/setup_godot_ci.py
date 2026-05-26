#!/usr/bin/env python3
"""Download Godot and export templates for CI packaging jobs."""

from __future__ import annotations

import argparse
import os
import platform
import shutil
import sys
import urllib.request
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools" / "godot-ci"


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        return
    print(f"Downloading {url}")
    urllib.request.urlretrieve(url, dest)


def template_version(version: str) -> str:
    return version.replace("-stable", ".stable")


def template_dir(version: str) -> Path:
    suffix = template_version(version)
    system = platform.system()
    if system == "Windows":
        base = Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming")) / "Godot"
    elif system == "Darwin":
        base = Path.home() / "Library" / "Application Support" / "Godot"
    else:
        base = Path.home() / ".local" / "share" / "godot"
    return base / "export_templates" / suffix


def godot_archive_name(version: str) -> tuple[str, str]:
    system = platform.system()
    if system == "Windows":
        return f"Godot_v{version}_win64.exe.zip", f"Godot_v{version}_win64.exe"
    if system == "Darwin":
        return f"Godot_v{version}_macos.universal.zip", "Godot.app/Contents/MacOS/Godot"
    return f"Godot_v{version}_linux.x86_64.zip", f"Godot_v{version}_linux.x86_64"


def install_godot(version: str) -> Path:
    archive_name, executable_name = godot_archive_name(version)
    archive = TOOLS / archive_name
    url = f"https://github.com/godotengine/godot/releases/download/{version}/{archive_name}"
    download(url, archive)
    out_dir = TOOLS / archive.stem
    if not out_dir.exists():
        with zipfile.ZipFile(archive) as zf:
            zf.extractall(out_dir)
    godot = out_dir / executable_name
    if not godot.exists():
        matches = list(out_dir.rglob(Path(executable_name).name))
        if not matches:
            raise FileNotFoundError(f"Godot executable not found in {out_dir}")
        godot = matches[0]
    godot.chmod(godot.stat().st_mode | 0o755)
    return godot


def install_templates(version: str) -> Path:
    archive_name = f"Godot_v{version}_export_templates.tpz"
    archive = TOOLS / archive_name
    url = f"https://github.com/godotengine/godot/releases/download/{version}/{archive_name}"
    download(url, archive)
    install_dir = template_dir(version)
    install_dir.mkdir(parents=True, exist_ok=True)
    tmp_dir = TOOLS / f"templates-{template_version(version)}"
    if not tmp_dir.exists():
        with zipfile.ZipFile(archive) as zf:
            zf.extractall(tmp_dir)
    for path in tmp_dir.rglob("*"):
        if path.is_file():
            dest = install_dir / path.name
            shutil.copy2(path, dest)
            if not dest.suffix.lower() in [".txt", ".md"]:
                dest.chmod(dest.stat().st_mode | 0o755)
    return install_dir


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--github-output", action="store_true")
    args = parser.parse_args()

    version = os.environ.get("GODOT_VERSION", "4.6.3-stable")
    godot = install_godot(version)
    templates = install_templates(version)
    print(f"GODOT_BIN={godot}")
    print(f"GODOT_EXPORT_TEMPLATE_DIR={templates}")

    if args.github_output and os.environ.get("GITHUB_OUTPUT"):
        with Path(os.environ["GITHUB_OUTPUT"]).open("a", encoding="utf-8") as handle:
            handle.write(f"godot_bin={godot}\n")
            handle.write(f"template_dir={templates}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
