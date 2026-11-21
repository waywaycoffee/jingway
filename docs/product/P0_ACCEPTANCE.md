# 景行语文 P0 验收

## 产品形态

- 独立 App（`com.jingway.chinese`），考试向，按 K12 年级分流。
- 底座 fork 自 AcquireEnglish；英语视频主路径入口已从底栏移除。

## 必过项

1. 首次启动进入年级选择；未选年级不能进入训练闭环。
2. 选七年级后，诗文目录只显示含 `grades: [7]` 的篇目。
3. 古诗文：遮挡 / 上下句 / 默写可用；默写结果逐字着色。
4. 汉字默写单测通过（`cn_dictation_diff_test.dart`）。
5. 正式内容仅 MIT 源；research 数据不进 prod 包。
6. 与 AcquireEnglish（`com.acquire.english`）可并列安装。
