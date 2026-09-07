# 派单 DISPATCH-TBD

- protocol_version: THREAD-PROTOCOL-v1
- dispatch_id: DISPATCH-TBD
- gate: TBD
- subgate: TBD
- mode: TBD
- from_role: coordinator
- to_role: TBD
- role_generation: 0
- thread_id: TBD
- request_sha256: 由总控在定稿后计算并登记到 dispatch-log；本行不参与自身哈希
- input_bundle_sha256: TBD
- exclusive_scope_id: TBD
- allowed_write_scope: TBD
- expected_output_paths: TBD
- depends_on_dispatch_ids: NONE
- user_authorization_id: NONE
- created_at: TBD
- user_approval_required: NO

## 目标

TBD

## 权威输入

列出必须读取的项目文件、版本、哈希和上游 receipt。聊天补充不得覆盖这里的内容。

## 验收条件

1. TBD

## 禁止事项与停止条件

1. 不得超出 path ownership 和本派单授权范围。
2. 发现输入版本或哈希不一致时停止并回执 `BLOCKED`。
3. 不得自行把质量门改为 PASS，不得代替用户批准。

## 回执要求

在 `coordination/receipts/` 创建与 dispatch_id 唯一对应的回执，登记输出路径、SHA-256、阻塞和建议门状态。
