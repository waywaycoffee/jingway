# 景行语文 · GitHub / 开源参考清单

检索日期：2026-11-23。供产品与工程参考；**不等于可直接进正式包**。引用前核 LICENSE、是否含部编正文/受版权教材、是否研究数据集。

景行已用（见 `docs/ATTRIBUTION.md`）：`chinese-poetry`、`chinese-xinhua`、`chinese-dictionary` 等 MIT 语料；ChinaTextbook / yuwen / dianzi-keben **仅目录 + 按需打开**。

---

## 1. 产品形态接近（小学语文 / 阅读练）

| 项目 | Stars（约） | 许可 | 可参考点 | 景行注意 |
| --- | --- | --- | --- | --- |
| [wuwangzhang1216/congcong-school](https://github.com/wuwangzhang1216/congcong-school) 聪聪学堂 | 1.4k+ | MIT（代码） | 小学全科；语文听读、分级课外故事 + 阅读理解、连击激励、错题与学习报告、TTS | 教材结构引用 ChinaTextbook；**正文版权归权利人**，勿整书打进 APK；AI 生成题需人工审核思路可学 |
| [Binkic/Reciter](https://github.com/Binkic/Reciter) | ~70 | MIT | 高考古诗文**结构化默写题库**（挖空 / 理解性默写） | 可对照默写题型与 JSON 结构；上线前再核内容授权 |
| [wceng/SuFei](https://github.com/wceng/SuFei) 素扉 | ~80 | MIT | Flutter 诗词 App：宣纸风阅读、TTS 逐句高亮、筛选、桌面小组件 | UI/朗读交互可参考；内置大规模诗库需单独核数据源许可 |

官方站类（非纯 GitHub，体验可参考）：[叫叫](https://www.jojoreading.com/jojoApp)、[JOJOUP](https://jojoup.cn/) —— 见 PRD §7，学闭环不学年课私域。

---

## 2. 语料与词典（内容底座）

| 项目 | Stars（约） | 许可 | 可参考点 | 景行注意 |
| --- | --- | --- | --- | --- |
| [chinese-poetry/chinese-poetry](https://github.com/chinese-poetry/chinese-poetry) | 54k+ | MIT | 最全古诗词 JSON | **已用**；诗词领域评估与默写 |
| [pwxcoo/chinese-xinhua](https://github.com/pwxcoo/chinese-xinhua) | 11k+ | MIT | 汉字/词语/成语/歇后语 | **已用**；划词、字词领域 |
| [skishore/makemeahanzi](https://github.com/skishore/makemeahanzi) | 2.7k+ | 开源字形数据 | 笔顺、字形 SVG | 低年级写字可参考；核具体许可文件 |
| [gujilab/chinese-classical-corpus](https://github.com/gujilab/chinese-classical-corpus) | ~30 | 数据 CC0 / 代码 MIT | 十三经、史书结构化、古译今指令对 | 文言领域语料与评测思路；体量大，按需抽样 |
| [TapXWorld/ChinaTextbook](https://github.com/TapXWorld/ChinaTextbook) | 80k+ | 见仓库说明 | 小初高教材 PDF 汇总 | **仅目录/索引**；禁止部编正文进包（景行硬约束） |

---

## 3. 阅读理解 / 评测数据集（能力画像与出题）

| 项目 | Stars（约） | 许可 | 可参考点 | 景行注意 |
| --- | --- | --- | --- | --- |
| [ymcui/cmrc2018](https://github.com/ymcui/cmrc2018) | ~460 | 见仓库 | 中文抽取式阅读理解 | **研究/评测**；勿当正式商用题库直接上架 |
| [ymcui/Chinese-Cloze-RC](https://github.com/ymcui/Chinese-Cloze-RC) PD&CFT | ~170 | CC-BY-SA-4.0 | 完形阅读（人民日报 / 童话） | 同上；可学题型与难度分布 |
| [RainPPR/gaokao-dataset](https://huggingface.co/datasets/RainPPR/gaokao-dataset)（及相关 GitHub） | — | 见页面 | 高考语文题结构化（含古诗阅读等） | 真题版权敏感；适合命题格式参考，不宜整包商用 |
| 叫叫 × 北师大阅读能力测评口径 | — | 非开源 | 信息提取 / 推论 / 整合 / 评价 | PRD §8 过程技能已对齐思路 |

NCR、CKnowEdit 等：**禁止进正式包**（PRD / ATTRIBUTION）。

---

## 4. 中文电子书阅读器 / 伴读交互

| 项目 | Stars（约） | 许可 | 可参考点 | 景行注意 |
| --- | --- | --- | --- | --- |
| [Mogao](https://mogao.org/)（开源 MIT，自托管） | — | MIT | 中文 EPUB：点词词典、拼音、i+1 高亮、生词卡、进度自托管 | **电子书阅读器 UX** 强相关；景行划词用新华，TTS/伴读走 ECS |
| [newhouseb/zhread](https://github.com/newhouseb/zhread) | 少 | MIT | 早期中文 EPUB + 悬停释义 | 思路参考，代码老旧 |
| Flutter EPUB 生态（如社区 `epub_view` / 各类 `flutter_epub_*`） | 不等 | 各异 | 与现有 `/reading` 导入管线对照 | 景行已有 epub/txt 导入底座，优先增强中文书架与中文 UX，而非重写引擎 |
| HSK 分级阅读站 [lm742611149/learn-chinese](https://github.com/lm742611149/learn-chinese) / readmandarin | 少 | 代码 MIT | 分级短文 + quiz + 点词 + 音频 JSON 格式 | 面向二语；**格式**可参考课外短篇 schema，正文自建/自审 |

古典诗词本地阅读（搜「古典诗词阅读器」可得若干个人项目，如基于 `chinese-poetry` 的浏览器阅读器）：拼音注音、点字释义、TTS —— 可参考伴读/诗文页交互，数据仍走 MIT 诗库。

---

## 5. 对景行的优先借鉴（落地建议）

1. **题库与默写结构**：Reciter 的挖空/理解性默写 JSON；congcong 的「课 → 练 → 故事理解题 → 报告」闭环（内容自建或授权，不抄教材正文）。  
2. **阅读器 UX**：Mogao 的点词、章节进度、词汇覆盖；景行对应新华查字 + 摘录素材本 + 中文书架。  
3. **诗词/文言**：chinese-poetry + classical-corpus 做领域语料；SuFei / 诗词阅读器做 UI。  
4. **能力评估**：CMRC/完形学「题型与过程技能标注」，不用研究集冒充课内真题。  
5. **明确不碰**：ChinaTextbook PDF 正文进包；未授权高考真题整包商用；研究集进正式 APK。

**落地进度**见 [OPEN_SOURCE_INTEGRATION.md](./OPEN_SOURCE_INTEGRATION.md)（诗文挖空/理解默写/朗读高亮、读练报告、分级故事样本已接）。

---

## 6. 后续可继续扫的关键词

```
GitHub: 语文题库 / 古诗文默写 / 文言文数据集 / 分级阅读 中文
GitHub: chinese graded reader / chinese epub dictionary / PIRLS chinese
Flutter: epub_view / foliate
HuggingFace: chinese reading comprehension / gaokao chinese
```

有新候选时：记 Stars、License、是否含教材正文、与 PRD 哪一 `domain`（阅读/写作/文言/诗词…）对齐，再决定「只参考交互 / 可进语料 / 禁止」。
