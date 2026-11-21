# 景行语文协作规则

用户已授权：每次完成修改并通过相关验证后，检查手机连接状态。如果存在已授权且在线的 Android 手机，自动构建与手机现有安装相同 applicationId 的 APK，使用覆盖安装保留应用数据，并自动提交、推送本次任务的改动到 GitHub，不重复询问。

- 当前正式包名为 `com.jingway.chinese`，构建使用 `flutter build apk --debug --flavor prod --no-pub`。
- 远程默认 `origin` = `waywaycoffee/jingway`；勿推送到 AcquireEnglish。
- 仅提交当前任务的改动，不提交密钥、缓存或生成文件。
- 多台设备且无法确定目标时再询问；未连接或未授权时说明原因。

## 产品边界

- 独立考试向语文 App；按 K12 年级匹配内容与练习。
- 商用内容：chinese-xinhua / chinese-poetry / chinese-dictionary（MIT）。
- NCR / CKnowEdit 等研究数据禁止进入正式包。

## 音视频只走 ECS

- **禁止**把语音、视频文件打进 App。
- 文本语料可按需下载缓存。详见 `docs/MEDIA_ECS.md`。
