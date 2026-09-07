# 多对话协作协议

本项目采用“一个总控任务 + 六个长期专业任务”的 Codex 协作方式。七个任务都从同一个本地项目根目录启动，共享项目文件，但不假定彼此能读取其他任务的聊天记录。

## 固定拓扑

| logical_role | 建议任务标题 | 职责 |
|---|---|---|
| coordinator | `[项目代号] 00-总控` | 创建派单、检查回执、合并状态、执行质量门、向用户请求批准 |
| literature_researcher | `[项目代号] 10-文献` | G1 领域与算法证据、合法全文下载、教材章节取证 |
| model_architect | `[项目代号] 20-建模` | G1 算法需求、G2-A、readiness 合并和 A 类 CR 去重 |
| model_implementer | `[项目代号] 30-实现` | G2-B `PREFREEZE_READINESS`、G3 `G3_EXECUTION` |
| model_verifier | `[项目代号] 40-验证` | G2-B 独立挑战、G4 `G4_VERIFICATION` |
| paper_outline_writer | `[项目代号] 50-论文提纲` | G5 写作大纲和论断—证据映射 |
| release_packager | `[项目代号] 60-发布` | 只在用户明确命令后执行 G6 |

完整论文形成后，G5.5 由 `coordinator` 汇总自动一致性检查与队员人工复核，写入 `reports/late-stage-ai-self-check.csv`；它不新增长期角色，也不允许发布角色提前介入。

每个 logical_role 同时最多有一个 `ACTIVE` 任务。任务丢失或需要重建时，旧任务标为 `RETIRED`，新任务增加 `generation`；不得让两个同角色任务同时写项目。

## 为什么不能只在聊天里派单

- 各任务的聊天记录相互独立；跨任务消息只是提醒，不是正式证据。
- 所有正式派单先写入 `coordination/dispatches/`，再向对应任务发送短消息。
- 专业任务完成后先写 `coordination/receipts/`，总控核验文件、哈希和阻塞项后才更新 `PROJECT_STATUS.md`、`HANDOFF.md` 或质量门。
- 聊天中的数字、批准、结论或“已完成”若没有项目文件和回执，不得进入正式论文或质量门。

## 同目录要求

长期角色任务必须运行在同一个 saved local project 的主目录，使用共享本地目录，不使用相互隔离的 Git worktree。若必须使用 worktree，则本协议的即时共享写入无效，必须另行设计提交、合并和冲突解决流程。

## 派单流程

1. 总控读取 `PROJECT_STATUS.md`、`HANDOFF.md`、`coordination/CONTROL-BOARD.md` 和线程注册表。
2. 总控为本次工作创建唯一 `dispatch_id`，写完整派单文件，并在 `dispatch-log.csv` 登记输入版本、授权写入范围、预期输出和验收条件。
3. 总控向对应长期任务发送短消息，只引用 `dispatch_id` 和派单文件路径，不在聊天里另起一套要求。当前 Codex 客户端支持任务间消息时由总控发送；若所用客户端没有该能力，则由用户把这条短消息转发到已登记任务，正式证据仍以派单文件为准。
4. 专业任务核对自己的 role、generation、thread_id、mode 和允许写入范围；不匹配则拒绝执行。
5. 专业任务写角色产物和回执；回执包含派单文件哈希、输出路径、哈希、阻塞、建议门状态和禁止合并的事项。
6. 总控检查回执与实际文件，再把 `ACCEPTED / REWORK / REJECTED / CANCELLED` 决定写入 `coordination/sync-ledger.csv`，最后更新共享状态。专业任务不得直接把质量门改为 `PASS`。

## 并发原则

- 允许只读检索、审查和不同所有权目录并行。
- 禁止两个活动派单拥有相同 `exclusive_scope_id`。
- G2-B 的实施者和验证者可以并行，因为分别写自己的 review 和合成测试目录；共同 readiness 只能由建模任务在两份回执完成后合并。
- `PROJECT_STATUS.md`、`HANDOFF.md`、`coordination/CONTROL-BOARD.md` 和线程/派单登记只由总控写。
- G6 必须绑定 `coordination/user-authority-log.csv` 中由用户当前消息产生、尚未消费且只允许使用一次的授权；历史打包消息和旧授权不能复用。
- 写入所有权以 `coordination/path-ownership.csv` 为准；专业任务对共享文件只能在回执中提出修改建议。THREAD-PROTOCOL-v1 不允许跨所有权写入例外，不实现自动过期锁或自动抢占；需要例外时取消当前派单并由总控重新划分所有权和派单。

## 任务失效与替换

若任务无法继续、找不到或上下文污染：

1. 总控把旧注册行标为 `RETIRED`，保留旧 thread_id 和最后回执。
2. 创建同角色新任务，`generation + 1`，使用 `role-thread-prompts.md` 的启动提示。
3. 新任务只从项目文件、当前派单和角色合同恢复，不要求复制旧聊天全文。
4. 旧任务未完成的派单标为 `SUPERSEDED`，创建新 dispatch，不复用旧 dispatch_id。

## 本地标识与交接

`thread_id` 与 `host_id` 只用于当前 Codex 环境的任务路由，不是科学证据。项目交给队友或换设备后，应把旧任务标为 `RETIRED` 并在新环境重新注册；不得假定队友能访问原任务。

本模板只预置协议，不预造任务 ID。Snapshot 中七个角色可保持 `UNREGISTERED`；正式开赛初始化后才把它们登记为 `ACTIVE`。是否能自动创建、唤醒或跨任务发消息取决于当前 Codex 客户端；能力不可用时使用人工转发，不得伪造已路由或已收到的状态。
