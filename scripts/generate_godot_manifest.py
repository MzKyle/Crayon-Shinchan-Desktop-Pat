#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "godot_pet" / "assets" / "actions.json"
NUMBER_RE = re.compile(r"(\d+)")


def natural_key(path: Path) -> list[tuple[int, int | str]]:
    parts: list[tuple[int, int | str]] = []
    for part in NUMBER_RE.split(path.name):
        if not part:
            continue
        parts.append((1, int(part)) if part.isdigit() else (0, part.casefold()))
    return parts


def frames(relative_dir: str) -> list[str]:
    root = ROOT / "resource_hd" / relative_dir
    return [str(Path(relative_dir) / path.name) for path in sorted(root.glob("*.png"), key=natural_key)]


def action(
    name: str,
    resource: str,
    size: tuple[int, int],
    fps: float,
    loop: bool = True,
    loop_start: int = -1,
    next_action: str = "",
) -> dict:
    return {
        "name": name,
        "resource": resource,
        "size": list(size),
        "fps": fps,
        "loop": loop,
        "loop_start": loop_start,
        "next_action": next_action,
        "frames": frames(resource),
    }


def main() -> int:
    manifest = {
        "version": 1,
        "actions": {
            "idle": action("闲置", "xianzhi", (130, 130), 10.0),
            "walk_left": action("向左散步", "sanbu/zuo", (130, 130), 10.0),
            "walk_right": action("向右散步", "sanbu/you", (130, 130), 10.0),
            "mischief_grab": action("费力抢鼠标", "mischief_grab", (190, 160), 8.0),
            "fall": action("下落", "xialuo", (150, 150), 30.0, next_action="idle"),
            "exercise": action("运动", "yundong", (150, 180), 8.0),
            "eat": action("吃饭", "eat", (160, 90), 40.0, loop=True, loop_start=122),
            "sleep": action("睡觉", "sleep", (162, 149), 50.0, loop=False),
            "wake": action("唤醒", "waken", (162, 149), 33.0, loop=False, next_action="idle"),
            "pipi": action("屁屁舞", "pipi", (300, 130), 40.0),
            "transform": action("动感光波", "xiandanchaoren", (160, 130), 60.0),
            "snack": action("偷吃宵夜", "snack", (400, 200), 50.0, loop=False, next_action="sleep"),
            "meet": action("见到小白", "meet", (150, 150), 30.0, loop=False, next_action="idle"),
            "xiaobai": action("小白", "xiaobai", (125, 85), 50.0),
        },
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT}")
    for key, value in manifest["actions"].items():
        print(f"{key}: {len(value['frames'])} frames")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
