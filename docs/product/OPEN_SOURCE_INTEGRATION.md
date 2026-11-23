# 开源项目接入对照（景行落地）

更新：2026-11-23。原则：**学闭环与交互，不抄教材正文；研究数据不进正式包；音视频只走 ECS。**

| 来源 | 接入方式 | 景行落点 | 状态 |
| --- | --- | --- | --- |
| **congcong-school** | 学「课→读→练→错题→报告」 | `/jingway` 阅读入口读练弹窗；专项交卷「学习报告」（按能力层汇总）；三年级分级故事 `g3-story-v1` | 已接样本 |
| **Binkic/Reciter** | 学挖空 / 理解性默写 **JSON 结构**；题干自建 | 诗文页「挖空」「理解默写」；`comprehensions_core.json`（景行原创题干 + MIT 诗句） | 已接样本；**不整包引入** Reciter 高考向题库 |
| **wceng/SuFei** | 宣纸阅读 + **TTS 逐句高亮** | 诗文「朗读」模式 + `JingwayClassicalText.highlightLineIndex`；TTS 经 ECS `readingSpeech` | 已接交互 |
| **CMRC2018 / PD&CFT Cloze** | 学过程技能标注 | 篇后题 `skill`：信息提取 / 直接推论 / 理解整合；报告按 skill 汇总 | 标注已用；**数据集不进 APK** |
| **HF gaokao-dataset** | 仅命题格式参考 | 文档保留；真题版权敏感 | **禁止商用整包** |
| **Mogao** | 点词、i+1、自托管进度 | `/reading` 书架 i+1、词表、阅读器点词新华；EPUB/TXT 导入 | 已有底座，入口已标明 |
| **zhread** | 早期点词 EPUB 思路 | 同 Mogao；不单独 vendoring | 参考 only |

## 明确不做

- ChinaTextbook / yuwen / dianzi-keben **正文**进 `assets`
- Reciter / 高考真题库整包打进安装包
- CMRC、Cloze、gaokao-dataset 原始语料进正式包
- 把 TTS 音频文件打进 APK（一律 ECS）

## 本地对照仓库

开发机可浅克隆到 `tools/vendor_refs/`（已 gitignore），勿提交。
