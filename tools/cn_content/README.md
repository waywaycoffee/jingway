# 景行语文内容管线

将可商用开源库切成带 `grades` 的考试内容包。

## 商用源（可上线）

| 库 | 地址 | 用途 |
|----|------|------|
| chinese-xinhua | https://github.com/pwxcoo/chinese-xinhua | 字词释义、成语、听写卡（强推） |
| chinese-poetry | https://github.com/chinese-poetry/chinese-poetry | 古诗文默写精选 |
| chinese-dictionary | https://gitee.com/ridp/chinese-dictionary | 多音字、分级、词性、文言补充 |

## 仅研究（禁止打进正式包）

- NCR、CKnowEdit、cn-math-taxonomy → 放到 `data/research/` 且勿进 prod flavor。

## 用法

```bash
# 拉取 vendor（可选手动 git clone）
./tools/cn_content/fetch_vendors.sh

# 从 chinese-poetry 按清单生成年级诗文包（需已 clone vendor）
python3 tools/cn_content/build_poetry_exam.py

# 从 xinhua 生成示例词书骨架
python3 tools/cn_content/build_xinhua_syllabus.py
```

当前仓库已内置：

- `apps/mobile/assets/jingway/poetry/exam_core.json`（诗文精选，可从唐诗三百首扩展）
- `apps/mobile/assets/jingway/dict/xinhua_seed.json`（离线点词：字 / 词 / 成语）
- `apps/mobile/assets/syllabus/cn_g7_dictation.json` 等内置听写词书

研究数据（NCR / CKnowEdit）只放 `data/research/`（gitignored），由
`ResearchContentGate` 控制；**禁止**写入 `pubspec.yaml` assets。
详见 `docs/RESEARCH_CONTENT.md`；debug 入口：`/settings/research-lab`。

`fetch_vendors.sh` 若遇 GitHub 网络中断，可稍后重试；种子数据足够跑通 P0 UI。
