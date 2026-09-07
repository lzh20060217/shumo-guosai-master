# 资料库与论文学习规则

## 是否需要额外准备资料

建议准备一个“精选资料库”，但不建议下载海量论文和教材让 Agent 从头通读。真正有价值的是可检索的索引、与当前题型相关的少量全文，以及由 Agent 生成的结构化知识卡片。

## 推荐规模

- 往届优秀论文：优先收集与比赛类型和常见题型相关的 8～15 篇高质量论文。
- 建模教程：准备 1～3 本你确实有权使用的权威教材或讲义。
- 方法资料：每个可能采用的方法保留 2～5 篇经典或高质量应用论文。
- 规则资料：保留当前竞赛规则、评分标准、论文格式和官方数据说明。

资料数量不是质量指标。20篇经过索引和比较的资料通常比200篇未分类PDF更有用。

## 文件组织

```text
research/library/
├─ library-index.csv
├─ papers/          # 已授权保存的论文全文
├─ books/           # 已授权使用的教材或讲义
└─ notes/           # 针对资料生成的知识卡片
```

`library-index.csv` 建议字段：

- `id`
- `type`
- `title`
- `authors`
- `year`
- `contest_or_venue`
- `problem_family`
- `methods`
- `doi_or_url`
- `local_path`
- `license_or_access_note`
- `priority`
- `verified`
- `notes_path`
- `download_status`
- `downloaded_at`
- `download_url`
- `sha256`
- `size_bytes`
- `download_error`

其中 `verified` 只表示书目信息已经核验；全文是否成功保存以 `download_status`、本地路径和 SHA-256 为准。

## 使用顺序

1. 先扫描索引，不要先打开所有全文。
2. 根据题目、数据和候选方法筛选最高相关资料。
3. 只读取当前决策所需的章节、公式、实验或结论。
4. 为重要资料生成知识卡片，记录方法、假设、可迁移点、限制和原始页码。
5. 将跨资料比较写入 `research/evidence-matrix.csv`。
6. 对涉及最终模型的关键结论回到原文复核。

## 合法下载全文

文献 Agent 可以下载当前任务确实需要的论文全文，但必须同时满足：

- 来源是出版社开放 PDF、开放获取仓储、作者公开版本，或团队明确有权访问和保存的直链。
- 使用 HTTPS 直链，不把 Cookie、Token、账号或机构凭据写入命令、日志和项目文件。
- 不绕过付费墙、验证码、登录、访问频率限制或网站条款，不使用侵权镜像。
- 下载到 `research/library/papers/`，文件名使用稳定的文献 ID；不覆盖已有文件。
- 通过 PDF 文件头、文件大小和 SHA-256 检查后，才把 `local_path` 写入 `library-index.csv`。
- 在 `research/library/download-log.csv` 记录 URL、访问依据、本地路径、字节数、SHA-256、状态和失败原因。
- 只有摘要或付费页面时不下载，将索引标记为 `LINK_ONLY` 或 `PAYWALLED`，继续保留正式链接和元数据。

推荐命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".agents\skills\math-modeling-competition\scripts\download-paper.ps1" -ProjectRoot "." -Id "paper-id" -Url "https://example.org/paper.pdf" -AccessBasis "OPEN_ACCESS" -LicenseNote "Publisher open-access PDF"
```

脚本只负责安全下载、校验和日志；Agent 仍须独立核验论文元数据并更新 `library-index.csv`。

## 往届优秀论文的正确用途

- 学习问题拆解、指标选择、模型组合、检验方式和论文表达。
- 比较什么证据能支撑一个模型，而不是照搬题目专用参数。
- 识别常见缺陷，例如只报拟合指标、没有基线、缺少稳健性或把相关性写成因果。
- 不复制文字、结构或代码，不把获奖当作方法对当前题目一定有效的证明。

## 教材的正确用途

- 用于补全方法的定义、假设、推导、适用条件和标准诊断。
- 在知识卡片中保留章节和页码，避免只保存二手摘要。
- 当教材与最新论文的实践不一致时，分别记录基础理论和当前应用证据。
- 每本教材先登记到 `research/library/books/book-index.csv`。本地文件必须记录合法访问依据、版本、SHA-256 和知识卡路径；来源不明时只标 `ACCESS_UNVERIFIED`，不得读取、摘录、引用或满足 G1/G2 证据门。
- 对算法证据不得只写书名，必须记录章节、页码、对应 request_id/component_id 和具体支撑的定义、假设、公式或诊断。
- 没有可合法使用的本地教材时，用 `NO_AUTHORIZED_BOOK` 哨兵行记录原因，不要留下未登记文件或伪造章节页码。

## G1 与 G2 之间的算法证据回路

1. `model_architect` 先在 `model/algorithm-evidence-request.csv` 写基线、候选和算法组件的中性理论问题与双语关键词，不标首选。
2. `literature_researcher` 对每个请求分别执行中性、支持、比较、局限检索，把完整查询和负向结果写入 `research/search-log.csv`。
3. 将每一条来源按 `FOUNDATIONAL / TEXTBOOK_OR_MONOGRAPH / TASK_APPLICATION / COMPARATIVE_OR_LIMITATION` 登记到 `research/algorithm-evidence-coverage.csv`，并标记证据方向和独立来源组。
4. `model_architect` 根据覆盖、冲突和迁移限制比较候选。新算法或重要变体产生新 round_id；旧证据标记 `STALE`。
5. 只有当前版本的最终组件证据覆盖完整，G1 才可 `PASS`；之后才进入正式 G2 和用户冻结审核。

## 外部检索与本地资料的关系

本地资料库不能替代针对当前题目的实时检索。每道题仍应检索相关论文、数据说明和方法进展。资料库负责提供稳定基础，外部检索负责补齐题目特定证据。

## 版权与交接

- 只保存和共享团队有权使用或再分发的全文。
- 对不能随压缩包分发的资料，只交接索引、你们自己的笔记、页码和正式链接。
- 打包脚本默认排除 `papers/` 和 `books/`，只有用户明确要求且确认权限后才包含。
