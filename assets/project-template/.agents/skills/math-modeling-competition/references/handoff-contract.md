# 已废弃的旧打包与交接摘要（仅供迁移）

> 不再作为验收依据。请读取 `handoff-contract-v2.md`；论文提纲交接为 G5，用户命令触发的打包为 G6。

## 触发规则

仅在用户当前消息明确要求以下动作时打包：打包、压缩、生成快照、生成交接包、正式发布。

完成阶段、测试通过或等待队友都不是自动打包授权。不得创建定时任务。

## 模式

### Snapshot

用于阶段性备份和队友协作。允许存在 DRAFT 方案、未完成检验和已知失败，但必须在清单和 `HANDOFF.md` 中如实说明。

### Release

用于最终或严格发布。要求：

- `model/PLAN_STATUS.txt` 为 `FROZEN`
- `PROJECT_STATUS.md` 和 `HANDOFF.md` 存在
- `reports/verification-report.md` 存在且不含未解释的关键失败
- 验证脚本的严格检查通过

## 默认排除

- `.git/`
- `releases/` 中已有产物
- 虚拟环境、依赖缓存、Notebook缓存和测试缓存
- `.env`、密钥、证书、凭据和命名为 secrets 的文件
- `research/library/papers/` 与 `research/library/books/` 全文

## 必需交接内容

- `AGENTS.md`
- `.codex/agents/`
- `.agents/skills/math-modeling-competition/`
- `PROJECT_STATUS.md`
- `HANDOFF.md`
- 题目、必要数据、证据矩阵、冻结方案、代码、实验入口和检验报告
- 包清单、排除项说明和 SHA-256

## 接手顺序

1. 验证 ZIP 的 SHA-256。
2. 解压并从项目根目录打开 Codex。
3. 读取 `HANDOFF.md`、`PROJECT_STATUS.md`、`model/model-plan.md` 和检验报告。
4. 复现当前主要结果。
5. 再继续新的实现或测试。
