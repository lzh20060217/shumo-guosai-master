# 来源、版本与迁移

## 融合来源

1. `cumcm-step-review`：本机兄弟技能目录 `../cumcm-step-review`。主要复用论文写作、摘要、算法索引、科研绘图、DOCX、LaTeX、PDF、Excel、论文检索和2026 AI报告门禁。
2. `math-modeling-competition`：原始快照完整保存在 `assets/project-template/`。主要复用 G0–G6、Tier、冻结审批、证据矩阵、artifact manifest、独立验证和可交接工程结构。
3. 模拟赛复盘原则：算法适配和真实效果优先；每问不堆模型；前问产物传递给后问；数据图由代码生成；统一事实源解决论文与单题报告数字冲突。
4. 可选本地技能 `../scibox-figure`：用于真实 CSV/TSV 数据图与图表溯源。其复杂样式模板源于 `jihe520/sci-box`，因核对时上游缺少明确整体许可证，不把第三方源码并入本公开仓库。

## 版本信息

- 专属技能：`shumo-guosai-master`，当前版本 1.2.0；初始版本 1.0 创建于 2026-09-06，1.1.0 于 2026-09-07 新增 G5.5 晚期 AI 辅助自查，1.2.0 于 2026-09-08 新增可选真实数据绘图路由与 provenance 约束。
- `cumcm-step-review`：安装时仓库声明 v1.8；正式比赛前可检查上游更新，但不要在比赛中途无审计升级。
- 内置项目模板：快照生成于 2026-09-06，原始 manifest 和历史验证日志保留。

## 迁移

将 `shumo-guosai-master` 与 `cumcm-step-review` 两个文件夹放入目标机器的 `~/.codex/skills/`。如需统一的真实数据绘图入口，再单独安装经过许可核对和本机适配的 `scibox-figure`。重新启动 Codex 后使用 `$shumo-guosai-master`。不要从 `assets/project-template/` 原位比赛，应使用初始化脚本复制到独立项目目录。

新机器至少需要 Python、NumPy、Pandas、SciPy、Matplotlib、scikit-learn、openpyxl、python-docx、lxml、statsmodels、pypdf、pdfplumber、Pillow 和 PyYAML；生成论文建议准备 XeLaTeX。Draw.io、Pandoc、LibreOffice、MATLAB 按赛题需要安装。

项目模板的完整校验脚本是 PowerShell；没有 `pwsh` 时先用本技能 Python 检查器，不能把基础检查等同于完整 Release 门禁。
