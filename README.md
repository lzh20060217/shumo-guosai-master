# shumo-guosai-master

面向全国大学生数学建模竞赛（CUMCM）的 Codex 总控技能，重点服务同时承担建模与编程工作的队员。它把题意、数据、模型、代码、验证、图表、论文、AI 使用记录和交付包连接成可复核链条。

> 本项目不是全国大学生数学建模竞赛组委会的官方工具、规则或评分系统。比赛要求始终以当届官方文件为准。

## 核心特点

- G0--G6 分阶段推进：规则与数据、证据、模型冻结、实现、验证、论文、交付；
- 默认三人队轻量流程，只有用户明确要求时才启用多角色完整审计；
- 每问优先可解释基线和一个适配的主力模型，不以算法数量或复杂度为目标；
- 原始数据只读，前问清洗结果必须传递给后问；
- 论文数字、表和图必须来自可运行代码及统一结果源；
- AI 使用日志、声明和详情报告保持一致；
- G5.5 晚期 AI 辅助自查：在论文完成后、打包前执行 5 个维度、20 个可追踪项目。

## 安装

将仓库克隆到 Codex skills 目录：

```bash
git clone https://github.com/lzh20060217/shumo-guosai-master.git ~/.codex/skills/shumo-guosai-master
```

重新启动 Codex 后，在新对话中调用：

```text
$shumo-guosai-master
```

例如：

```text
使用 $shumo-guosai-master 开始本届国赛 B 题。先读取官方规则、题目和附件，只完成 G0 数据与任务盘点，不要提前写正式模型代码。
```

## 新建比赛项目

```bash
python3 ~/.codex/skills/shumo-guosai-master/scripts/init_project.py "/绝对路径/比赛项目"
```

初始化脚本拒绝覆盖已有目录。随后把当届官方规则、题目和原始附件放入项目，按 G0 开始。

快照检查：

```bash
python3 ~/.codex/skills/shumo-guosai-master/scripts/check_project.py \
  --root "/绝对路径/比赛项目" --mode snapshot
```

正式交付检查：

```bash
python3 ~/.codex/skills/shumo-guosai-master/scripts/check_project.py \
  --root "/绝对路径/比赛项目" --mode release
```

## G5.5 晚期自查说明

`references/late-stage-ai-self-check.md` 将一份第三方图片清单转化为可审计流程。原图声称有六个维度、26 项，但用户提供的图片实际只显示五个维度、20 项，因此本项目只收录可见的 20 项，不补造缺失内容。

该环节不会把“AI 文风检测”当成可靠的违规鉴定，而是核对：

- AI 使用声明、日志与真实产物是否一致；
- 数据、文献、图表和数字是否可追溯；
- 题意、模型、求解、参数和结论是否自洽；
- 摘要、正文、结果和结论是否一致；
- 论文是否经过真实人工复核。

记录模板位于 `assets/project-template/reports/late-stage-ai-self-check.csv`，校验工具为 `scripts/check_late_stage_ai_audit.py`。

## 目录

```text
shumo-guosai-master/
├── SKILL.md
├── agents/openai.yaml
├── references/
├── scripts/
└── assets/project-template/
```

技能会按任务逐步读取参考文件，不建议一次性把全部模板载入上下文。

## 安全与合规

- 不要把未公开赛题、受限数据、队员隐私、账号令牌或未获授权的论文全文提交到公开仓库。
- AI 检测器分数不能单独证明作者身份或违规。
- 不得为“降低 AI 率”隐瞒真实 AI 使用、篡改数据、伪造文献或虚构实验。
- 深度学习不是获奖条件；模型适配、结果效果、稳定性和解释性更重要。

## 许可证

本项目采用 [MIT License](LICENSE)。第三方名称、规则和工具仍归各自权利人所有；详见 [NOTICE](NOTICE.md)。
