# 研究内容隔离（NCR / CKnowEdit）

## 规则

| 项 | 要求 |
|----|------|
| 存放 | 仅 `data/research/`（gitignored，真实语料不入库） |
| 门禁 | `ResearchContentGate`；`kReleaseMode` 恒为关闭 |
| 正式包 | **禁止**写入 `pubspec.yaml` assets / prod flavor |
| 商用 | 不可作为付费权益 |

## 原型能力（门禁开启时）

1. **NCR 风格阅读选择题**：篇段 + 选项 + `errorCategory`（literal / inference / method）+ `methodCard`
2. **CKnowEdit 风格填空**：`prompt` 含空，提交后走汉字级 `diffCnDictation`

真实 NCR / CKnowEdit 正文需研究者自行取得并放入本地目录；仓库只保留 schema 与合成夹具（`test/fixtures/research/`）用于单测。

## 开启方式（debug）

默认 `_localDebugAllow = false`。单测使用 `ResearchContentGate(debugOverride: true)`。
本地手工验证可临时改门禁或注入 `remoteEnabled`（仍不得在 release 生效）。
