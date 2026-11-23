# 开源项目接入对照（景行落地）

更新：2026-11-23。原则：**学闭环与交互，不抄教材正文；研究数据不进正式包；音视频只走 ECS。**

| 来源 | 接入方式 | 景行落点 | 状态 |
| --- | --- | --- | --- |
| **congcong-school** | 学「课→读→练→错题→报告」 | `/jingway/reading` 读练弹窗；篇后题入口（g3/g7）；交卷「学习报告」；订正验证带 skill | 已接样本 |
| **Binkic/Reciter** | 学挖空 / 理解性默写 **JSON 结构**；题干自建 | 诗文「挖空」「理解默写」；`comprehensions_core.json` 覆盖核心篇目 | 已接；**不整包** Reciter 题库 |
| **wceng/SuFei** | 宣纸阅读 + **TTS 逐句高亮** | 诗文「朗读」+ 行高亮；短篇连续朗读用 CJK 分词 | 已接交互 |
| **CMRC2018 / PD&CFT Cloze** | 学过程技能标注 | 篇后题与验证题 `skill`；报告按层汇总 | 标注已用；**数据集不进 APK** |
| **HF gaokao-dataset** | 仅命题格式参考 | 文档保留；真题版权敏感 | **禁止商用整包** |
| **Mogao** | 点词、i+1、自托管进度 | CJK 分词 + 新华点词；摘录→作文素材本；书架 i+1 | 中文路径已打通 |
| **zhread** | 早期点词 EPUB 思路 | 同 Mogao；不单独 vendoring | 参考 only |

冒烟：`./tools/cn_content/verify_oss_integration.sh`

## 明确不做

- ChinaTextbook / yuwen / dianzi-keben **正文**进 `assets`
- Reciter / 高考真题库整包打进安装包
- CMRC、Cloze、gaokao-dataset 原始语料进正式包
- 把 TTS 音频文件打进 APK（一律 ECS）

## 本地对照仓库

开发机可浅克隆到 `tools/vendor_refs/`（已 gitignore），勿提交。
