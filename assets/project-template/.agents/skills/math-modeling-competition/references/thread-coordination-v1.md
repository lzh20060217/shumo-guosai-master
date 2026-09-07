# 长期角色任务与跨对话路由契约

## 1. 逻辑模型

一个比赛项目固定包含一个 `coordinator` 总控任务和六个长期专业任务。它们是同一项目中的平级 Codex 任务，不依赖父子 Agent 生命周期；“子 Agent”仅表示业务角色从属于总控流程。

每个任务拥有独立聊天记录。共享上下文只来自同一项目目录中的文件、项目级 `AGENTS.md`、技能、派单和回执。任何只存在于某个聊天中的决定都不是持久项目事实。

## 2. 初始化

只有用户明确要求初始化多对话工作流时，总控才创建角色任务。全部任务使用同一个 saved local project 和主目录，标题按 `coordination/role-thread-prompts.md` 固定并建议置顶。

总控把自身与六个角色的 `thread_id`、`host_id`、generation 和状态写入 `coordination/thread-registry.csv`。每个角色最多一条 `ACTIVE` 记录；替换任务必须先退休旧任务。

## 3. 正式派单

每次正式派单必须包含：

- 唯一 `dispatch_id`；
- gate、subgate 和唯一 mode；
- from/to role、role generation、目标 thread_id；
- 权威输入文件、版本和 `input_bundle_sha256`；
- `exclusive_scope_id`、允许写入范围和预期输出路径；
- 上游 dispatch 依赖、验收条件、禁止事项和停止条件；
- 是否需要用户批准。

G6 派单还必须包含 `user_authorization_id`，并绑定 `coordination/user-authority-log.csv` 中当前、未消费、mode/label/bundle 一致且 `max_uses=1` 的授权。完成或取消后由总控消费该授权；历史授权不得复用。

先落盘 dispatch，再发送跨任务消息。若当前 Codex 客户端支持任务间消息，由总控直接路由；否则由用户把只含 dispatch_id 和路径的短消息人工转发到已登记任务。目标任务收到消息后必须重新读取项目状态、注册表和 dispatch，不得依赖消息中的简写重构要求，也不得把“客户端无路由能力”伪装为已送达。

## 4. 回执与合并

专业任务完成、阻塞或拒绝时都要写 receipt。receipt 至少包含 dispatch 文件 SHA-256、dispatch/role/generation/thread 绑定、输入哈希、状态、输出路径及哈希、阻塞、建议门状态、授权写入声明和未执行事项。

总控必须独立检查：

1. receipt 与活动 dispatch 一一对应；
2. thread、role、generation、mode 和输入哈希匹配；
3. 输出位于授权路径，文件存在且哈希匹配；
4. 上游依赖没有 `BLOCKED / SUPERSEDED`；
5. 角色没有越权批准、代签或自验；
6. 质量门的其他证据条件均满足。

只有检查完成后，总控才把接纳决定和 receipt 哈希写入 `coordination/sync-ledger.csv`，再合并共享状态、关闭 dispatch 并派发下游。`SUBMITTED` 不等于质量门通过；只有 `ACCEPTED` receipt 可以推动共享状态。

## 5. 写入所有权

`coordination/path-ownership.csv` 是默认所有权表。总控独占控制面和跨角色追踪表；角色独占自己的证据目录。专业角色不得直接修改总控控制面，只能在 receipt 中提出结构化更新建议。

同一时刻不得有两个活动 dispatch 使用同一 `exclusive_scope_id`。读操作可并行；写操作只有路径所有权互不重叠时才可并行。G2-B 的两个 review 是刻意分离的合法并行写入。v1 不允许跨所有权例外，也不自动抢占过期锁；若必须重新划分写入，先取消旧 dispatch，再由总控修改所有权并创建新 dispatch。

## 6. 质量门路由

| 阶段 | 必需完成的角色派单 |
|---|---|
| G1 | literature `G1_EVIDENCE`；architect `G1_ALGORITHM_REQUEST` 与 `G1_REVIEW`；必要时循环 |
| G2-A | architect `G2_A_DESIGN` |
| G2-B | implementer `PREFREEZE_READINESS` 与 verifier `PREFREEZE_READINESS`，随后 architect `G2_B_MERGE` |
| G2-C | coordinator 向用户展示精确审查包并记录批准；不得派给专业角色代批 |
| G3 | implementer `G3_EXECUTION` |
| G4 | verifier `G4_VERIFICATION` |
| G5 | paper writer `G5_OUTLINE` |
| G6 | 仅用户当前明确命令后派给 release packager |

G0 由总控组织并合并事实；如需专业角色早期只读建议，也必须用不授权其改变 G0 事实的派单。

## 7. 失效、超时和重建

- 任务失联或上下文污染不改变科学状态；以最后一个已核验 receipt 为准。
- 不复用失败或被取代的 dispatch_id。
- 替换任务从项目文件恢复，generation 加一；未完成旧派单标为 `SUPERSEDED`。
- 队友接手、项目复制或换设备后，原 thread_id 视为本地过期，重新建立任务拓扑。
- 不自动创建定时唤醒；需要继续工作时由总控发送一次性 follow-up，或由用户明确要求自动化。

## 8. 禁止事项

- 不得让六个角色都在总控对话内以临时同角色子 Agent 反复重建。
- 不得同时存在两个能写同一路径的同角色任务。
- 不得把跨任务消息、聊天摘要或 UI 中的“完成”当作门状态证据。
- 不得让专业任务直接更新用户批准、总体门状态或 G6 授权。
- 不得因为拆分对话而降低 G1 证据、G2 哈希、G4 独立性或 G5 产物追溯要求。
