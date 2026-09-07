# G0–G6 质量门验收契约

状态只允许 `NOT_STARTED / IN_PROGRESS / BLOCKED / PASS`。必需文件存在、内容非占位、引用路径可解析且阻塞项为零，才能记 `PASS`。通过后同步更新 `PROJECT_STATUS.md` 和 `HANDOFF.md`。

采用多对话结构时，每个专业门还必须有匹配当前 ACTIVE role/generation/thread、输入 bundle 哈希和授权范围的 dispatch、receipt 与 `ACCEPTED` sync-ledger 记录；聊天中的“已完成”不能替代。共同状态、任务追踪、G2-C 批准和质量门只由 coordinator 在验收回执后写入。Snapshot 可保留未注册的空白拓扑并警告；正式比赛进入专业派单后以及 Release 时，重复 ACTIVE 角色、陈旧输入、越权路径、未闭环派单或缺少接纳记录均为阻塞。

## 全程任务追踪

`problem/task-requirements.csv` 必须覆盖题目每个子任务、交付物和硬约束。G0 填题意与输入输出，G1 填证据，G2 填模型，G3 填实现，G4 填检验，G5 填论文位置；任一必填映射缺失均阻塞对应门。

## G0 赛制、题目、数据与预处理草案

必需：`competition/competition-profile.md`、题目原文、任务追踪表、`data/data-inventory.csv`、`data/raw-hashes.csv`、`data/preprocessing-plan.md`。

通过条件：当届官方格式、匿名、AI 与提交规则有来源和核验时间；任务和歧义完整；每个数据源含许可、字段、单位、范围、缺失/重复/异常和哈希；无官方数据时明确登记；预处理草案覆盖字段映射、规则顺序、划分和防泄漏。

阻塞：规则来自往届或非官方且未标风险；任务/文件漏登；关键单位或时间语义不明；`data/raw/` 被修改；存在影响建模方向的未决歧义。

## G1 文献与证据

必需：`research/evidence-matrix.csv`、`research/literature-review.md`、`research/citation-brief.md`、`model/algorithm-evidence-request.csv`、`research/algorithm-evidence-coverage.csv`、`research/search-log.csv`。

通过条件：检索日期、来源、双语检索式和筛选标准可复核；元数据及 DOI/稳定链接已核验；覆盖机制、基线、候选、预处理、指标、检验和局限；区分事实、综合与迁移；冲突、访问限制和证据缺口显式记录。建模 Agent 已为基线、候选和非平凡组件提出中性、带版本的算法证据需求；文献 Agent 已分别检索支持、比较、局限和失败证据并记录负向结果；候选至少有一个原始/权威理论来源和一个独立应用、比较或局限来源。最终核心组件应覆盖 `FOUNDATIONAL`、`TASK_APPLICATION`、`COMPARATIVE_OR_LIMITATION`，并检查 `TEXTBOOK_OR_MONOGRAPH`；若无可用教材/专著章节须记录原因。至少两份关键来源可读全文，且不少于三个独立来源组。下载全文只有在 PDF、日志、索引、知识卡和覆盖表相互一致后才算完成。

阻塞：核心方法只靠未核验来源、摘要或通用方法族材料；不能支持基线和至少一个候选比较；关键任务既无证据又无缺口说明；只有成功案例而未检索比较或失败条件；教材已投放但无授权/章节/页码记录；算法版本、请求版本和计划版本不一致；证据为 `STALE / GAP / BLOCKED / PARTIAL / CONFLICTED / UNSUPPORTED`。G2 引入新算法或重要变体时，G1 返回 `IN_PROGRESS`，完成新一轮定向检索后才能再次 `PASS`。

## G2 预处理与模型冻结

G2 包含三个顺序子门：G2-A 方案设计、G2-B 冻结前联合可实现性审查、G2-C 用户审批与同步冻结。

必需：完整的 `data/preprocessing-plan.md`、`model/model-plan.md`、`model/protected-invariants.md`、`model/implementation-defaults.md`、`model/decision-register.csv`、`model/complexity-budget.csv`、`model/implementation-readiness.md`、`model/change-request.md`、当前版本算法请求与证据覆盖，且最终 `data/PREPROCESSING_STATUS.txt` 与 `model/PLAN_STATUS.txt` 均为 `FROZEN`。

G2-A 通过条件：数据契约精确到输入哈希、字段单位、规则顺序、阈值、拟合范围、划分、种子、防泄漏和输出模式；逐任务定义变量、方程、目标、约束、算法、初始化、停止条件、复杂度和输出；每题有同一外层划分、评价单位和主要指标下的 Tier 0 与 Tier 1，Tier 2 若存在则具有相对 Tier 1 的预注册增益/区间/稳定性/校准/成本门和直接回退路线；基线、候选和关键辅助算法具有稳定 ID、当前证据、假设映射和迁移限制；计算预算含入口、单次与总拟合次数、bootstrap/模拟、时间/内存/磁盘、最坏耗时和超预算动作。Tier 1 默认不超过可用窗口 40%，Tier 2 运行前预留至少 30% 交付安全余量。

G2-B 通过条件：`model_implementer` 和 `model_verifier` 只基于纸面与 `tests/contract/` 合成小例完成一次联合审查；未读取正式结果、未运行真实模型、未生成 processed 或正式 artifact；实施者确认接口、依赖、预算和底表设计唯一可执行，验证者确认链条、正负/边界/退化/防泄漏测试、阈值独立性和 Tier 回退可执行。`model/implementation-readiness.md` 状态为 `READY_FOR_USER_REVIEW`、双方签收为 YES、审查轮次唯一，记录的模型/预处理/受保护决策/实现默认项/预算规范化 SHA-256 与当前文件一致。G2-A 修订后必须重新计算哈希和双签收；算法变化还须重开定向 G1。

G2-C 通过条件：A 类受保护科学决策完整，`decision-register.csv` 不存在 `PROPOSED / UNRESOLVED / BLOCKED` 的 A 类项；B 类等价实现约定已经冻结前登记；用户只收到最终正文、白话变更摘要、A 类决策、Tier/效果门、联合 readiness 和真实风险，并批准当前精确审查包；模型与预处理同步冻结。

阻塞：任务未映射；缺 Tier 0/1、量纲、复杂度、入口、预算、阈值、底表或回退路线；readiness 非 `READY_FOR_USER_REVIEW`、缺任一签收或哈希过期；存在未决 A 类；最终算法理论/版本证据不足；团队新组合被错误写成文献已整体证明；用户审批前已经运行真实模型或借结果选择阈值；模型与预处理没有同步冻结。

## G3 实现、运行与产物登记

必需：`src/`、`experiments/`、`tests/`、`data/processed/`、日志、`outputs/result-summary.json`、`outputs/artifact-manifest.csv`。

通过条件：实现忠实于冻结契约与 G2-B 签收版本；先完成 Tier 0/1，Tier 2 仅在预算与效果门允许时运行；同折候选结果包括失败/无增益结果均保留；种子、环境、命令、参数、输入哈希、时间和输出可追溯；正式结果由脚本重建；每个正式数值/表/图均有 artifact_id、生成器、源数据、运行 ID、单位、图注、论文位置和验证状态。B 类约定写入实现默认项，C 类缺陷写入 bug/fix 日志。

阻塞：原始数据改变；实现偏离冻结方案；无范围地重新审计整个 G2；为挽救 Tier 2 改测试集、指标或受保护语义；任务无入口或结果；结果靠不可追溯的手工修改；只存在于 Notebook。Tier 2 同因两次识别/收敛/预算失败必须退 Tier 1；Tier 1 失败时继续检查冻结的 Tier 0，只有所有冻结 Tier 均不能完整回答题目时才重开 G2。

## G4 独立复现与挑战检验

必需：`reports/verification-report.md`、`reports/claim-audit.csv`、独立代码/证据、回填验证状态的 artifact manifest。

通过条件：验证者从文档命令独立复现；检查题目—方案—数据—代码—结果一致性；所有预注册且适用的基线、灵敏度、稳健性、消融、随机重复、不确定性、边界和复杂度检查均有阈值、实际结果和证据；正式图表可重建；声明措辞与证据相符。

阻塞：关键项 `FAIL` 或 `NOT_TESTED`；`CONDITIONAL` 无论文限制；关键产物仍 `PENDING`；验证者只复述实现者结论；事后修改阈值。

## G5 论文提纲与写作交接

必需：`writing/paper-outline.md`、`writing/claim-evidence-matrix.csv`、完整 artifact manifest、更新后的 `HANDOFF.md`。

通过条件：每个任务映射到论文节、公式、表或图；摘要明确逐任务方法、主要定量结果、检验和克制结论；正文覆盖数据处理、基线、最终模型、结果、灵敏度、稳健性、消融、局限；每个拟写结论映射到文献、已验证 artifact_id 和检验；写作顺序、格式预算、复现命令、风险和禁止夸大表述齐全。

阻塞：任务无论文落点；关键结论无来源或验证产物；引用 `PENDING / FAIL / NOT_TESTED`；路径、单位或版本不一致。G5 不授权打包。

## G5.5 晚期 AI 辅助自查（G5 子检查）

必需：完整编译的 Word/PDF、当届官方规则、`ai_usage_log.md`、AI 使用声明、artifact manifest、验证报告和 `reports/late-stage-ai-self-check.csv`。

通过条件：可见的 5 个维度、20 个 `item_id` 均完成；AI 声明与实际日志/产物一致；数据、引用、图表数值、逻辑因果、题意闭环、模型适配、参数依据和全文呼应均有定位证据；不存在 `NOT_REVIEWED / ISSUE / NEEDS_CONFIRMATION`；`NOT_APPLICABLE` 有理由。

阻塞：把第三方自查表冒充官方规则；用文风检测器分数证明 AI 作者身份或违规；虚构图片缺失的第六维度；为通过检查隐瞒 AI 使用、改动真实数据或伪造检验。G5.5 不替代 G4，也不授权打包。

## G6 用户命令触发的手动打包

只在用户当前消息明确要求打包、快照或发布时运行。默认 Snapshot；只有明确“正式/严格发布”才用 Release。

Release 要求 G0–G5 全部 `PASS`、方案 `FROZEN`、证据和结果非空、关键检验无 `FAIL/NOT_TESTED`、论文关键产物已验证；校验 ZIP、manifest、SHA-256 和解压后验证；排除秘密、缓存、环境、Git、旧 releases 和默认不授权的论文/教材全文。
