import json
import pathlib
import tomllib
import unittest
import csv
import hashlib
import re
import shutil
import subprocess
import sys
import tempfile


ROOT = pathlib.Path(__file__).resolve().parents[1]


class WorkflowContractTests(unittest.TestCase):
    def test_six_agent_contracts_parse_and_match_names(self) -> None:
        expected = {
            "literature-researcher.toml": "literature_researcher",
            "model-architect.toml": "model_architect",
            "model-implementer.toml": "model_implementer",
            "model-verifier.toml": "model_verifier",
            "paper-outline-writer.toml": "paper_outline_writer",
            "release-packager.toml": "release_packager",
        }
        agent_dir = ROOT / ".codex" / "agents"
        self.assertEqual({p.name for p in agent_dir.glob("*.toml")}, set(expected))
        for filename, internal_name in expected.items():
            config = tomllib.loads((agent_dir / filename).read_text(encoding="utf-8"))
            self.assertEqual(config["name"], internal_name)
            self.assertTrue(config["developer_instructions"].strip())

    def test_required_handoff_artifacts_exist(self) -> None:
        required = [
            "WORKFLOW-GUIDE.md",
            "competition/competition-profile.md",
            "problem/task-requirements.csv",
            "data/data-inventory.csv",
            "data/raw-hashes.csv",
            "data/preprocessing-plan.md",
            "data/PREPROCESSING_STATUS.txt",
            "model/algorithm-evidence-request.csv",
            "model/protected-invariants.md",
            "model/implementation-defaults.md",
            "model/implementation-readiness.md",
            "model/readiness/implementer-review.md",
            "model/readiness/verifier-review.md",
            "model/g2-approval.json",
            "model/decision-register.csv",
            "model/complexity-budget.csv",
            "research/algorithm-evidence-coverage.csv",
            "research/search-log.csv",
            "research/algorithm-briefs/algorithm-brief-template.md",
            "research/library/books/book-index.csv",
            "research/library/papers/.gitkeep",
            "outputs/result-summary.json",
            "outputs/artifact-manifest.csv",
            "reports/verification-report.md",
            "reports/claim-audit.csv",
            "reports/late-stage-ai-self-check.csv",
            "writing/paper-outline.md",
            "writing/claim-evidence-matrix.csv",
            "coordination/README.md",
            "coordination/CONTROL-BOARD.md",
            "coordination/thread-registry.csv",
            "coordination/dispatch-log.csv",
            "coordination/path-ownership.csv",
            "coordination/sync-ledger.csv",
            "coordination/user-authority-log.csv",
            "coordination/role-thread-prompts.md",
            "coordination/dispatches/dispatch-template.md",
            "coordination/receipts/receipt-template.md",
            ".agents/skills/math-modeling-competition/references/thread-coordination-v1.md",
        ]
        missing = [path for path in required if not (ROOT / path).exists()]
        self.assertEqual(missing, [])

    def test_late_stage_ai_self_check_contract(self) -> None:
        path = ROOT / "reports" / "late-stage-ai-self-check.csv"
        with path.open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        expected_ids = {
            *{f"L1-{i:02d}" for i in range(1, 5)},
            *{f"L2-{i:02d}" for i in range(1, 5)},
            *{f"L3-{i:02d}" for i in range(1, 6)},
            *{f"L4-{i:02d}" for i in range(1, 4)},
            *{f"L5-{i:02d}" for i in range(1, 5)},
        }
        self.assertEqual(len(rows), 20)
        self.assertEqual({row["item_id"] for row in rows}, expected_ids)
        self.assertTrue(all(row["status"] == "NOT_REVIEWED" for row in rows))
        self.assertTrue(all(row["basis_level"] for row in rows))
        validator = ROOT.parents[1] / "scripts" / "check_late_stage_ai_audit.py"
        snapshot = subprocess.run(
            [sys.executable, str(validator), "--csv", str(path), "--mode", "snapshot"],
            check=False,
            capture_output=True,
            text=True,
        )
        release = subprocess.run(
            [sys.executable, str(validator), "--csv", str(path), "--mode", "release"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(snapshot.returncode, 0, snapshot.stdout + snapshot.stderr)
        self.assertEqual(release.returncode, 1, release.stdout + release.stderr)

    def test_result_summary_template_is_valid_json(self) -> None:
        payload = json.loads((ROOT / "outputs" / "result-summary.json").read_text(encoding="utf-8"))
        self.assertIn(payload["project_status"], {"NOT_RUN", "IN_PROGRESS", "COMPLETE"})
        self.assertIn("task_results", payload)

    def test_task_trace_has_separate_gate_statuses(self) -> None:
        with (ROOT / "problem" / "task-requirements.csv").open(encoding="utf-8", newline="") as handle:
            fields = next(csv.reader(handle))
        for gate in range(6):
            self.assertIn(f"g{gate}_status", fields)
        self.assertIn("overall_status", fields)

    def test_paper_outline_has_stable_sections(self) -> None:
        outline = (ROOT / "writing" / "paper-outline.md").read_text(encoding="utf-8")
        required = [
            "ABSTRACT", "PROBLEM", "ASSUMPTIONS", "SYMBOLS", "DATA", "BASELINE",
            "FINAL_MODEL", "SOLUTION", "RESULTS", "VERIFICATION",
            "SENSITIVITY_ROBUSTNESS_ABLATION", "LIMITATIONS", "CONCLUSION", "REFERENCES",
        ]
        for section in required:
            self.assertIn(f"[{section}]", outline)

    def test_normative_references_define_g0_through_g6(self) -> None:
        gates = (
            ROOT
            / ".agents"
            / "skills"
            / "math-modeling-competition"
            / "references"
            / "workflow-gates-v2.md"
        ).read_text(encoding="utf-8")
        for gate in range(7):
            self.assertIn(f"G{gate}", gates)

    def test_persistent_role_task_coordination_contract(self) -> None:
        roles = {
            "coordinator", "literature_researcher", "model_architect",
            "model_implementer", "model_verifier", "paper_outline_writer",
            "release_packager",
        }
        with (ROOT / "coordination/thread-registry.csv").open(encoding="utf-8", newline="") as handle:
            registry = list(csv.DictReader(handle))
        self.assertEqual({row["role"] for row in registry}, roles)
        self.assertEqual(len(registry), 7)
        self.assertTrue(all(row["environment"] == "LOCAL_SHARED_PROJECT" for row in registry))

        schemas = {
            "coordination/thread-registry.csv": {
                "protocol_version", "role", "thread_id", "host_id", "generation",
                "environment", "status", "role_contract_path", "role_contract_sha256",
            },
            "coordination/dispatch-log.csv": {
                "dispatch_id", "gate", "mode", "to_role", "role_generation",
                "thread_id", "request_file", "request_sha256", "input_bundle_sha256",
                "exclusive_scope_id", "user_authorization_id", "receipt_file",
            },
            "coordination/path-ownership.csv": {
                "scope_id", "path_pattern", "owner_role", "merge_role", "concurrent_policy",
            },
            "coordination/sync-ledger.csv": {
                "sync_id", "receipt_id", "receipt_sha256", "dispatch_id", "role", "decision",
            },
            "coordination/user-authority-log.csv": {
                "authorization_id", "authorization_type", "status", "user_request_quote",
                "mode", "label", "bound_bundle_sha256", "bound_dispatch_id",
                "max_uses", "used_count",
            },
        }
        for relative, required_fields in schemas.items():
            with (ROOT / relative).open(encoding="utf-8", newline="") as handle:
                fields = set(next(csv.reader(handle)))
            self.assertTrue(required_fields.issubset(fields), relative)

        with (ROOT / "coordination/path-ownership.csv").open(encoding="utf-8", newline="") as handle:
            ownership = list(csv.DictReader(handle))
        path_tokens = [
            token.strip()
            for row in ownership
            for token in row["path_pattern"].split(";")
            if token.strip()
        ]
        self.assertEqual(len(path_tokens), len(set(path_tokens)))
        self.assertNotIn("tests/**", path_tokens)
        self.assertNotIn("experiments/**", path_tokens)

        for path in (ROOT / ".codex/agents").glob("*.toml"):
            instructions = tomllib.loads(path.read_text(encoding="utf-8"))["developer_instructions"]
            self.assertIn("coordination/thread-registry.csv", instructions, path.name)
            self.assertIn("coordination/dispatch-log.csv", instructions, path.name)
            self.assertIn("coordination/receipts/", instructions, path.name)

    def test_literature_agent_has_safe_download_contract(self) -> None:
        agent = tomllib.loads(
            (ROOT / ".codex" / "agents" / "literature-researcher.toml").read_text(encoding="utf-8")
        )
        instructions = agent["developer_instructions"]
        self.assertIn("download-paper.ps1", instructions)
        self.assertIn("research/library/papers/", instructions)
        self.assertIn("SHA-256", instructions)
        self.assertTrue(
            ROOT.joinpath(
                ".agents", "skills", "math-modeling-competition", "scripts", "download-paper.ps1"
            ).exists()
        )
        self.assertTrue((ROOT / "research" / "library" / "download-log.csv").exists())

    def test_algorithm_evidence_loop_contract(self) -> None:
        model_agent = tomllib.loads(
            (ROOT / ".codex" / "agents" / "model-architect.toml").read_text(encoding="utf-8")
        )["developer_instructions"]
        literature_agent = tomllib.loads(
            (ROOT / ".codex" / "agents" / "literature-researcher.toml").read_text(encoding="utf-8")
        )["developer_instructions"]
        for marker in [
            "model/algorithm-evidence-request.csv",
            "candidate_id",
            "component_id",
            "STALE",
            "EVIDENCE_COVERED",
        ]:
            self.assertIn(marker, model_agent)
        for marker in [
            "research/search-log.csv",
            "research/algorithm-evidence-coverage.csv",
            "FOUNDATIONAL",
            "TEXTBOOK_OR_MONOGRAPH",
            "TASK_APPLICATION",
            "COMPARATIVE_OR_LIMITATION",
            "SHA-256",
        ]:
            self.assertIn(marker, literature_agent)

    def test_algorithm_evidence_csv_schemas(self) -> None:
        contracts = {
            "model/algorithm-evidence-request.csv": {
                "request_id", "round_id", "plan_version", "task_id", "candidate_id",
                "component_id", "tier_role", "selection_eligible", "algorithm_name", "keywords_zh", "keywords_en",
                "theory_questions", "assumptions_to_verify", "blocking", "status",
            },
            "research/algorithm-evidence-coverage.csv": {
                "coverage_id", "request_id", "round_id", "plan_version", "component_id",
                "evidence_id", "evidence_role", "evidence_direction", "independent_group",
                "fulltext_status", "chapter_pages", "knowledge_card", "limitations",
                "task_transfer_judgment", "coverage_status", "conflict_resolution",
                "resolution_status",
            },
            "research/search-log.csv": {
                "search_id", "request_id", "round_id", "search_date", "database",
                "query_language", "query", "query_type", "negative_result", "stop_reason",
            },
            "research/library/books/book-index.csv": {
                "book_id", "title", "authors", "edition", "local_path",
                "license_or_access_note", "sha256", "notes_path", "status",
            },
        }
        for relative, required_fields in contracts.items():
            with (ROOT / relative).open(encoding="utf-8", newline="") as handle:
                fields = set(next(csv.reader(handle)))
            self.assertTrue(required_fields.issubset(fields), relative)

    def test_g2_readiness_artifacts_have_static_contracts(self) -> None:
        readiness = (ROOT / "model" / "implementation-readiness.md").read_text(encoding="utf-8")
        for marker in [
            "READY_FOR_USER_REVIEW",
            "NEEDS_REVISION",
            "BLOCKED_BY_DATA_OR_AUTHORITY",
            "实施者签收",
            "验证者签收",
            "模型方案规范化 SHA-256",
            "预处理契约规范化 SHA-256",
            "受保护决策 SHA-256",
            "实现默认项 SHA-256",
            "复杂度预算 SHA-256",
        ]:
            self.assertIn(marker, readiness)
        invariants = (ROOT / "model" / "protected-invariants.md").read_text(encoding="utf-8")
        self.assertIn("A 类", invariants)
        self.assertIn("change request", invariants)
        defaults = (ROOT / "model" / "implementation-defaults.md").read_text(encoding="utf-8")
        self.assertIn("B 类", defaults)
        for relative, role in [
            ("model/readiness/implementer-review.md", "model_implementer"),
            ("model/readiness/verifier-review.md", "model_verifier"),
        ]:
            review = (ROOT / relative).read_text(encoding="utf-8")
            self.assertIn(role, review)
            self.assertIn("PREFREEZE_READINESS", review)
            self.assertIn("used_formal_results", review)
        approval = json.loads((ROOT / "model" / "g2-approval.json").read_text(encoding="utf-8"))
        self.assertEqual(approval["status"], "NOT_APPROVED")
        self.assertIn("readiness_bundle_sha256", approval)

    def test_g2_readiness_csv_schemas(self) -> None:
        contracts = {
            "model/decision-register.csv": {
                "decision_id", "plan_version", "preprocessing_version", "task_id",
                "decision_class", "topic_group", "topic", "applicability",
                "protected_invariant_id", "selected_value", "na_reason", "rationale",
                "source_refs", "owner", "resolution_status", "requires_user_approval",
                "equivalence_test_id", "affects_rank", "affects_objective",
                "affects_prediction", "affects_threshold", "affects_model_selection",
                "change_request_id", "updated_at",
            },
            "model/complexity-budget.csv": {
                "budget_id", "plan_version", "preprocessing_version", "task_id",
                "candidate_id", "tier", "role", "route_status", "entry_point", "command",
                "interface_contract_id", "outer_split_id", "evaluation_unit", "primary_metric_id",
                "single_fit_minutes", "outer_fits", "inner_fits", "bootstrap_or_simulation_runs",
                "total_fit_count", "expected_total_minutes", "memory_gb", "disk_gb",
                "available_window_minutes", "window_fraction", "safety_reserve_fraction",
                "effect_gate", "interval_rule", "stability_gate", "calibration_gate", "cost_gate",
                "run_condition", "fallback_tier", "over_budget_action", "estimation_basis", "status",
            },
        }
        for relative, required_fields in contracts.items():
            with (ROOT / relative).open(encoding="utf-8", newline="") as handle:
                fields = set(next(csv.reader(handle)))
            self.assertTrue(required_fields.issubset(fields), relative)

    def test_verifier_enforces_algorithm_evidence_chain(self) -> None:
        verifier = (
            ROOT
            / ".agents"
            / "skills"
            / "math-modeling-competition"
            / "scripts"
            / "verify-project.ps1"
        ).read_text(encoding="utf-8")
        for marker in [
            "algorithm-evidence-readiness",
            "FOUNDATIONAL",
            "COMPARATIVE_OR_LIMITATION",
            "PDF_VERIFIED",
            "orphan or invalid paper",
            "book access or index invalid",
            "g2-readiness-files",
            "g2-readiness-status-and-signoff",
            "g2-protected-invariants",
            "g2-a-class-decisions",
            "g2-tier-budget-and-fallback",
            "g2-readiness-review-hashes",
            "g2-independent-prefreeze-reviews",
            "g2-user-approval-binding",
            "READY_FOR_USER_REVIEW",
            "TIER_1",
            "safety_reserve_fraction",
            "Get-NormalizedFileSha256",
            "coordination-files-and-schema",
            "thread-registry-uniqueness",
            "coordination-path-ownership",
            "dispatch-integrity",
            "dispatch-exclusive-scope",
            "receipt-and-sync-binding",
            "status-sync-binding",
            "user-authority-ledger",
            "late-stage-ai-audit-structure",
            "late-stage-ai-audit-completion",
        ]:
            self.assertIn(marker, verifier)
        self.assertLess(verifier.index("$rootPrefix ="), verifier.index("$implementationFullPath.StartsWith($rootPrefix"))


class G2ReadinessBehaviorTests(unittest.TestCase):
    """Exercise the verifier against a minimal valid G2-B bundle and key failures."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.powershell = shutil.which("powershell.exe") or shutil.which("powershell")
        if cls.powershell is None:
            raise unittest.SkipTest("Windows PowerShell is not available")

    def setUp(self) -> None:
        self.tempdir = tempfile.TemporaryDirectory(prefix=".g2-readiness-", dir=ROOT)
        self.fixture = pathlib.Path(self.tempdir.name) / "project"
        shutil.copytree(
            ROOT,
            self.fixture,
            ignore=shutil.ignore_patterns(
                "__pycache__", "*.pyc", "releases", pathlib.Path(self.tempdir.name).name
            ),
        )
        shutil.rmtree(self.fixture / "outputs/logs", ignore_errors=True)
        self._make_ready_fixture()

    def tearDown(self) -> None:
        self.tempdir.cleanup()

    @staticmethod
    def _normalized_hash(path: pathlib.Path) -> str:
        text = path.read_text(encoding="utf-8-sig").replace("\r\n", "\n").replace("\r", "\n")
        match = re.search(
            r"<!--\s*G2-CONTRACT-BEGIN\s*-->(.*?)<!--\s*G2-CONTRACT-END\s*-->",
            text,
            flags=re.DOTALL,
        )
        if match:
            text = match.group(1)
        lines = [line.rstrip() for line in text.split("\n")]
        while lines and lines[-1] == "":
            lines.pop()
        normalized = "\n".join(lines) + "\n"
        return hashlib.sha256(normalized.encode("utf-8")).hexdigest()

    def _write_csv(self, relative: str, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
        path = self.fixture / relative
        with path.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)

    def _make_ready_fixture(self) -> None:
        for relative in ["model/model-plan.md", "data/preprocessing-plan.md"]:
            path = self.fixture / relative
            text = path.read_text(encoding="utf-8")
            path.write_text(text.replace("- 版本：v0", "- 版本：v1", 1), encoding="utf-8")

        task_fields = [
            "task_id", "requirement", "input", "required_output", "hard_constraint", "metric",
            "evidence_ids", "model_section", "implementation_path", "verification_ids",
            "paper_section", "g0_status", "g1_status", "g2_status", "g3_status",
            "g4_status", "g5_status", "overall_status",
        ]
        self._write_csv(
            "problem/task-requirements.csv",
            task_fields,
            [{field: ("T1" if field == "task_id" else "NOT_STARTED" if field.endswith("status") else "fixture") for field in task_fields}],
        )

        (self.fixture / "model/protected-invariants.md").write_text(
            "# Protected invariants\n\n| invariant_id | task_id | rule |\n|---|---|---|\n"
            "| INV-T1 | T1 | Ranking, objective, split and claim scope require user approval. |\n",
            encoding="utf-8",
        )
        (self.fixture / "model/implementation-defaults.md").write_text(
            "# Implementation defaults\n\nB-class choices require equivalence tests.\n",
            encoding="utf-8",
        )
        (self.fixture / "tests/contract/tier0.txt").write_text("tier 0 interface\n", encoding="utf-8")
        (self.fixture / "tests/contract/tier1.txt").write_text("tier 1 interface\n", encoding="utf-8")

        decision_fields = [
            "decision_id", "plan_version", "preprocessing_version", "task_id", "decision_class",
            "topic_group", "topic", "applicability", "protected_invariant_id", "selected_value",
            "na_reason", "rationale", "source_refs", "owner", "resolution_status",
            "requires_user_approval", "equivalence_test_id", "affects_rank", "affects_objective",
            "affects_prediction", "affects_threshold", "affects_model_selection", "change_request_id",
            "updated_at",
        ]
        topics = [
            "STUDY_TARGET", "INCLUSION_ALIGNMENT", "SPLIT_LEAKAGE", "MODEL_OBJECTIVE",
            "PRIMARY_METRIC_DECISION", "TIER_FAIRNESS_FALLBACK", "CLAIM_SCOPE",
        ]
        decision_rows = []
        for index, topic in enumerate(topics, start=1):
            row = {field: "NO" for field in decision_fields}
            row.update(
                decision_id=f"A-{index}", plan_version="v1", preprocessing_version="v1",
                task_id="T1", decision_class="A", topic_group=topic, topic=topic,
                applicability="APPLICABLE", protected_invariant_id="INV-T1",
                selected_value="fixture-value", na_reason="NONE", rationale="fixture-rationale",
                source_refs="E1", owner="model_architect", resolution_status="RESOLVED",
                requires_user_approval="YES", equivalence_test_id="NONE",
                change_request_id="NONE", updated_at="2026-08-13T00:00:00+08:00",
            )
            decision_rows.append(row)
        self._write_csv("model/decision-register.csv", decision_fields, decision_rows)

        budget_fields = [
            "budget_id", "plan_version", "preprocessing_version", "task_id", "candidate_id", "tier",
            "role", "route_status", "entry_point", "command", "interface_contract_id",
            "outer_split_id", "evaluation_unit", "primary_metric_id", "single_fit_minutes",
            "outer_fits", "inner_fits", "bootstrap_or_simulation_runs", "total_fit_count",
            "expected_total_minutes", "memory_gb", "disk_gb", "available_window_minutes",
            "window_fraction", "safety_reserve_fraction", "effect_gate", "interval_rule",
            "stability_gate", "calibration_gate", "cost_gate", "run_condition", "fallback_tier",
            "over_budget_action", "estimation_basis", "status",
        ]
        common = {field: "NONE" for field in budget_fields}
        common.update(
            plan_version="v1", preprocessing_version="v1", task_id="T1", role="CORE",
            route_status="PLANNED", entry_point="src.main:main", command="python -m src.main",
            outer_split_id="SPLIT-1", evaluation_unit="row", primary_metric_id="METRIC-1",
            outer_fits="1", inner_fits="0", bootstrap_or_simulation_runs="0", memory_gb="1",
            disk_gb="1", available_window_minutes="100", safety_reserve_fraction="0.30",
            effect_gate="PRE_REGISTERED", interval_rule="FIXED", stability_gate="FIXED",
            calibration_gate="FIXED", cost_gate="FIXED", run_condition="ALWAYS",
            estimation_basis="synthetic smoke timing", status="READY",
        )
        tier0 = dict(common)
        tier0.update(
            budget_id="B0", candidate_id="C0", tier="TIER_0", interface_contract_id="tests/contract/tier0.txt",
            single_fit_minutes="1", total_fit_count="10", expected_total_minutes="10",
            window_fraction="0.10", fallback_tier="NONE", over_budget_action="STOP_AND_REPORT",
        )
        tier1 = dict(common)
        tier1.update(
            budget_id="B1", candidate_id="C1", tier="TIER_1", interface_contract_id="tests/contract/tier1.txt",
            single_fit_minutes="2", total_fit_count="20", expected_total_minutes="40",
            window_fraction="0.40", fallback_tier="TIER_0", over_budget_action="FALLBACK_TO_TIER_0",
        )
        self._write_csv("model/complexity-budget.csv", budget_fields, [tier0, tier1])
        self._refresh_readiness_hashes()

    def _refresh_readiness_hashes(self) -> None:
        entries = [
            ("model_plan_sha256", "model/model-plan.md"),
            ("preprocessing_plan_sha256", "data/preprocessing-plan.md"),
            ("protected_invariants_sha256", "model/protected-invariants.md"),
            ("implementation_defaults_sha256", "model/implementation-defaults.md"),
            ("complexity_budget_sha256", "model/complexity-budget.csv"),
        ]
        hashes = {label: self._normalized_hash(self.fixture / relative) for label, relative in entries}
        bundle_input = "".join(
            f"{relative}\0{hashes[label]}\n" for label, relative in entries
        )
        bundle = hashlib.sha256(bundle_input.encode("utf-8")).hexdigest()
        readiness_lines = [
            "# G2-B readiness fixture", "- readiness_id: READY-v1-R1",
            "- status: READY_FOR_USER_REVIEW", "- implementer_signoff: YES",
            "- verifier_signoff: YES",
        ]
        readiness_lines.extend(f"- {label}: {value}" for label, value in hashes.items())
        readiness_lines.append(f"- readiness_bundle_sha256: {bundle}")
        (self.fixture / "model/implementation-readiness.md").write_text(
            "\n".join(readiness_lines) + "\n", encoding="utf-8"
        )
        review_common = [
            "- mode: PREFREEZE_READINESS", "- verdict: READY_FOR_USER_REVIEW",
            f"- reviewed_readiness_bundle_sha256: {bundle}", "- used_formal_results: NO",
            "- ran_full_real_model: NO", "- signoff: YES",
        ]
        (self.fixture / "model/readiness/implementer-review.md").write_text(
            "# Implementer review\n- role: model_implementer\n- reviewer_id: implementer-fixture\n"
            + "\n".join(review_common) + "\n",
            encoding="utf-8",
        )
        (self.fixture / "model/readiness/verifier-review.md").write_text(
            "# Verifier review\n- role: model_verifier\n- reviewer_id: verifier-fixture\n"
            + "\n".join(review_common) + "\n- g4_status_claimed: NO\n",
            encoding="utf-8",
        )

    def _activate_coordination_registry(self) -> None:
        path = self.fixture / "coordination/thread-registry.csv"
        with path.open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
            fields = list(rows[0])
        for index, row in enumerate(rows):
            contract = self.fixture / row["role_contract_path"]
            row.update(
                task_title=f"fixture-{row['role']}",
                thread_id=f"thread-{index}",
                host_id=f"host-{index}",
                generation="1",
                status="ACTIVE",
                role_contract_sha256=hashlib.sha256(contract.read_bytes()).hexdigest(),
                registered_at="2026-08-28T00:00:00+08:00",
                last_seen_at="2026-08-28T00:00:00+08:00",
            )
        self._write_csv("coordination/thread-registry.csv", fields, rows)

    def _run_verifier(self) -> dict[str, str]:
        script = self.fixture / ".agents/skills/math-modeling-competition/scripts/verify-project.ps1"
        completed = subprocess.run(
            [
                self.powershell, "-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass",
                "-File", str(script), "-ProjectRoot", str(self.fixture), "-Mode", "Snapshot",
                "-SkipSelfTests",
            ],
            cwd=self.fixture,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=90,
            check=False,
        )
        reports = list((self.fixture / "outputs/logs").glob("project-check-*.json"))
        if not reports:
            self.fail(
                f"verifier produced no report (exit={completed.returncode})\n"
                f"stdout:\n{completed.stdout}\nstderr:\n{completed.stderr}"
            )
        report = max(reports, key=lambda path: path.stat().st_mtime_ns)
        payload = json.loads(report.read_text(encoding="utf-8-sig"))
        return {item["name"]: item["status"] for item in payload["checks"]}

    def test_ready_bundle_passes_all_prefreeze_checks(self) -> None:
        checks = self._run_verifier()
        for name in [
            "g2-readiness-files", "g2-readiness-status-and-signoff",
            "g2-independent-prefreeze-reviews", "g2-protected-invariants",
            "g2-a-class-decisions", "g2-tier-budget-and-fallback",
            "g2-readiness-review-hashes",
        ]:
            self.assertEqual(checks[name], "PASS", name)
        self.assertEqual(checks["coordination-files-and-schema"], "PASS")
        self.assertEqual(checks["coordination-path-ownership"], "PASS")
        self.assertEqual(checks["thread-registry-uniqueness"], "WARN")

    def test_duplicate_active_thread_identity_is_rejected(self) -> None:
        self._activate_coordination_registry()
        path = self.fixture / "coordination/thread-registry.csv"
        with path.open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
            fields = list(rows[0])
        rows[1]["thread_id"] = rows[0]["thread_id"]
        self._write_csv("coordination/thread-registry.csv", fields, rows)
        self.assertEqual(self._run_verifier()["thread-registry-uniqueness"], "FAIL")

    def test_stale_hash_is_rejected(self) -> None:
        path = self.fixture / "model/protected-invariants.md"
        path.write_text(path.read_text(encoding="utf-8") + "\nchanged after signoff\n", encoding="utf-8")
        self.assertEqual(self._run_verifier()["g2-readiness-review-hashes"], "FAIL")

    def test_open_a_class_decision_is_rejected(self) -> None:
        path = self.fixture / "model/decision-register.csv"
        with path.open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        rows[0]["resolution_status"] = "OPEN"
        self._write_csv("model/decision-register.csv", list(rows[0]), rows)
        self.assertEqual(self._run_verifier()["g2-a-class-decisions"], "FAIL")

    def test_tier_one_over_forty_percent_is_rejected(self) -> None:
        path = self.fixture / "model/complexity-budget.csv"
        with path.open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        rows[1]["expected_total_minutes"] = "50"
        rows[1]["window_fraction"] = "0.50"
        self._write_csv("model/complexity-budget.csv", list(rows[0]), rows)
        self._refresh_readiness_hashes()
        self.assertEqual(self._run_verifier()["g2-tier-budget-and-fallback"], "FAIL")

    def test_same_reviewer_identity_is_rejected(self) -> None:
        path = self.fixture / "model/readiness/verifier-review.md"
        text = path.read_text(encoding="utf-8").replace("verifier-fixture", "implementer-fixture")
        path.write_text(text, encoding="utf-8")
        self.assertEqual(self._run_verifier()["g2-independent-prefreeze-reviews"], "FAIL")

    def test_asynchronous_freeze_is_rejected(self) -> None:
        (self.fixture / "model/PLAN_STATUS.txt").write_text("FROZEN\n", encoding="utf-8")
        self.assertEqual(self._run_verifier()["plan-status"], "FAIL")


if __name__ == "__main__":
    unittest.main()
