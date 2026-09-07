# 建模与检验冻结方案

- 版本：v0
- 状态：DRAFT
- 对应预处理契约版本：v0
- 建模手批准：否
- 批准时间与原话：无
- 版本哈希或变更摘要：初始占位模板
- G2 子门：G2-A DRAFT
- readiness_id：尚未生成
- G2-C 审批包 SHA-256：尚未生成

<!-- G2-CONTRACT-BEGIN -->

## 1. 逐任务覆盖

| task_id | 题目要求 | 输入 data_id | 输出 | 硬约束 | 评价指标 | 模型小节 | 检验 ID |
|---|---|---|---|---|---|---|---|
| TBD | 待从 `problem/task-requirements.csv` 映射 |  |  |  |  |  |  |

## 2. 数据版本与预处理接口

- 输入哈希：引用 `data/raw-hashes.csv`。
- 字段、单位、规则顺序、阈值、拟合范围、划分和防泄漏：引用 `data/preprocessing-plan.md`。
- 本模型只允许读取的 processed_id 与字段：待填写。
- 数据缺口及其对任务的影响：待填写。

## 3. 符号、变量、参数与量纲

| 符号 | 含义 | 类型 | 单位/量纲 | 定义域或范围 | 来源/估计方法 | 对应代码名 |
|---|---|---|---|---|---|---|
| 待填写 |  |  |  |  |  |  |

## 4. 基本假设

| assumption_id | 假设 | 题目给定/团队新增 | 依据 | 风险 | 可检验方式 | 不成立时动作 |
|---|---|---|---|---|---|---|
| A0 | 待填写 |  |  |  |  |  |

## 5. 简单基线模型

逐任务为 Tier 0 简单基线、Tier 1 竞赛主力模型和可选 Tier 2 高级候选分配 candidate_id 和 component_id。三层必须使用相同外层数据划分、评价单位、预测时点和主要指标；不得删除困难样本、换测试集或换指标制造表面增益。引用当前 request_id、理论证据与迁移限制，写出公式、参数估计、输入输出、实现入口及其局限。

## 6. 候选模型比较与选择

| task_id | tier | candidate_id | component_id | 方案与变体 | request_id | 证据覆盖 | 理论/教材/应用/局限证据 ID | 解决的低层缺陷 | 效果/稳定性/校准/成本门 | 入口与预算 ID | 回退层 | 风险与迁移限制 | 选择或淘汰理由 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TBD | TIER_0 | CAND-TBD | COMP-TBD | 待填写 | REQ-TBD | REQUESTED |  |  |  | BUD-TBD | NONE |  |  |
| TBD | TIER_1 | CAND-TBD | COMP-TBD | 待填写 | REQ-TBD | REQUESTED |  |  |  | BUD-TBD | TIER_0 |  |  |
| TBD | TIER_2 | CAND-TBD | COMP-TBD | 可选 | REQ-TBD | REQUESTED |  |  |  | BUD-TBD | TIER_1 |  |  |

### 6.1 算法证据回审

- 当前 round_id 与 plan_version：待填写。
- 算法需求表：`model/algorithm-evidence-request.csv`。
- 覆盖表与检索日志：`research/algorithm-evidence-coverage.csv`、`research/search-log.csv`。
- 矛盾证据及处理：待填写。
- 因证据不足而降级或淘汰的算法：待填写。
- 团队提出的新组合及其不能声称的内容：待填写。

## 7. 最终模型数学定义

按任务依次给出输入、输出、目标函数、约束、完整方程、边界/初始条件、单位检查、参数估计和适用条件。每个最终组件必须标出 candidate_id、component_id、request_id 和证据 ID；公式中的每个符号必须能在第 3 节找到。

## 8. 算法与实现契约

写出数据流、伪代码、初始化、随机性、停止条件、容差、最坏/典型复杂度、数值稳定措施、依赖和预期入口。指出模型计划与代码模块的一一映射。

### 8.1 决策分类与冻结前审查接口

- A 类受保护科学决策：见 `model/protected-invariants.md` 与 `model/decision-register.csv`，由用户审批。
- B 类数学等价实现约定：见 `model/implementation-defaults.md`，由架构师与实施者在冻结前固定。
- C 类代码缺陷：冻结后由实施者记录到 `reports/bug-fix-log.csv`。
- 计算入口与预算：见 `model/complexity-budget.csv`。
- G2-B 联合签收：见 `model/implementation-readiness.md`；只允许纸面与 `tests/contract/` 合成小例。

## 9. 预注册检验矩阵

每行在看见正式结果前填写；结果产生后不得回改阈值冒充通过。

| verification_id | task_id | 类型 | critical | 因素/场景 | 基准值 | 范围或离散场景 | 步长/网格 | 重复次数与种子 | 数据划分 | 指标 | 通过阈值 | 证据路径 | 失败动作 | 适用性 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| V-BL | ALL | 基线比较 | YES | 待填写 |  |  |  |  |  |  |  | `outputs/verification/` |  | REQUIRED |
| V-SA | ALL | 灵敏度 | YES | 关键参数/预处理阈值 |  |  |  |  |  |  |  | `outputs/verification/` |  | REQUIRED |
| V-RB | ALL | 稳健性 | YES | 噪声/缺失/异常/划分/情景 |  |  |  |  |  |  |  | `outputs/verification/` |  | REQUIRED |
| V-AB | ALL | 消融或替代模型 | NO | 模块/特征/约束 |  |  |  |  |  |  |  | `outputs/verification/` |  | REQUIRED_OR_JUSTIFY_NA |
| V-RP | ALL | 复现与随机性 | YES | 独立运行 |  |  |  |  |  |  |  | `outputs/verification/` |  | REQUIRED |
| V-CX | ALL | 复杂度与规模 | YES | 样本/节点/时段规模 |  |  |  |  |  |  |  | `outputs/verification/` |  | REQUIRED |

### 灵敏度最低要求

- 选择会影响论文结论的参数，不只选择容易展示的参数。
- 明确局部单因素、全局采样或情景分析的选择理由；参数交互重要时必须使用全局或二维分析。
- 同时报告输出变化、排序/决策稳定性、阈值跨越和失效区间；不只给一张平滑曲线。
- 若模型无可调参数，必须分析关键输入、权重、预处理阈值或边界假设，并说明 `NOT_APPLICABLE` 的理由。

## 10. 不确定性、失败判据与备用路线

定义逐任务和总体失败条件、数值/统计/业务阈值、置信区间或误差来源。每种失败写清继续、降级基线、换候选模型或回到 G2 的动作。

### 防循环停止规则

- Tier 2 连续两次因同一识别、收敛或预算原因失败，直接退到冻结的 Tier 1，不再改方案挽救。
- Tier 1 能回答题目且通过质量门时，不因追求高级模型阻塞交付；Tier 1 失败但 Tier 0 仍能完整回答题目时，使用 Tier 0 并限制声明；所有冻结 Tier 均不能回答时才重开 G2。
- G2-B 通过后，G3 只处理具体失败，不再全面审计整个方案。
- 进入预设安全窗口后不新增模型家族，只修复 C 类缺陷并完成验证、制图和写作。

## 11. 预期论文产物登记

| artifact_id | task_id | 类型 | 内容 | 预期路径 | 输出格式 | 生成脚本 | 源数据 | 单位/图注要求 | 目标章节 | 支持的拟写结论 |
|---|---|---|---|---|---|---|---|---|---|---|
| TBD |  | 图/表/数值 |  |  | CSV/JSON/PNG/SVG/PDF 等 |  |  |  |  |  |

## 12. 未决选择与冻结清单

- 未决选择：待填写；若会改变方法或结论，不得冻结。
- [ ] 所有 task_id 已覆盖。
- [ ] 数据与预处理契约完整且一致。
- [ ] 基线、候选、最终模型和选择理由完整。
- [ ] 所有采用的算法与关键辅助算法都有稳定 ID，并与当前版本证据请求双向映射。
- [ ] 最终核心组件的理论、教材/专著、相近应用和比较/局限证据覆盖完成；摘要不能代替理论全文核对。
- [ ] 不存在 `STALE / GAP / BLOCKED / PARTIAL / CONFLICTED / UNSUPPORTED` 的最终组件，矛盾证据和团队新组合已明确处理。
- [ ] 每个 task_id 都有 Tier 0/1，Tier 2 若存在则有增益门和直接回退路线，三层评价口径一致。
- [ ] `complexity-budget.csv` 的入口、拟合次数、时间/内存/磁盘、窗口占比、安全余量和失败动作完整。
- [ ] A 类受保护决策完整且无未决项；B 类默认项有等价性判据；C 类有 bug/fix 日志入口。
- [ ] G2-B readiness 为 `READY_FOR_USER_REVIEW`、双方签收为 YES，且规范化哈希匹配当前文件。
- [ ] 用户批准原话、时间和 G2-C 审批包 SHA-256 已登记，且与 readiness 审查包一致。
- [ ] 公式、单位、算法、复杂度和实现接口完整。
- [ ] 灵敏度、稳健性、消融、复现、复杂度均已预注册或合理说明不适用。
- [ ] 失败阈值、备用路线和论文产物已定义。
- [ ] 建模手已批准当前精确版本。

<!-- G2-CONTRACT-END -->
