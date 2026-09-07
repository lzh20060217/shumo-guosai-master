#!/usr/bin/env python3
"""Initialize a new competition project from the bundled snapshot safely."""

from __future__ import annotations

import argparse
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path, help="new, non-existing project directory")
    args = parser.parse_args()

    skill_root = Path(__file__).resolve().parents[1]
    template_root = skill_root / "assets" / "project-template"
    destination = args.destination.expanduser().resolve()

    if not template_root.is_dir():
        print(f"ERROR: bundled template is missing: {template_root}")
        return 3
    if destination.exists():
        print(f"ERROR: destination already exists; refusing to overwrite: {destination}")
        return 2

    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(template_root, destination)
    for relative in ("paper", "paper/latex", "deliverables"):
        (destination / relative).mkdir(parents=True, exist_ok=True)

    ai_log = destination / "ai_usage_log.md"
    if not ai_log.exists():
        ai_log.write_text(
            "# AI 使用日志\n\n"
            "按发生顺序记录时间、环节、工具/模型、提示词摘要、用途、人工修改、核验方式和对应文件。\n",
            encoding="utf-8",
        )

    origin = {
        "skill": "shumo-guosai-master",
        "skill_version": "1.1.0",
        "initialized_at": datetime.now(timezone.utc).isoformat(),
        "template": "math-modeling-competition snapshot 2026-09-06",
    }
    (destination / ".skill-origin.json").write_text(
        json.dumps(origin, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    print(f"Initialized project: {destination}")
    print("Next: add current official rules, problem statement, and raw data; then run G0.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
