---
name: math-modeling-competition
description: Run a gated mathematical-modeling competition workflow covering contest rules, problem and data decomposition, literature evidence, preprocessing and model approval, reproducible implementation, independent sensitivity and robustness validation, paper-outline handoff, and user-commanded packaging. Do not silently change a frozen plan or package without an explicit command.
---

# Mathematical Modeling Competition

Coordinate a reproducible competition project through one coordinator task, six persistent role tasks, and explicit quality gates. Persist every important conclusion in project files so any task can continue without another task's transcript.

## Start Every Run

1. Read `AGENTS.md`, `PROJECT_STATUS.md`, `HANDOFF.md`, `coordination/CONTROL-BOARD.md`, `coordination/thread-registry.csv`, `problem/`, and `model/PLAN_STATUS.txt`.
2. Identify the current gate and the exact user request.
3. Preserve `data/raw/` and all unrelated user changes.
4. Read only the reference needed for the current gate:
   - Literature or local learning resources: `references/literature-library.md`
   - Gate acceptance criteria: `references/workflow-gates-v2.md`
   - Model and code validation: `references/verification-standard-v2.md`
   - Packaging or teammate continuation: `references/handoff-contract-v2.md`
   - Choosing a modeling family: `references/method-selection-map.md`
   - Persistent role tasks and cross-chat routing: `references/thread-coordination-v1.md`
   - Late-stage AI-assisted audit: the parent `shumo-guosai-master/references/late-stage-ai-self-check.md` when available, plus `reports/late-stage-ai-self-check.csv`

## Route Work to Persistent Role Tasks

Use `coordination/README.md` as the normative cross-task protocol and `.codex/agents/` as the six role contracts.

1. In a formal competition project, maintain exactly one active coordinator task and one active task for each role: `literature_researcher`, `model_architect`, `model_implementer`, `model_verifier`, `paper_outline_writer`, and `release_packager`.
2. Run all seven tasks in the same saved local project and shared primary directory. Do not use separate worktrees for this live shared-file protocol.
3. Create or replace role tasks only after an explicit user request to initialize or repair the role-task topology. Record task/thread identifiers and generations in `coordination/thread-registry.csv`.
4. Before sending a cross-task message, write a versioned dispatch under `coordination/dispatches/` and a matching row in `coordination/dispatch-log.csv`. The message only tells the role task which dispatch to read.
5. A role task must reject a dispatch when role, generation, thread identifier, mode, input hash, dependency, or allowed write scope does not match. Each role has at most one active dispatch.
6. A role task writes its owned artifacts and an immutable receipt under `coordination/receipts/`. The coordinator validates the receipt and actual files before updating shared status.
7. Treat chats as separate transcripts. Never rely on a role task having seen the coordinator transcript or another role's messages; use project files and hashes as the shared source of truth.

Use `literature_researcher` for search and evidence; `model_architect` for algorithm requests and G2 design; `model_implementer` for the two explicit readiness/execution modes; `model_verifier` for the two separate challenge/verification modes; `paper_outline_writer` for G5; and `release_packager` only after an explicit current user packaging command.

The coordinator must reconcile receipts, resolve contradictions, enforce write ownership and gates, and report uncertainty. It must not perform a professional role's formal signoff, modify another role's evidence to make it pass, or delegate the user approval decision.

## G0: Parse the Problem and Inventory Data

1. Preserve the original statement in `problem/`.
2. Restate each subproblem, required deliverable, hard constraint, evaluation target, and ambiguity.
3. Inventory every data file, field, unit, time range, missingness pattern, and provenance.
4. Write assumptions that are already forced by the statement separately from assumptions proposed by the team.
5. Update `PROJECT_STATUS.md`, `HANDOFF.md`, and `coordination/CONTROL-BOARD.md` with G0 evidence and unresolved questions. Only the coordinator performs this shared-state merge.

Do not choose a sophisticated model before completing this inventory.

## G1: Build Literature Evidence

1. Have `literature_researcher` generate Chinese and English queries from the problem, variables, mechanisms, and likely method families.
2. Search current external sources and the curated local library. Do not rely on model memory for citations.
3. Verify title, authors, year, venue, and DOI or stable URL before treating a source as confirmed.
4. Populate `research/evidence-matrix.csv` and `research/literature-review.md`.
5. Separate source facts, researcher synthesis, and transfer judgment.
6. Mark inaccessible, secondary-only, contradictory, or weak sources explicitly.
7. Require enough diversity to compare at least a baseline and plausible alternative approaches.
8. Before treating G1 as complete, have `model_architect` generate `model/algorithm-evidence-request.csv` for every baseline, candidate and nontrivial component without naming a preferred winner.
9. Return the requests to `literature_researcher` for neutral, support, comparison and limitation searches. Record queries in `research/search-log.csv` and coverage in `research/algorithm-evidence-coverage.csv`.
10. Repeat the request-search-review loop whenever a new algorithm, variant or hybrid component appears. Evidence tied to an older plan version is `STALE` and cannot support freezing.

Use Luna for high-volume retrieval, extraction, classification, and structured summaries. Route cross-paper synthesis, conflicting evidence, and final model choice to Sol through `model_architect`.

## G2: Design and Freeze the Model

1. Enter formal G2 only after every selected algorithm component has current, cross-referenced evidence coverage.
2. G2-A: have `model_architect` define preprocessing, variables, equations, algorithms, Tier 0/1/2, effect gates, protected A decisions, equivalent B defaults, budgets, preregistered checks, artifact plans and frozen fallback routes. Keep all plans `DRAFT`.
3. G2-B: call `model_implementer` in `PREFREEZE_READINESS` and `model_verifier` in their prefreeze mode. They write separate `model/readiness/implementer-review.md` and `model/readiness/verifier-review.md` records and may run only synthetic contract examples under their own `tests/contract/` subfolders; they must not read formal results, run full real-data models, create processed data or write paper artifacts.
4. Have `model_architect` merge the two immutable reviews once in `model/implementation-readiness.md` without impersonating either signoff. If G2-A changes, repeat the joint canonical-hash/signoff check; if an algorithm changes, reopen targeted G1.
5. G2-C: present only the exact final model/preprocessing, plain-language change summary, protected A decisions, Tier/effect gates, readiness conclusion and unresolved real risks to the user.
6. Change both status files to `FROZEN` only after readiness is `READY_FOR_USER_REVIEW`, both reviewers signed the exact canonical hashes, no A decision is unresolved, and the user clearly approves that version.

Do not freeze when a final component lacks foundational theory, a relevant textbook/monograph check, a comparable application, or limitation/comparison evidence; when all theory detail is abstract-only; when assumptions are not mapped to current data; or when request and plan versions differ.

After freezing, require `model/change-request.md` and renewed approval for any mathematical-model change. Refactoring that preserves the model does not require a plan change.

Classify changes before opening a request. Class A changes the scientific answer and requires user approval; class B fixes an equivalent reproducibility convention before freeze; class C is an ordinary code defect. After G2-B, G3 may not reopen a broad ambiguity audit. Use frozen Tier fallbacks first; reopen G2 only when Tier 1 cannot answer the task.

## G3: Implement and Run

1. Confirm the plan is `FROZEN`.
2. Have `model_implementer` implement the baseline first and the final model second.
3. Keep exploration separate from production entry points.
4. Fix random seeds and record dependency versions, parameters, commands, runtime, metrics, and output paths.
5. Store code in `src/`, experiment entry points in `experiments/`, tests in `tests/`, and generated evidence under `outputs/`.
6. The implementer writes a dispatch receipt after material results; the coordinator verifies it and updates `PROJECT_STATUS.md`, `HANDOFF.md`, and the control board.

If implementation reveals a modeling flaw, stop that path and submit a change request. Do not silently reinterpret the frozen plan.

## G4: Verify Independently

1. Have `model_verifier` reproduce the reported results from documented commands.
2. Check mathematical-plan fidelity before checking performance.
3. Apply the relevant checks in `references/verification-standard-v2.md`.
4. Record every check in `reports/verification-report.md` as `PASS`, `CONDITIONAL`, `FAIL`, or `NOT_TESTED` with evidence.
5. Send failures back to the implementer as minimal reproductions; rerun affected checks after fixes.

Do not call the project verified when critical checks are missing or when the verifier only inspected the implementer's summary.

## Removed Legacy Gate

The former G5 packaging flow has been removed. Use only normative G6 below; G5 is exclusively the paper-outline and writer-handoff gate.

## Workflow Version 2 (Normative)

The G0–G6 contract below supersedes any shorter gate description above. Status values are `NOT_STARTED / IN_PROGRESS / BLOCKED / PASS`; file existence alone never earns `PASS`.

### G0: Contest Rules, Problem and Data

1. Fill `competition/competition-profile.md` from the current official rules, including format, anonymity, AI-use and submission constraints.
2. Split every subproblem, deliverable, hard constraint, metric and ambiguity into `problem/task-requirements.csv`.
3. Inventory raw and external data in `data/data-inventory.csv`; record byte hashes in `data/raw-hashes.csv`.
4. Draft field mapping, units, rule order, missing/outlier/duplicate handling, time/space alignment, split strategy and leakage risks in `data/preprocessing-plan.md`.
5. If no official data exists, write `NO_OFFICIAL_DATA` and the acquisition plan instead of leaving files blank.

### G1: Literature Evidence

1. Search current primary or authoritative sources and the curated local library with Chinese and English queries.
2. Verify title, authors, year, venue and DOI/stable URL; do not cite model memory.
3. Download a full-text PDF only when it is needed, available through an open or team-authorized HTTPS direct link, and its access basis can be recorded. Use `scripts/download-paper.ps1`; never bypass access controls or paywalls.
4. After a successful download, verify PDF signature and SHA-256, update `research/library/library-index.csv`, and retain `research/library/download-log.csv`. For unavailable full text, keep a verified link and mark the access limitation.
5. Populate `research/evidence-matrix.csv`, `research/literature-review.md` and `research/citation-brief.md`.
6. Cover mechanisms, baseline, candidates, preprocessing, metrics, validation methods and limitations.
7. Separate source facts, synthesis and transfer judgment; mark inaccessible, secondary-only, weak and contradictory evidence.
8. Run the algorithm evidence loop before G1 can pass:
   - `model_architect` writes neutral, versioned component requests to `model/algorithm-evidence-request.csv`.
   - `literature_researcher` searches foundational, textbook/monograph, task-application and comparison/limitation evidence, records every query in `research/search-log.csv`, and writes coverage to `research/algorithm-evidence-coverage.csv`.
   - Downloaded evidence counts only after PDF, log, library index, knowledge card and coverage records agree.
   - A new or materially changed algorithm reopens targeted G1 and makes the old request `STALE`.
   - Tier labels do not waive evidence: every `selection_eligible=YES` component that may become a formal deliverable must be currently covered.

### G2: Freeze Preprocessing and Model

1. G2-A completes task coverage, preprocessing, equations, stable algorithm IDs, preregistered validation and artifacts.
2. Give every task Tier 0 and Tier 1; Tier 2 is optional and must have a preregistered incremental effect/stability/calibration/cost gate plus a direct Tier 1 fallback. All tiers use the same outer split, evaluation unit and primary metric.
3. Complete `model/protected-invariants.md`, `model/implementation-defaults.md`, `model/decision-register.csv` and `model/complexity-budget.csv`. Record fit counts, compute/memory/disk budgets, the 40% Tier 1 window, the 30% delivery reserve and over-budget actions.
4. Preregister every applicable baseline, sensitivity, robustness, ablation/alternative, reproducibility and complexity check with range, repeats, threshold, evidence path and failure action.
5. G2-B requires one joint prefreeze review. The implementer confirms executable interfaces and resources; the verifier confirms testability, threshold independence, leakage defenses and fallback executability. Only synthetic contract examples are allowed.
6. `model/implementation-readiness.md` must be `READY_FOR_USER_REVIEW`, both signoffs must be YES, and its canonical hashes must match the current plan, preprocessing, invariants, defaults and budget. No unresolved A decision may remain.
7. Keep both status files `DRAFT` until G2-C user approval of the exact review bundle. Template-upgrade approval is not model approval; approved versions freeze together.
8. Block freezing for algorithm evidence gaps, absent Tier 0/1, incomplete entries/budgets/failure actions, stale readiness hashes, unresolved A decisions, or unreadable theoretical assumptions.

Semantic preprocessing or mathematical changes after freeze require `model/change-request.md` and renewed approval.

After freeze, try the declared Tier fallback before reopening G2. Two same-cause Tier 2 identification/convergence/budget failures force Tier 1. B conventions and C defects do not trigger a model CR; a CR is allowed only for a concrete non-equivalent A ambiguity that cannot be solved by the frozen fallback, and same-gate A items are merged once.

### G3: Implement, Run and Register Results

1. Confirm both status files are `FROZEN` and verify raw hashes before processing.
2. Implement baseline first and final model second; write transformed data only to `data/processed/`.
3. Fix seeds and record dependencies, parameters, commands, runtime, input hashes and output paths.
4. Run all preregistered experiments, including negative or inconclusive runs.
5. Maintain `outputs/result-summary.json` and one row per formal number, table or figure in `outputs/artifact-manifest.csv`.
6. Separate draft/final figures and make captions state task, variables, units, sample/time range and takeaway.

### G4: Independent Verification

1. `model_verifier` reproduces results from documented commands, not the implementer's narrative.
2. Check problem → plan → preprocessing → code → result fidelity before performance.
3. Execute all preregistered and applicable checks in `references/verification-standard-v2.md`.
4. Record `PASS / CONDITIONAL / FAIL / NOT_TESTED / NOT_APPLICABLE`, command, input, threshold, actual result, evidence path and action.
5. Write `reports/verification-report.md`, `reports/claim-audit.csv` and evidence under `outputs/verification/`.
6. Critical `FAIL` or `NOT_TESTED` blocks G4. `CONDITIONAL` must constrain the paper claim.

### G5: Paper Outline and Writer Handoff

1. `paper_outline_writer` reads the verified problem, plan, evidence, result manifest and verification files.
2. Produce `writing/paper-outline.md` covering abstract, restatement, assumptions, symbols, preprocessing, baseline, each task's method/algorithm/results, sensitivity, robustness, ablation, limitations and conclusion.
3. Map every claim to literature and verified artifact IDs in `writing/claim-evidence-matrix.csv`.
4. Give the writer exact artifact paths, caption points, units, interpretation boundaries and prohibited overclaims.
5. Update `HANDOFF.md` with writing order, format budget, blockers, reproduction commands and risks.

G5 never authorizes packaging.

### G5.5: Late-Stage AI-Assisted Audit (G5 Subcheck)

After the complete Word/PDF has been compiled and before G6, fill all 20 rows in `reports/late-stage-ai-self-check.csv`. Check AI-use disclosure against logs and artifacts; verify data, citations, figures, numerical claims and causal language; recheck task closure, model/solver fit, parameter evidence, abstract and whole-paper consistency. Resolve `ISSUE` and `NEEDS_CONFIRMATION`, and do not leave `NOT_REVIEWED` in a Release.

This subcheck is an evidence-based adaptation of a third-party checklist, not an official judging rubric and not a reliable AI-authorship detector. Current official rules override it. The source images exposed only five dimensions and 20 items despite claiming six dimensions and 26 items; do not invent the missing items. G5.5 does not replace G4 verification or genuine human review.

### G6: Package Only on Command

Only after an explicit current user command: update status/handoff, use `Snapshot` by default or `Release` only for an explicitly strict/final request, run the package script with a label, and return ZIP, manifest, SHA-256, verification log and warnings. Add `-IncludeLibrary` only after explicit redistribution confirmation. Never schedule packaging.

## Completion Standard

Finish a requested stage only when required files exist, are non-placeholder, referenced paths resolve, claims are supported, commands and results are recorded, the relevant dispatch has a valid receipt, and blockers are zero. `PROJECT_STATUS.md`, `HANDOFF.md`, and `coordination/CONTROL-BOARD.md` must agree. A teammate or replacement role task must be able to reproduce the work from project files without access to the original chats.
