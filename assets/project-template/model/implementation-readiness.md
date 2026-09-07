# G2-B 冻结前联合可实现性审查

- readiness_id：READINESS-v0-R0
- 审查轮次：R0
- 状态：NEEDS_REVISION
- status: NEEDS_REVISION
- 模型方案版本：v0
- 模型方案规范化 SHA-256：待填写
- model_plan_sha256: 待填写
- 预处理契约版本：v0
- 预处理契约规范化 SHA-256：待填写
- preprocessing_plan_sha256: 待填写
- 受保护决策 SHA-256：待填写
- protected_invariants_sha256: 待填写
- 实现默认项 SHA-256：待填写
- implementation_defaults_sha256: 待填写
- 复杂度预算 SHA-256：待填写
- complexity_budget_sha256: 待填写
- readiness 审查包 SHA-256：待填写
- readiness_bundle_sha256: 待填写
- 实施者签收：NO
- implementer_signoff: NO
- 验证者签收：NO
- verifier_signoff: NO
- 实施者 review_id：IMP-READINESS-v0-R0
- 验证者 review_id：VER-READINESS-v0-R0
- 审查日期：待填写

状态只能为 `READY_FOR_USER_REVIEW / NEEDS_REVISION / BLOCKED_BY_DATA_OR_AUTHORITY`。本审查只读题目、数据字典、DRAFT 契约与算法证据；允许在 `tests/contract/` 使用人工或合成小例，但禁止读取正式结果、运行真实模型、生成 `data/processed/` 或论文正式产物。本文件不是 G4 验证报告。

规范化哈希规则：按 UTF-8 读取并移除 BOM，将 CRLF/CR 统一为 LF，移除每行行尾空格，删除多余末尾空行并保证恰好一个末尾 LF，再计算 SHA-256。模型与预处理只哈希各自 `G2-CONTRACT-BEGIN/END` 间的科学契约，避免 G2-C 审批元数据产生自引用。readiness 审查包按固定路径顺序，以 `路径 + NUL + 文件哈希 + LF` 连接后再次计算 SHA-256：`model/model-plan.md`、`data/preprocessing-plan.md`、`model/protected-invariants.md`、`model/implementation-defaults.md`、`model/complexity-budget.csv`。任一契约文件改变都使旧签收失效。规范化规则版本为 `G2-CANONICAL-V1`。

## 实施者检查

| check_id | task_id | 检查对象 | 唯一可执行入口/结论 | 合成小例或静态证据 | 状态 | 阻塞与修订动作 |
|---|---|---|---|---|---|---|
| RI-IMP-TBD | TBD | 字段/变换/划分/目标/约束/指标/产物底表 | 待填写 | 待填写 | NOT_REVIEWED | 待填写 |

实施者必须确认 Tier 0/1 的入口、依赖、求解器、内存和时间预算可获得；bootstrap、模拟、随机重复和图表均有可生成的底表设计；实现只要求数学等价，不要求矩阵坐标、列序或文件字节完全一致。

## 验证者检查

| check_id | task_id | 检查对象 | 可执行的正负/边界/退化/防泄漏检查 | 预注册阈值独立性 | Tier 回退可执行性 | 状态 | 阻塞与修订动作 |
|---|---|---|---|---|---|---|---|
| RI-VER-TBD | TBD | 题目—数据—预处理—模型—指标—声明链 | 待填写 | 待填写 | 待填写 | NOT_REVIEWED | 待填写 |

## 联合结论

- G2-A 意见是否一次合并：NO
- 未决 A 类科学决策：待填写
- 未消除的真实风险：待填写
- 允许提交给用户的白话摘要：待填写
- 下一步：返回 G2-A 修订；只有状态为 `READY_FOR_USER_REVIEW` 且双签收为 YES 才能进入 G2-C。

本文件由 `model_architect` 依据 `model/readiness/implementer-review.md` 和 `model/readiness/verifier-review.md` 合并；它不得代替任一角色签收。两个 review 必须具有不同 reviewer_id、相同审查包哈希，且均声明未使用正式结果。
