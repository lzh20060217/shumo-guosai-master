# 项目状态

最后更新：2026-09-06（可分享模板 Snapshot 维护；不代表任何具体赛题过门）

| 质量门 | 状态 | 负责人 | 主要证据 |
|---|---|---|---|
| G0 赛制、题目与数据盘点 | NOT_STARTED | 总控 Agent | `competition/`, `problem/task-requirements.csv`, `data/data-inventory.csv` |
| G1 文献检索与证据矩阵 | NOT_STARTED | literature_researcher | `research/evidence-matrix.csv`, `research/algorithm-evidence-coverage.csv` |
| G2 预处理、方案与冻结前可实现性 | NOT_STARTED | model_architect + model_implementer + model_verifier + 用户 | `model/model-plan.md`, `data/preprocessing-plan.md`, `model/implementation-readiness.md`, `model/g2-approval.json` |
| G3 实现、运行与产物登记 | NOT_STARTED | model_implementer | `outputs/result-summary.json`, `outputs/artifact-manifest.csv` |
| G4 独立分析与检验 | NOT_STARTED | model_verifier | `reports/verification-report.md`, `reports/claim-audit.csv` |
| G5 论文提纲与写作交接 | NOT_STARTED | paper_outline_writer | `writing/paper-outline.md`, `writing/claim-evidence-matrix.csv` |
| G6 用户命令触发的打包 | NOT_STARTED | release_packager | `releases/`, `HANDOFF.md` |

## 当前结论

- 模板仍是空白竞赛项目，G0-G6 均未针对具体赛题执行；`model/PLAN_STATUS.txt` 与 `data/PREPROCESSING_STATUS.txt` 保持 `DRAFT`。
- G5.5 为完整论文形成后的补充自查，不单列为官方质量门；状态记录在 `reports/late-stage-ai-self-check.csv`，Release 前必须完成。
- G1 保留“基础检索—算法证据需求—定向检索与合法下载—证据覆盖—架构师回审”闭环；新增算法或重要变体会使旧覆盖失效并重开定向 G1。
- G2 已拆成 G2-A 方案设计、G2-B 独立冻结前可实现性审查、G2-C 用户批准与同步冻结。模板升级不等于用户批准任何模型。
- 每题采用 Tier 0 基线、Tier 1 主力、可选 Tier 2 高级候选；相同外层划分、评价单位和主指标，按预注册效果、区间、稳定性、校准和成本门选择，并保留失败候选。
- A 类科学决策需要用户批准；B 类等价实现约定需登记和契约测试；C 类代码缺陷进入 bug 修复日志。G3 不允许重新发起无边界全面审计。
- 验证器会检查双角色独立签收、规范化哈希、决策关闭、Tier 预算与回退、用户批准绑定和模型/预处理同步冻结。
- 模板采用一个总控任务和六个长期角色任务；正式派单、回执、写入所有权和角色代次记录在 `coordination/`。当前注册表仍为 `UNREGISTERED`，未创建任何具体比赛任务。
- 用户已明确授权生成标签为 `math-modeling-template` 的空白模板 Snapshot；该维护性导出不代表任何具体比赛的 G6 通过，接收者仍须从 G0 重新开始。

## 当前阻塞

- 尚未放入正式题目、当届规则与数据，因此不能开始 G0，更不能生成 G2 审查包或冻结方案。

## 下一步

- 正式比赛开始后先核验当届规则、放入题目和数据并完成 G0；随后按 `START-HERE.md` 和 `WORKFLOW-GUIDE.md` 推进。
