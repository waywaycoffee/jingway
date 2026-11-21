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

## 闭环走查（手工 / 真机）

| # | 步骤 | 期望 |
|---|------|------|
| A | 冷启动 | 进入 `JingwayGradeOnboardingScreen` |
| B | 选七年级 → 开始学习 | 进入备考首页，展示「七年级」 |
| C | 古诗文目录 | 仅 `grades` 含 7 的篇目 |
| D | 打开一篇 → 默写 | 逐字 diff；错字可进复习 |
| E | 字词听写 / 词书 | 年级词书可用 |
| F | 新华点词 | 离线 seed 可查 |
| G | 今日复习 | 默认只含当前年级卡 |
| H | 设置改年级为三年级 | 诗文/推荐切换；七年级卡不进默认会话 |
| I | release / prod 包 | 无 `data/research` assets；无内测实验室入口 |

## 许可证与归因

- [x] `docs/ATTRIBUTION.md` 列出 xinhua / poetry / dictionary（MIT）
- [x] NCR / CKnowEdit 标为仅研究，见 `docs/RESEARCH_CONTENT.md`
- [x] `pubspec.yaml` 不含 research 路径（单测守卫）
- [x] `ResearchContentGate`：release 恒关闭

## 自动化核对（本机）

```bash
# 不依赖 native assets / 真机
./tools/cn_content/verify_p0_accept.sh

cd apps/mobile
dart analyze lib/features/jingway/ lib/features/player/domain/cn_dictation_diff.dart
flutter test test/features/player/cn_dictation_diff_test.dart \
  test/features/jingway/research_content_gate_test.dart \
  test/features/jingway/research_content_repository_test.dart
```

说明：`flutter test` 若因 `livekit_ffi` 从 GitHub 拉原生库超时而失败，以 `verify_p0_accept.sh` + `dart analyze`（无 error）为准；修好网络后重跑单测。

## 真机安装

```bash
# 需已授权 Android 设备
adb devices
flutter build apk --debug --flavor prod --no-pub
adb install -r build/app/outputs/flutter-apk/app-prod-debug.apk
```

包名：`com.jingway.chinese`（覆盖安装保留数据）。

### 本机执行记录

| 项 | 结果 |
|----|------|
| `verify_p0_accept.sh` | 通过 |
| `dart analyze`（jingway + cn_dictation_diff） | 无 error |
| ATTRIBUTION / research 隔离 | 通过 |
| `adb devices` | 无已授权设备 → 真机覆盖安装待插机后执行 |
