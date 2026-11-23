# 景行语文 ← AcquireEnglish 能力复用对照

> 以本仓库代码为准（`FlavorConfig`、`app_router`、`AppNavDestination`、`features/jingway/*`）。  
> 英语产品全景见 [`PRODUCT_FEATURES.md`](./PRODUCT_FEATURES.md)；景行验收见 [`P0_ACCEPTANCE.md`](./P0_ACCEPTANCE.md)。  
> 版权 / 教材边界：[`ATTRIBUTION.md`](../ATTRIBUTION.md)；媒体：[`MEDIA_ECS.md`](../MEDIA_ECS.md)。

---

## 1. 复用原则

| 原则 | 说明 |
|------|------|
| 技术底座 vs 产品叙事 | 可复用调度引擎、播放壳、导入管线、账号/路由/设置壳、社区 API；不复用「爱快英语 / CEFR / 背单词 hub」叙事与英语默认文案。 |
| 产品门闸 | `FlavorConfig.isJingwayProduct == true`；`enableMachineTranslation`、`enableAutoSubtitleGeneration` 均为 **false**（见 `apps/mobile/lib/flavors/app_flavor.dart`）。 |
| 路由软阻断 | 英语独占路径进 `/jingway/unavailable`；`/exam/*` 子路径收回 `/exam` 语文专项（`_jingwayEnglishRouteRedirect`）。 |
| 版权 | 正式包仅 MIT：新华 / 诗文 / dictionary；部编正文 **禁止**打进 APK；教材三源仅目录 + 按需打开。 |
| 媒体 | 音视频只走 ECS（`foundation` / `reading` / `oral` / `course` / `misc` / `exam` + `imports/`）；禁止打进 `apps/mobile/assets`。 |
| 研究数据 | NCR / CKnowEdit 等仅 debug / research lab；`ResearchContentGate` 在 release 关闭。 |

**近期产品决策（与代码一致）**

| 决策 | 落地 |
|------|------|
| KEEP | 阅读 `/reading*`、视频库/导入/播放器、成长 `/growth`、社区 `/discover`、AI老师 `/digital-human` |
| GATE OFF | 机翻 UI/管线；ASR「生成字幕」/ 闲时字幕补齐队列 / 双语 pipeline 入口 |
| 语文核心 | 年级档案、诗文默写、字词听写、FSRS 年级过滤复习、新华查字 |
| 教材 | ChinaTextbook / yuwen / dianzi-keben → 目录资产 + 远程/外链；无部编正文资产 |
| 英语 hub | CEFR 考试主路径改为语文专项；短语库 / 单词本 nav / phonics 等零基础 `/learn/*` / 词汇量测评 / 怎么学 阻断 |

---

## 2. 可直接复用（engine / infra）

代码仍在树内且景行可走通或作为无感底座；无需换英语内容即可服务语文产品。

| 能力 | 代码锚点 | 备注 |
|------|----------|------|
| FSRS 记忆调度 | `package:fsrs` + `MemoryItemStore` / `daily_review` | 景行 hub 按 `grade` 过滤卡；错字/默写回流同一引擎 |
| 播放器壳 | `/episodes/:episodeId`，portrait/landscape player | 跟读 / 听写 / 字幕轨播放仍可用；**不**触发自动补字幕 |
| 导入管线（无 MT/ASR 生成） | `/importCourse`，`import_course_flow` | 导入本地/外链视频 + **已有字幕**；`enableAutoSubtitleGeneration` 时跳过补齐入队 |
| 视频库壳 | `/library` | 设置 / 首页可进；文案强调「已有字幕」 |
| 路由 / 导航壳 | `GoRouter`、`PadScaffold`、底栏 / More | 底栏：备考 / 诗文 / 复习 / 专项 / 我的 |
| 账号登录 | 微信 / 手机 / 邮箱、JWT、`authSession` | 设置「账号」组复用；同步进度 |
| 设置壳（景行裁剪） | `_buildJingwaySettings` | 年级、功能入口、会员、API、主题、更新、清缓存；**不**暴露 AE 翻译/Whisper/AI 字幕管理面板 |
| 会员 / 支付壳 | `/membership` | UI 仍挂在景行设置 |
| 成长壳 | `/growth` | KEEP；叙事可后换「语文掌握度」 |
| 社区后端 | `/api/community/*`、`exam` 媒体命名空间 | 真题资料上传/下载仍走 ECS |
| 媒体 manifest / 上传 | `/api/content/media/*`、`/media/{ns}/…` | 与 AE 同架构；换运营内容即可 |
| TTS / 朗读缓存（能力层） | reading speech、oral_coach `tts/cache` | 景行设置未暴露引擎面板；阅读/陪练路径仍可调用服务端缓存 |
| 共享 OCR 书库（能力层） | `/api/shared-ocr-books` + 阅读扫描 PDF | 扫描导入仍可走云/本机 OCR；与「字幕生成」门闸无关 |
| 硬字幕 OCR / Whisper（代码在树） | `bilingual_subtitle_pipeline`、`LocalWhisperAsr` | **产品关闭**：随 `enableAutoSubtitleGeneration` 不入队、不展示生成入口；勿当景行卖点 |

---

## 3. 需换皮 / 换内容后复用

入口 **KEEP** 或骨架可用，但默认数据、文案或题包仍偏英语，需换成语文内容与年级叙事。

| 模块 | 现状（代码） | 换什么 |
|------|--------------|--------|
| 阅读 | `/reading` 可读；句译开关受 `enableMachineTranslation` 隐藏 | 在线书库仍挂 OneStop / CEFR / Magic / Standard Ebooks；需换语文读物源或只推本地导入 + 教材文本 |
| 视频导入 / 库 / 播放 | 路由开放；补字幕 / 机翻关 | 运营侧换成语文讲解课；播放器 Tab 文案与「练习/背单词」英语语义需收敛 |
| 成长 | `/growth` 可进 | 等级/打卡可保留；称号与「英语习得」文案换景行 |
| 社区真题 | `/discover` KEEP | 考试族/素材仍可偏英语注册表；需语文真题分类与审核策略 |
| AI老师 | `/digital-human` KEEP | 场景/提示词/音色改语文陪练；拍照识词可接新华 |
| 错题本 / 考试会话骨架 | `ExamErrorBookScreen`、`ExamSessionScreen` 等仍在路由树 | 景行 `/exam` 已接入七年级原创试练；旧子路径仍重定向。考试会话与错题壳保留为后续复用候选 |
| 词书 / syllabus | `/words/syllabus*` **未**进 exact block（首页「字词听写」跳此） | 用 `cn_g*_dictation` 等语文词书；勿引导英语云词书主路径 |
| 影子跟读 / 句听写 | 播放器内 | 评测与回流 FSRS 可留；提示与评分文案改中文课语境 |
| Pad 设计 Token / 主题 | `AppDesignTokens` + `JingwayColors` 并存 | 统一景行视觉，减少英语休息室残留文案 |

---

## 4. 景行关闭或慎用

| 能力 | 门闸 / 路由 | 说明 |
|------|-------------|------|
| 机器翻译（MT） | `enableMachineTranslation == false` | 阅读句译、字幕中英管线、查词 MT 分支关闭 |
| 自动字幕生成 / ASR 补齐 | `enableAutoSubtitleGeneration == false` | 闲时队列、播放器「生成字幕」、双语 pipeline 入口关闭；已有字幕仍可播 |
| 硬字幕 OCR 自动跑 | 同上 | 与补字幕同一产品门；勿单独打开当默认能力 |
| 短语库 | `availableInJingway: false` + `/phrases` → unavailable | 英语表达库 |
| 单词本（字幕收藏词） | nav 关 + `/words` exact block | 勿与 `/words/syllabus` 语文听写混淆 |
| 怎么学（三遍精听） | `/guide` block | 英语精听方法论 |
| 零基础模块 | `/learn/*` block | IPA / phonics / chunks / listening / dialogue |
| 真人口语匹配 | `/peer-oral` block | LiveKit 对练英语路径 |
| 词汇量测评 | `/vocabularyPlacement` block | |
| SM2 / learning 复习旁路 | `/review/sm2`、`/review/learning` block | 景行走 `/review` + `/review/session` |
| 英语写作 | `/writing*` block | |
| 公开学习卡 | `/shared/*` block | |
| 旧英语首页 | `/home/legacy` block | 现 `/home` = `JingwayExamHomeScreen` |
| CEFR 考试 hub | `/exam` → `JingwayExamScreen`；子路径收口 | 官方薄题包 / 模考英语路径不做主入口 |
| AE 设置：翻译引擎 / Whisper / AI 字幕管理 | 景行设置不渲染该大段 UI | 代码仍在同一文件，仅 flavor 分支 |

---

## 5. 景行自建 / 不复用 AE 内容

| 能力 | 位置 | 说明 |
|------|------|------|
| K12 年级档案 | `jingway_profile`、`cn_grade_registry`、`/onboarding`、`/settings/grade` | 首启必选年级；过滤诗文与复习卡 |
| 古诗文默写 | `/poetry`、`/poetry/:unitId`，`assets/jingway/poetry/exam_core.json` | 遮挡 / 上下句 / 逐字 diff；MIT chinese-poetry |
| 新华查字 | `xinhua_dictionary`、首页查字框、`xinhua_lookup_sheet` | 离线 seed；MIT chinese-xinhua |
| 字词听写词书 | `assets/syllabus/cn_g*_dictation.json` 等 | 年级生字/成语；非 AE 英语词书 |
| 教材三源目录 | `/textbooks`，`assets/jingway/textbooks/*.json` | ChinaTextbook PDF 远程、yuwen MD 按需、dianzi-keben 外链；**无正文入包** |
| 备考首页 / 复习 hub / 专项 / unavailable | `features/jingway/presentation/*` | 替换 AE 学习首页与背单词 hub |
| 年级标签键 | `grade_tags.dart`（`jingwayCharReviewKey` 等） | 错字卡与年级绑定 |
| 包名与品牌 | `com.jingway.chinese`，`FlavorConfig.appName` | 与 `com.acquire.english` 可并列安装 |

---

## 6. 建议下一步产品优先级

1. **巩固语文闭环**：年级 ↔ 诗文默写 ↔ 听写词书 ↔ FSRS 今日复习（P0 已验收项保持绿灯）。  
2. **阅读换源**：弱化英语在线书库入口，优先本地导入 + 教材 yuwen 按需文本；朗读走 ECS `reading`。  
3. **视频保持「有字幕可学」**：导入/库/播放器只承诺已有字幕；不做 MT/ASR 生成承诺。  
4. **社区真题语文化**：分类、审核与 `exam` 命名空间素材规范；同桌 PK 词源改字词/诗文。  
5. **AI老师提示词与识词**：默认场景改语文；识词接新华；示范音仍 ECS `oral`。  
6. **专项题包**：扩充七年级现代文试练与文言客观题，逐步接上统一错题本和 FSRS。
7. **设置与侧栏文案清扫**：去掉残留英语休息室 / 背单词叙事；TTS 若要对用户开放，单独做景行面板而非打开 AE 全套 ASR。

---

## 附录：景行主导航速查

| 入口 | 路径 | 状态 |
|------|------|------|
| 备考主页 | `/home` | 景行自建 |
| 诗文 | `/poetry` | 景行自建 |
| 复习 | `/review` → session | 换皮 FSRS |
| 专项 | `/exam` | 七年级原创试练 |
| 我的 | `/settings` | 裁剪壳 |
| 阅读 / 教材 / 视频 / 导入 / 成长 / 社区 / AI老师 | 见上 KEEP | 换皮或自建目录 |

门闸源文件：`apps/mobile/lib/flavors/app_flavor.dart`、`apps/mobile/lib/router/app_router.dart`、`apps/mobile/lib/features/navigation/presentation/navigation_destination.dart`。

---

*维护：改 Flavor / 路由阻断 / 景行首页卡片时同步更新本表；勿把规划中的题包写成已上线。*
