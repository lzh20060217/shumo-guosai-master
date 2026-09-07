# 数学建模竞赛 Agent 模板

这是一个可复制给正式比赛项目使用的 Codex 模板。它采用“一个总控任务 + 六个长期专业任务”的多对话结构，把工作分成文献、建模、实现、独立检验、论文提纲和发布交接六个角色，并用 G0–G6 防止跳步与无证据写作。

完整比赛操作见 `WORKFLOW-GUIDE.md`；多对话注册、派单、回执和恢复规则见 `coordination/README.md`。

## 第一次使用

1. 复制整个文件夹并改成比赛项目名称。
2. 把当届官方规则记录到 `competition/competition-profile.md`，把题目原文放进 `problem/`，把原始数据放进 `data/raw/`。
3. 把本文件夹作为 Codex 本地项目的主目录打开。所有角色任务都使用这个共享目录，不要创建隔离 worktree。
4. 在第一个任务中发送以下初始化命令。若当前 Codex 客户端支持任务创建与任务间消息，总控应创建并置顶六个长期角色任务；否则你按 `coordination/role-thread-prompts.md` 手动新建六个任务。两种方式都必须登记 `coordination/thread-registry.csv`；此步骤只建立对话拓扑，不开始建模：

   ```text
   使用 $math-modeling-competition。初始化本项目的长期多对话工作流：当前任务作为 coordinator；在同一 saved local project 和共享主目录中分别创建 literature_researcher、model_architect、model_implementer、model_verifier、paper_outline_writer、release_packager 六个长期任务，按 coordination/role-thread-prompts.md 命名和发送启动提示，登记 thread-registry.csv 并置顶。若当前客户端不支持自动创建或跨任务消息，明确列出需要我手动新建/转发的六项，不得伪造 thread_id 或已送达状态。不要使用 worktree，不要开始 G0，不要打包。
   ```

5. 初始化完成后，只在总控任务中发送比赛推进命令：

   ```text
   使用 $math-modeling-competition。先完成 G0；然后按 coordination 协议为长期文献任务和建模任务建立 G1 dispatch，等待回执并执行证据回审。不要在当前对话临时重建同角色 Agent，不要提前冻结方案或写正式模型代码。
   ```

6. G2-A 完成后，总控向实施和验证两个长期任务分别派发 G2-B；只有 readiness 为 `READY_FOR_USER_REVIEW`、双签收和哈希匹配，建模手才能在总控任务的 G2-C 批准精确审查包并同步冻结。

## 常用命令

- 开始检索：`给长期 literature_researcher 任务建立 G1_EVIDENCE dispatch，完成题目机制、基线、候选方法族、指标和局限证据。`
- 生成算法需求：`给长期 model_architect 任务建立 G1_ALGORITHM_REQUEST dispatch，生成带稳定 ID 的 algorithm-evidence-request.csv；先不选最终模型。`
- 定向算法取证：`把当前算法需求作为新 dispatch 发回长期 literature_researcher，检索理论、教材章节、相近应用、比较与局限论文。`
- G2-A 设计：`给长期 model_architect 建立 G2_A_DESIGN dispatch，建立 Tier、A/B 决策、预算、效果门与冻结回退，保持 DRAFT。`
- G2-B 实施审查：`给长期 model_implementer 建立 PREFREEZE_READINESS dispatch，只用纸面和合成小例检查可实现性。`
- G2-B 独立挑战：`给长期 model_verifier 建立 PREFREEZE_READINESS dispatch，检查可检验性、阈值独立性和回退路线。`
- 批准方案：`批准 readiness_id 和 G2-C 审批包 SHA-256 对应的 A 类科学决策与 Tier 规则，同步冻结 model/preprocessing。`
- 实现与运行：`给长期 model_implementer 建立 G3_EXECUTION dispatch，按 Tier 与冻结回退实现并运行。`
- 独立检验：`给长期 model_verifier 建立 G4_VERIFICATION dispatch，独立复现并完成灵敏度、稳健性、消融和声明审计。`
- 论文交接：`给长期 paper_outline_writer 建立 G5_OUTLINE dispatch，依据已验证结果生成论文写作大纲。`
- 终稿自查：`完整论文编译后执行 G5.5，按 reports/late-stage-ai-self-check.csv 核查 20 项并处理全部问题。`
- 手动打包：`打包当前工程，标签为 model-v1，生成快照。`
- 严格发布：`打包当前工程，标签为 final，按 Release 模式检查。`

打包只会在用户明确下令时执行，没有任何定时任务。

## 队友接手

队友解压或换设备后，原 thread_id 不能假定仍可访问。队友从项目根目录打开自己的 Codex，先重建多对话拓扑，再发送：

```text
使用 $math-modeling-competition，读取 HANDOFF.md、PROJECT_STATUS.md、coordination/README.md 和 CONTROL-BOARD.md；把旧线程注册标为 RETIRED，在当前环境按 role-thread-prompts.md 重建七个长期任务并增加 generation。随后依据已核验 receipt 判断当前质量门继续；不得破坏冻结方案。
```

如果队友的账户没有模板中指定的模型，可以在 `.codex/agents/*.toml` 中替换模型，但不要修改角色边界和质量门。

## 你应该查看什么

- 总进度：`PROJECT_STATUS.md`。
- 对话拓扑和当前派单：`coordination/thread-registry.csv`、`coordination/CONTROL-BOARD.md`、`coordination/dispatch-log.csv`。
- 当前队友行动：`HANDOFF.md`。
- 每道小问是否闭环：`problem/task-requirements.csv`。
- 方案是否允许实现：`model/PLAN_STATUS.txt` 与 `data/PREPROCESSING_STATUS.txt`；只有二者均为 `FROZEN` 才能进入 G3。
- 冻结前是否真正可实现：`model/implementation-readiness.md`、`model/protected-invariants.md`、`model/implementation-defaults.md`、`model/decision-register.csv`、`model/complexity-budget.csv` 与 `tests/contract/`。
- 算法是否有理论依据：`model/algorithm-evidence-request.csv`、`research/algorithm-evidence-coverage.csv`、`research/search-log.csv` 与 `research/algorithm-briefs/`。
- 数值和图表从哪来：`outputs/artifact-manifest.csv`。
- 论文结果底表与草图：`outputs/tables/raw/`、`outputs/tables/final/`、`outputs/figures/drafts/`、`outputs/figures/final/`。
- 灵敏度等检验是否真的完成：`reports/verification-report.md` 与 `reports/claim-audit.csv`。
- 论文手怎么写：`writing/paper-outline.md` 与 `writing/claim-evidence-matrix.csv`。

不要手工把占位模板状态改为 `PASS`。每一门必须用对应文件、命令和产物证明。
