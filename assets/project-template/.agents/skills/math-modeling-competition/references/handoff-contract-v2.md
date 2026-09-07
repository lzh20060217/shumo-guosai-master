# 写作交接与手动打包契约

## G5 写作交接

`paper_outline_writer` 只能整理已存在、已验证的证据，不得修改模型、代码、数据或创造数值。它在自己的长期任务中完成 G5 dispatch，并用 receipt 交给总控验收；共享状态和任务追踪仍由总控合并。它必须输出：

- `writing/paper-outline.md`：摘要句式、逐任务方法与结果、数据处理、基线、检验、局限、图表/公式位置和禁止夸大表述。
- `writing/claim-evidence-matrix.csv`：每个拟写结论到 evidence_id、artifact_id、verification_id 的映射。
- 更新的 `HANDOFF.md`：当前门、写作顺序、格式/页数预算、复现命令、阻塞和风险。

论文手先看大纲，再按 artifact_id 找原始结果表格和图；不要从聊天复制数字。

## G6 触发规则

只在用户当前消息明确要求打包、压缩、快照、交接包或正式发布时执行。阶段完成、测试通过或等待队友不是授权；不得创建定时任务。

Snapshot 允许上游未完成，但必须在 manifest 和 `HANDOFF.md` 如实警告。Release 要求 G0–G5 全部通过、方案冻结、关键验证全通过或有明确非关键限制、论文关键产物已验证。

默认排除 Git、旧 releases、环境/缓存、秘密，以及 `research/library/papers/`、`research/library/books/` 全文。仅在用户明确要求并确认分享权后包含全文。

交付 ZIP、manifest、SHA-256、验证日志和警告。接手者先验哈希，再读 `HANDOFF.md`、项目状态、任务追踪、冻结方案、产物清单、验证报告、论文大纲和 `coordination/README.md`。任务 ID/host ID 只在当前 Codex 环境有效；复制项目或交给队友后，应退休旧登记、提高 generation 并重新绑定七个任务，不能复用旧任务身份或旧 G6 授权。
