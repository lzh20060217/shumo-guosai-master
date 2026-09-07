# 队友、论文手与接手 Agent 交接说明

## 当前阶段

- 当前质量门：G0 前
- 建模方案状态：DRAFT
- 预处理契约状态：DRAFT
- G2-B readiness：NEEDS_REVISION（模板占位，尚未执行）
- 用户批准：NOT_APPROVED
- 最近验证结果：2026-09-06 模板 Snapshot 打包前和解压后结构验证均为 0 个失败；空白字段警告保留，尚无具体赛题结果

## 已完成的模板能力

- 六个专业角色和 G0-G6 质量门已建立。
- G1 具有算法证据需求、定向检索、合法全文下载、教材章节取证、覆盖审计与版本失效回路。
- G2 已拆成 G2-A/G2-B/G2-C，并新增：
  - `model/protected-invariants.md`：A 类受保护科学决策；
  - `model/implementation-defaults.md`：B 类等价实现约定；
  - `model/decision-register.csv`：决策类别、状态、依据、影响与 CR；
  - `model/complexity-budget.csv`：Tier 0/1/2 的入口、资源、效果门与回退；
  - `model/readiness/implementer-review.md` 与 `model/readiness/verifier-review.md`：不同身份的冻结前独立审查；
  - `model/implementation-readiness.md`：架构师合并后的用户审核包；
  - `model/g2-approval.json`：与精确版本和审查包哈希绑定的用户批准记录。
- 实现者具有 `PREFREEZE_READINESS` 与 `G3_EXECUTION` 两种互斥模式；验证者的冻结前审查不得冒充 G4。
- G3/G4/G5 仍要求可复现代码、原始/最终表格、草图/终图、artifact manifest、独立灵敏度与稳健性检验、论断审计和论文大纲。
- G6 仍只能由用户当前明确命令触发。
- 已增加“一个总控任务 + 六个长期角色任务”的多对话控制面：`coordination/thread-registry.csv` 登记角色身份与代次，`dispatch-log.csv`、`dispatches/`、`receipts/` 和 `sync-ledger.csv` 形成派单—回执—接纳链，`path-ownership.csv` 防止跨对话覆盖共享文件。
- 当前只是可复制模板，七个任务均未注册；正式比赛需在同一 saved local project 和共享主目录初始化，客户端无跨任务消息能力时由用户人工转发派单指针。
- 本模板已按用户当前命令以 `math-modeling-template` 标签执行 Snapshot 导出，默认不包含论文和教材全文；这只是模板维护记录，不把任何具体比赛的 G6 改为 PASS。

## 正式比赛中的继续顺序

1. 完成 G0：核验规则，登记题目、任务、数据来源、许可、字段、单位和原始哈希。
2. 完成 G1：先做领域检索；架构师提出候选与算法证据需求；文献角色定向检索并合法下载；架构师确认核心算法证据覆盖。
3. G2-A：架构师写预处理、Tier 0/1/2、验证计划、A/B 决策和复杂度预算，状态保持 DRAFT。
4. G2-B：实施者与验证者分别在 `PREFREEZE_READINESS` 模式审查，只允许纸面和 `tests/contract/` 合成小例，不读取正式结果、不运行完整真实模型。
5. 架构师只合并共同问题；当 readiness 为 `READY_FOR_USER_REVIEW`、两份审查哈希一致且没有未决 A 类决策时，把白话审核包交给用户。
6. G2-C：用户批准精确审查包后，同时把模型与预处理设为 FROZEN；哈希失配必须重新审查，不能沿用旧批准。
7. G3：实施者运行冻结的 Tier 路线。Tier 2 失败或未过预注册门则回退 Tier 1；Tier 1 仍能回答题目时不重开 G2。普通 C 类 bug 直接修复并记入 `reports/bug-fix-log.csv`。
8. G4：由独立验证者复现，并分别完成灵敏度、稳健性、消融、不确定性、泄漏和声明审计。
9. G5：论文手只使用已验证数值和 artifact ID，按大纲取用结果底表、终表、草图、终图和方法证据。
10. 完整论文编译后执行 G5.5：填写 `reports/late-stage-ai-self-check.csv`，处理全部 `ISSUE / NEEDS_CONFIRMATION`，并重新核数、编译和复查。
11. 只有用户明确要求时进入 G6 快照或正式发布。

## 关键文件

- 总状态与指南：`PROJECT_STATUS.md`, `START-HERE.md`, `WORKFLOW-GUIDE.md`
- 任务与数据：`problem/task-requirements.csv`, `data/data-inventory.csv`, `data/raw-hashes.csv`
- G1：`model/algorithm-evidence-request.csv`, `research/search-log.csv`, `research/algorithm-evidence-coverage.csv`
- G2：`data/preprocessing-plan.md`, `model/model-plan.md`, `model/protected-invariants.md`, `model/implementation-defaults.md`, `model/decision-register.csv`, `model/complexity-budget.csv`, `model/implementation-readiness.md`, `model/g2-approval.json`
- G3 结果：`outputs/result-summary.json`, `outputs/artifact-manifest.csv`, `outputs/tables/`, `outputs/figures/`
- G4：`reports/verification-report.md`, `reports/claim-audit.csv`, `reports/bug-fix-log.csv`
- G5：`writing/paper-outline.md`, `writing/claim-evidence-matrix.csv`
- G5.5：`reports/late-stage-ai-self-check.csv`
- 多对话控制：`coordination/README.md`, `coordination/CONTROL-BOARD.md`, `coordination/thread-registry.csv`, `coordination/dispatch-log.csv`, `coordination/sync-ledger.csv`, `coordination/user-authority-log.csv`

## 给接手 Codex 的指令

```text
使用 $math-modeling-competition。读取 HANDOFF.md、PROJECT_STATUS.md、coordination/README.md、coordination/CONTROL-BOARD.md、coordination/thread-registry.csv、competition/、problem/、data/PREPROCESSING_STATUS.txt、model/PLAN_STATUS.txt、model/implementation-readiness.md 和 model/g2-approval.json，判断当前 G0-G6、G2-A/B/C 与活动派单状态后继续。不得把模板升级视为具体模型批准；不得在未获用户批准时冻结；不得把冻结前审查冒充 G4；不得自行打包。
```

## 已知风险

- 当前所有赛题内容、数值结论和正式质量门状态仍为空白；模板验证通过不表示竞赛结果通过。
- readiness 使用精确规范化哈希。审查后修改模型、预处理、受保护决策、默认项或复杂度预算，旧双签与用户批准会失效。
- G5 完成不表示允许打包；只有用户当前消息明确要求时才能执行 G6。
