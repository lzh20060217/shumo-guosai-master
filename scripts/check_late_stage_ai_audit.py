#!/usr/bin/env python3
"""Validate the late-stage 20-item AI-assisted competition audit record."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


EXPECTED_IDS = tuple(
    [f"L1-{i:02d}" for i in range(1, 5)]
    + [f"L2-{i:02d}" for i in range(1, 5)]
    + [f"L3-{i:02d}" for i in range(1, 6)]
    + [f"L4-{i:02d}" for i in range(1, 4)]
    + [f"L5-{i:02d}" for i in range(1, 5)]
)
REQUIRED_FIELDS = {
    "dimension_id",
    "dimension",
    "item_id",
    "check_name",
    "check_scope",
    "status",
    "location",
    "issue_summary",
    "remediation",
    "evidence_path",
    "reviewer",
    "reviewed_at",
    "basis_level",
}
ALLOWED_STATUSES = {
    "NOT_REVIEWED",
    "PASS",
    "ISSUE",
    "NEEDS_CONFIRMATION",
    "NOT_APPLICABLE",
}
RELEASE_STATUSES = {"PASS", "NOT_APPLICABLE"}


def validate(path: Path, mode: str) -> tuple[list[str], list[str]]:
    failures: list[str] = []
    warnings: list[str] = []
    if not path.is_file():
        return [f"missing audit CSV: {path}"], warnings

    with path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        fields = set(reader.fieldnames or [])
        missing_fields = sorted(REQUIRED_FIELDS - fields)
        if missing_fields:
            failures.append(f"missing columns: {', '.join(missing_fields)}")
        rows = list(reader)

    ids = [row.get("item_id", "").strip() for row in rows]
    if len(ids) != len(EXPECTED_IDS):
        failures.append(f"expected 20 rows; found {len(ids)}")
    duplicates = sorted({item_id for item_id in ids if ids.count(item_id) > 1})
    if duplicates:
        failures.append(f"duplicate item_id values: {', '.join(duplicates)}")
    missing_ids = sorted(set(EXPECTED_IDS) - set(ids))
    extra_ids = sorted(set(ids) - set(EXPECTED_IDS))
    if missing_ids:
        failures.append(f"missing item_id values: {', '.join(missing_ids)}")
    if extra_ids:
        failures.append(f"unexpected item_id values: {', '.join(extra_ids)}")

    for row in rows:
        item_id = row.get("item_id", "<unknown>").strip() or "<blank>"
        status = row.get("status", "").strip().upper()
        if status not in ALLOWED_STATUSES:
            failures.append(f"{item_id}: invalid status {status!r}")
            continue
        if mode == "release":
            if status not in RELEASE_STATUSES:
                failures.append(f"{item_id}: release-blocking status {status}")
            for field in ("evidence_path", "reviewer", "reviewed_at"):
                if not row.get(field, "").strip():
                    failures.append(f"{item_id}: release requires {field}")
            if status == "NOT_APPLICABLE" and not row.get("issue_summary", "").strip():
                failures.append(f"{item_id}: NOT_APPLICABLE requires a reason in issue_summary")
        elif status == "NOT_REVIEWED":
            warnings.append(f"{item_id}: not reviewed yet")

    return failures, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", required=True, type=Path)
    parser.add_argument("--mode", choices=("snapshot", "release"), default="snapshot")
    args = parser.parse_args()
    path = args.csv.expanduser().resolve()
    failures, warnings = validate(path, args.mode)
    print(f"mode={args.mode} csv={path}")
    print(f"items={len(EXPECTED_IDS)} failures={len(failures)} warnings={len(warnings)}")
    for item in failures:
        print(f"FAIL {item}")
    for item in warnings:
        print(f"WARN {item}")
    if failures:
        return 1
    print("PASS late-stage AI-assisted audit record structure")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
