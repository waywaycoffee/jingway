# Research corpora（禁止进正式包）

本目录存放 **NCR / CKnowEdit** 等仅研究用途的数据。

- 真实语料文件被 `.gitignore` 忽略，**不得**提交、**不得**写入 `apps/mobile/pubspec.yaml` assets。
- 客户端通过 `ResearchContentGate` 控制；release/profile **始终关闭**。
- 仅允许提交：本 README、`schemas/` 下的空 schema 说明。

## 本地放置

```text
data/research/
  ncr/           # Native Chinese Reader 导出（自备）
  cknow_edit/    # CKnowEdit 切片（自备）
  schemas/       # 字段约定（可提交）
```

调试时把 JSON 放到对应目录后，在 debug 构建中显式打开门禁（见 `docs/RESEARCH_CONTENT.md`）。

## 禁止

- 打进 `prod` flavor / 正式 APK
- 作为付费权益内容
- 与 MIT 商用词书/诗文包混目录
