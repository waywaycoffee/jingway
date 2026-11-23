# 第三方内容归因

## 可商用（正式包）

| 来源 | 协议 | 用途 |
|------|------|------|
| [chinese-xinhua](https://github.com/pwxcoo/chinese-xinhua) | MIT | 汉字/成语释义、听写与点词 |
| [chinese-poetry](https://github.com/chinese-poetry/chinese-poetry) | MIT | 古诗文原文精选（古籍公有领域整理） |
| [chinese-dictionary](https://gitee.com/ridp/chinese-dictionary) | MIT | 多音字、分级、词性、文言补充 |

## 教材目录（按需打开，不打进 APK 正文）

景行仅内置**元数据目录**（书名 / 年级 / 远程路径），用户设备按需下载或外链打开。
**禁止**将部编教材 PDF / OCR 课文全文打进 `apps/mobile/assets`。

| 来源 | 说明 | 用途 |
|------|------|------|
| [TapXWorld/ChinaTextbook](https://github.com/TapXWorld/ChinaTextbook) | 民间整理的 K12 PDF 仓库 | 「电子课本」目录 → 远程 PDF / 本机缓存 |
| [hantang/yuwen](https://github.com/hantang/yuwen)（`docs` 分支） | 业余 OCR 课文原文；版权归原作者/出版社，严禁商用 | 「课文文本」按需拉取 Markdown |
| [zhongyuanqi/dianzi-keben](https://github.com/zhongyuanqi/dianzi-keben) | 国家中小学智慧教育平台电子课本索引 / 网盘链接 | 「智慧教育」外链索引 |
| [basic.smartedu.cn](https://basic.smartedu.cn/) | 教育部智慧教育平台 | 官方电子课本入口 |

版权声明：版权归原出版社 / 教育部；仅供个人学习；景行不内置正文。

刷新目录：`python3 tools/cn_content/build_textbook_manifests.py`

## 仅研究（禁止正式发布）

| 来源 | 协议 | 用途 |
|------|------|------|
| NCR (Native Chinese Reader) | 学术研究许可 | 阅读选择题链路内测 |
| CKnowEdit (ZJUNLP) | 研究 | 填空/文学常识原型 |
| cn-math-taxonomy | CC BY-NC | 知识点打标范式参考 |

景行语文不内置部编教材正文或未授权试卷原文。
