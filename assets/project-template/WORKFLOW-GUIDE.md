# 正式数学建模比赛使用指南

## 一、赛前准备

1. 为每次比赛复制一份完整模板，从副本根目录打开 Codex。
2. 在同一 saved local project 和共享主目录建立一个总控长期任务与六个专业长期任务；不要为这些任务使用隔离 worktree。
3. 提前确认 Python/求解器环境，但不要把虚拟环境或资料库全文放入最终交接包。
4. 指定一名建模手负责 G2 批准、一名论文手负责 G5 使用；实现者不能兼任最终验证者。
5. 由总控按 `coordination/README.md` 维护线程注册、派单、回执和独占写入范围。专业任务不直接更新总状态。

### 多对话拓扑

固定置顶七个任务：`00-总控 / 10-文献 / 20-建模 / 30-实现 / 40-验证 / 50-论文提纲 / 60-发布`。每个专业角色在一个比赛项目中只有一个活动任务，并在整个比赛中反复续聊。六个 `.codex/agents/*.toml` 是角色职责合同；总控任务依据 `AGENTS.md` 和协调协议工作。

各任务共享项目文件，但聊天记录互不自动共享。因此总控每次先创建 dispatch 文件，再向专业任务发送短消息；专业任务写完 receipt 后，总控才合并 `PROJECT_STATUS.md`、`HANDOFF.md` 和任务追踪表。当前客户端若不能跨任务发消息，由用户人工转发只含 dispatch_id 与路径的短消息；不得跳过派单文件或伪造送达。需要并行时，只并行只读工作或不同且路径不重叠的 `exclusive_scope_id` 写入。

## 二、正式比赛流程

| 门 | 负责人 | 你要给的材料/决定 | 必看产物 | 何时允许前进 |
|---|---|---|---|---|
| G0 赛制题目数据 | 总控 Agent | 当届规则、题目、官方数据 | `competition/competition-profile.md`, `problem/task-requirements.csv`, `data/data-inventory.csv` | 每个任务和数据文件均登记，歧义已处置 |
| G1 文献与算法证据 | literature_researcher + model_architect | 研究边界；必要时确认教材访问权限 | `model/algorithm-evidence-request.csv`, `research/algorithm-evidence-coverage.csv`, `research/search-log.csv` | 基线和候选已比较，最终组件理论/教材/应用/局限覆盖完整且版本一致 |
| G2-A 方案设计 | model_architect | 计算资源与比赛剩余时间 | 模型/预处理、A/B 决策、Tier 与预算 | 每题有 Tier 0/1，Tier 2 有效果门和回退，状态仍 DRAFT |
| G2-B 冻结前联合审查 | model_implementer + model_verifier | 无；不得提供或使用正式结果 | `model/implementation-readiness.md`, `tests/contract/` | 双签收、规范化哈希匹配、状态为 `READY_FOR_USER_REVIEW` |
| G2-C 审批冻结 | coordinator + 建模手 | 只批准 A 类科学决策和精确审查包 | 最终正文、A 类决策、Tier/效果门、readiness、真实风险 | 无未决 A 类，模型和预处理由总控同步 `FROZEN` |
| G3 实现结果 | model_implementer | 计算资源与运行期限 | `outputs/result-summary.json`, `outputs/artifact-manifest.csv`, tables/figures | 基线和最终模型可复现，全部论文产物已登记 |
| G4 独立检验 | model_verifier | 无；保持独立性 | `reports/verification-report.md`, `reports/claim-audit.csv` | 关键项无 `FAIL/NOT_TESTED`，图表已重建 |
| G5 论文交接 | paper_outline_writer | 论文格式和篇幅预算 | `writing/paper-outline.md`, `writing/claim-evidence-matrix.csv` | 每道题和每个拟写结论都有论文落点与证据 |
| G5.5 晚期 AI 辅助自查 | coordinator + 人工复核 | 完整论文和当届官方规则 | `reports/late-stage-ai-self-check.csv` | 20项均完成，问题整改并复查；不把第三方表当官方规则 |
| G6 打包 | release_packager | 当前消息明确下令 | ZIP、manifest、SHA-256、检查日志 | 只在明确要求时执行；正式发布还需 G0–G5 全 PASS |

## 三、总控任务中的派单指令

下面指令都发送给 `00-总控`，不是直接发到新建的临时 Agent。总控负责写 `coordination/dispatches/`、登记 `dispatch-log.csv`、向已注册的长期任务发送消息、等待回执并核验结果。

### 初始化七个长期任务

```text
初始化本项目的长期多对话拓扑。当前任务登记为 coordinator；在同一 saved local project 和共享主目录创建并置顶六个专业任务，使用 coordination/role-thread-prompts.md 的标题和启动提示，回填 thread-registry.csv。不得使用 worktree，不开始 G0，不打包。
```

### 开赛与 G0

```text
使用 $math-modeling-competition。读取当届规则、题目和 data/raw/，由总控完成 G0：逐项建立任务追踪表、数据清单、原始哈希和预处理草案。先报告歧义和阻塞，不要选最终模型；完成后同步 CONTROL-BOARD。
```

### G1

```text
为长期 literature_researcher 建立 G1_EVIDENCE dispatch；回执完成后，为长期 model_architect 建立 G1_ALGORITHM_REQUEST dispatch，只提出带 candidate_id/component_id 的基线和候选，不选最终模型。再把算法需求作为新 dispatch 发回长期文献任务，检索并合法下载原始理论、教材/专著章节、相近应用、比较与局限证据。最后为建模任务建立 G1_REVIEW dispatch。新算法或重要变体必须新建一轮 dispatch，旧证据标 STALE，不能直接进入 G2。
```

### G2-A 方案设计

```text
确认 G1 算法覆盖完成，为长期 model_architect 建立 G2_A_DESIGN dispatch：为每题建立同划分、同评价单位、同主要指标的 Tier 0/1 和可选 Tier 2，写出 Tier 2 相对 Tier 1 的增益、区间、稳定性、校准、成本门及回退路线；完成模型、预处理、A 类 protected invariants、B 类 implementation defaults、decision register、复杂度预算和预注册检验。全部保持 DRAFT，不要请求冻结。
```

### G2-B 联合可实现性审查

两个 Agent 分别写自己的 review，可以独立执行；共同 readiness 只由 model_architect 在两份 review 返回后合并：

```text
为长期 model_implementer 建立 PREFREEZE_READINESS dispatch，只读 G2-A 草案，用 tests/contract/implementer/ 合成小例检查字段、变换、划分、目标、约束、指标、依赖、预算和底表入口；禁止读取正式结果、运行真实模型或生成正式产物，只写自己的 review 和 receipt。
```

```text
为长期 model_verifier 建立独立的 PREFREEZE_READINESS dispatch，挑战题目—数据—预处理—模型—指标—声明链、正负/边界/退化/防泄漏测试、阈值独立性和 Tier 回退；禁止读取正式结果或写 G4 报告，只写自己的 review 和 receipt。
```

两份回执完成后，再为长期 model_architect 建立 `G2_B_MERGE` dispatch。建模任务校验 reviewer_id、审查包哈希和正式结果禁用声明后合并 readiness；总控核验。任一 verdict 为 `NEEDS_REVISION` 时一次合并两方意见并修订；任何文件变化都要重新计算哈希并重新双签收。若算法变化，先重开定向 G1。

### G2-C 用户审批

确认 readiness 为 `READY_FOR_USER_REVIEW`、双签收为 YES、哈希匹配、A 类无未决项后再发送：

```text
我批准 readiness_id 与 G2-C 审批包 SHA-256 对应的当前精确版本，包括列出的 A 类受保护科学决策、Tier 选择/降级规则和主要指标阈值；同步冻结 model 与 preprocessing，进入 G3。B 类等价约定和 C 类修复按登记规则处理。
```

### G3 与 G4

```text
为长期 model_implementer 建立 G3_EXECUTION dispatch，严格按冻结契约先运行 Tier 0/1，再按预算和预注册效果门决定 Tier 2；保存成功、失败和无增益结果，以及逐样本/逐场景底表、汇总表、草图、终稿图和完整 artifact manifest。禁止重新全面审计 G2。
```

```text
在 G3 回执和产物经总控核验后，为长期 model_verifier 建立 G4_VERIFICATION dispatch，独立复现并逐任务检验，完成方案忠实度、数据哈希、基线、灵敏度、稳健性、消融、随机重复、复杂度、图表重建和声明审计。不要替实现者修结果。
```

### G5

```text
为长期 paper_outline_writer 建立 G5_OUTLINE dispatch，只依据已验证结果生成论文写作大纲：告诉论文手摘要怎么写、每道题用了什么方法、关键结果和 artifact_id、应放哪些图表、检验结论、局限及不可夸大的表述。

### G5.5

完整 Word/PDF 编译后、G6 前，根据当届官方规则和 `reports/late-stage-ai-self-check.csv` 完成 20 项补充检查。核查 AI 声明与日志、数据与引用真实性、图表数值、逻辑因果、题意闭环、模型与求解适配、参数依据、摘要和全文呼应。第三方图片仅提供检查灵感，不能证明 AI 作者身份或替代官方规则。发现 `ISSUE` 或 `NEEDS_CONFIRMATION` 时先整改、复算或确认，再重新编译和复查。
```

## 四、论文手如何取材料

1. 从 `writing/paper-outline.md` 得到摘要与逐章写法。
2. 在 `writing/claim-evidence-matrix.csv` 找到每句话的 evidence_id、artifact_id 和 verification_id。
3. 在 `outputs/artifact-manifest.csv` 找实际路径、单位、图注、脚本与验证状态。
4. 原始结果底表在 `outputs/tables/raw/`，论文汇总表在 `outputs/tables/final/`；草图和终稿图分开放置。
5. 公式看冻结方案，数据清洗看预处理契约，可靠性措辞看验证报告和声明审计。
6. 只使用 `VERIFIED` 产物；`CONDITIONAL` 必须保留限制，`PENDING/FAIL/NOT_TESTED` 不得写成已成立。

## 五、你如何快速看进度

- 先看 `PROJECT_STATUS.md` 的 G0–G6 表。
- 再看 `coordination/CONTROL-BOARD.md`、线程注册和 dispatch log，确认没有失联角色、重复 ACTIVE 角色或写入范围冲突。
- 再看 `HANDOFF.md` 的当前阻塞和下一步。
- 随机抽查一个 task_id，确认它能串到模型小节、实现路径、verification_id 和论文小节。
- 随机抽查一个最终算法 component_id，确认它能串到 request_id、检索日志、理论/教材/应用/局限证据、知识卡和当前 plan_version。
- 抽查一个 task_id，确认存在 Tier 0/1、预算入口、同折效果门、回退动作和 readiness 双签收。
- 比较 readiness 审查包 SHA-256 与当前模型、预处理、受保护决策、实现默认项和预算，任何不一致都不得冻结。
- 随机抽查一个摘要数字，确认它能串到 artifact_id、原始结果底表、生成脚本和验证证据。
- 运行 Snapshot 检查；允许 WARN，但任何 FAIL 表示模板完整性或工程结构损坏。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".agents\skills\math-modeling-competition\scripts\verify-project.ps1" -ProjectRoot "." -Mode Snapshot
```

正式提交前运行 Release 检查。它应在 G0–G5 未完成时失败，这是保护机制。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".agents\skills\math-modeling-competition\scripts\verify-project.ps1" -ProjectRoot "." -Mode Release
```

## 六、时间紧时的原则

可以缩小检索数量、Tier 2 候选和实验网格，但不能跳过任务追踪、Tier 0/1、核心算法理论证据、数据哈希、G2-B readiness、用户冻结批准、独立验证和声明—证据映射。Tier 1 默认不超过可用计算窗口 40%，至少预留 30% 给 G4、制图、论文和故障修复；进入安全窗口后不得新增模型家族。
