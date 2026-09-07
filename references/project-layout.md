# 项目初始化与目录说明

## 初始化

从空白路径初始化：

```bash
python3 "$SKILL_ROOT/scripts/init_project.py" "/绝对路径/比赛项目"
```

脚本拒绝覆盖已存在的非空目录。初始化后立即把当届规则放入 `competition/`、题目放入 `problem/`、原始附件放入 `data/raw/`，然后完成 G0；不要直接修改模板中的 PASS/FROZEN 状态。

## 新增目录

初始化脚本在原工程模板外补充：

- `paper/`：论文草稿、LaTeX 和最终 PDF；
- `deliverables/`：最终提交和队友交接包；
- `ai_usage_log.md`：AI 使用事实日志；
- `.skill-origin.json`：初始化来源与技能版本信息。

模板已包含 `reports/late-stage-ai-self-check.csv`。保持 20 个 `item_id` 不变，在完整论文形成后填写状态、位置、问题、整改、证据、核查人和时间。

## 检查

日常快照检查：

```bash
python3 "$SKILL_ROOT/scripts/check_project.py" --root "/绝对路径/比赛项目" --mode snapshot
```

正式交付检查：

```bash
python3 "$SKILL_ROOT/scripts/check_project.py" --root "/绝对路径/比赛项目" --mode release
```

也可单独校验晚期自查记录：

```bash
python3 "$SKILL_ROOT/scripts/check_late_stage_ai_audit.py" \
  --csv "/绝对路径/比赛项目/reports/late-stage-ai-self-check.csv" \
  --mode release
```

这只是跨平台基础检查。若 PowerShell 可用，还应运行项目模板自带的 `verify-project.ps1`；论文与 AI 报告还要运行 `cumcm-step-review` 的专用门禁。
