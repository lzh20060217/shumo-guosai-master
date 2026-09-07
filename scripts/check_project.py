#!/usr/bin/env python3
"""Cross-platform structural checks for a shumo-guosai-master project."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


REQUIRED = (
    "competition/competition-profile.md",
    "problem/task-requirements.csv",
    "data/data-inventory.csv",
    "data/raw-hashes.csv",
    "data/preprocessing-plan.md",
    "data/PREPROCESSING_STATUS.txt",
    "model/model-plan.md",
    "model/PLAN_STATUS.txt",
    "outputs/result-summary.json",
    "outputs/artifact-manifest.csv",
    "reports/verification-report.md",
    "reports/claim-audit.csv",
    "reports/late-stage-ai-self-check.csv",
    "writing/paper-outline.md",
    "writing/claim-evidence-matrix.csv",
    "ai_usage_log.md",
)


def status_value(path: Path) -> str:
    if not path.is_file():
        return "MISSING"
    text = path.read_text(encoding="utf-8-sig", errors="replace").strip().upper()
    for value in ("FROZEN", "DRAFT", "NOT_STARTED", "IN_PROGRESS", "BLOCKED", "PASS"):
        if re.search(rf"\b{value}\b", text):
            return value
    return "UNKNOWN"


def gate_statuses(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    found: dict[str, str] = {}
    for line in text.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        match = re.match(r"G([0-6])\b", cells[0], flags=re.IGNORECASE)
        if match:
            found[f"G{match.group(1)}"] = cells[1].upper()
    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--mode", choices=("snapshot", "release"), default="snapshot")
    args = parser.parse_args()
    root = args.root.expanduser().resolve()

    failures: list[str] = []
    warnings: list[str] = []
    if not root.is_dir():
        print(f"FAIL root does not exist: {root}")
        return 2

    for relative in REQUIRED:
        path = root / relative
        if not path.is_file():
            failures.append(f"missing required file: {relative}")
        elif path.stat().st_size == 0:
            failures.append(f"empty required file: {relative}")

    model_status = status_value(root / "model/PLAN_STATUS.txt")
    data_status = status_value(root / "data/PREPROCESSING_STATUS.txt")
    gates = gate_statuses(root / "PROJECT_STATUS.md")

    audit_path = root / "reports/late-stage-ai-self-check.csv"
    audit_script = Path(__file__).with_name("check_late_stage_ai_audit.py")
    if audit_path.is_file() and audit_script.is_file():
        audit = subprocess.run(
            [
                sys.executable,
                str(audit_script),
                "--csv",
                str(audit_path),
                "--mode",
                args.mode,
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        audit_lines = audit.stdout.splitlines()
        if audit.returncode != 0:
            details = [line[5:] for line in audit_lines if line.startswith("FAIL ")]
            failures.append(
                "late-stage AI audit failed: " + ("; ".join(details) or "validator error")
            )
        elif args.mode == "snapshot":
            pending = sum(line.startswith("WARN ") for line in audit_lines)
            if pending:
                warnings.append(f"late-stage AI audit has {pending} item(s) not reviewed yet")
    elif not audit_script.is_file():
        failures.append(f"missing bundled validator: {audit_script}")

    if args.mode == "release":
        if model_status != "FROZEN" or data_status != "FROZEN":
            failures.append(
                f"release requires synchronized FROZEN statuses; model={model_status}, preprocessing={data_status}"
            )
        for gate in ("G0", "G1", "G2", "G3", "G4", "G5"):
            if gates.get(gate) != "PASS":
                failures.append(f"release requires {gate}=PASS; found {gates.get(gate, 'MISSING')}")
    else:
        if model_status != "FROZEN" or data_status != "FROZEN":
            warnings.append(
                f"plans are not frozen (expected for a blank/active snapshot): model={model_status}, preprocessing={data_status}"
            )

    print(f"mode={args.mode} root={root}")
    print(f"required_files={len(REQUIRED)} failures={len(failures)} warnings={len(warnings)}")
    for item in failures:
        print(f"FAIL {item}")
    for item in warnings:
        print(f"WARN {item}")
    if failures:
        return 1
    print("PASS basic cross-platform project check")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
