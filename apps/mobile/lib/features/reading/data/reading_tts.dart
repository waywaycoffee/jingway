import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../flavors/app_flavor.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../shared/data/word_pronunciation_service.dart';
import '../../sync/data/acquire_api_client.dart';

const String kReadingTtsGenderKey = 'reading_tts_gender_v1';
const String kReadingTtsVoiceIdKey = 'reading_tts_voice_id_v1';

final RegExp _cjkSpeechRe = RegExp(r'[\u4e00-\u9fff]');

/// Offline catalog for 景行中文朗读（与生产 `/api/reading/voices` 对齐）。
class JingwaySpeechVoice {
  const JingwaySpeechVoice({
    required this.id,
    required this.label,
    required this.gender,
  });

  final String id;
  final String label;
  final String gender; // female | male
}

const List<JingwaySpeechVoice> kJingwaySpeechVoiceCatalog =
    <JingwaySpeechVoice>[
  JingwaySpeechVoice(
    id: 'longanfengyue',
    label: '龙安风悦 · 温暖女声（推荐）',
    gender: 'female',
  ),
  JingwaySpeechVoice(
    id: 'libai_v3.1',
    label: '李白 · 文气旁白',
    gender: 'male',
  ),
  JingwaySpeechVoice(
    id: 'longshu_v3.1',
    label: '龙书 · 朗读书卷',
    gender: 'male',
  ),
  JingwaySpeechVoice(
    id: 'longze_v3.1',
    label: '龙泽 · 磁性男声（推荐）',
    gender: 'male',
  ),
  JingwaySpeechVoice(
    id: 'longxiaocheng_v3.1',
    label: '龙小诚 · 沉稳男声',
    gender: 'male',
  ),
  JingwaySpeechVoice(
    id: 'longanhuan_v3.6',
    label: '龙安欢 · 元气女声',
    gender: 'female',
  ),
  JingwaySpeechVoice(
    id: 'longanxiaoxin',
    label: '龙安小昕 · 亲切活泼',
    gender: 'female',
  ),
  JingwaySpeechVoice(
    id: 'longanlingxi',
    label: '龙安灵希 · 甜美轻快',
    gender: 'female',
  ),
  JingwaySpeechVoice(
    id: 'longanyang_v3.1',
    label: '龙安洋 · 中英双语',
    gender: 'male',
  ),
  JingwaySpeechVoice(
    id: 'longsanshu_v3.1',
    label: '龙三叔 · 中英双语',
    gender: 'male',
  ),
  JingwaySpeechVoice(
    id: 'longanlufeng',
    label: '龙安鲁风 · 中英双语',
    gender: 'male',
  ),
  JingwaySpeechVoice(
    id: 'longchuanshu_v3.6',
    label: '龙川叔 · 沉稳大叔',
    gender: 'male',
  ),
];

const String kDefaultJingwaySpeechVoiceId = 'longanfengyue';

/// Reading uses Alibaba CosyVoice via ECS `/api/reading/speech`.
enum ReadingTtsGender { female, male, luna, nora, ivy, alexander, james, ryan }

extension ReadingTtsGenderX on ReadingTtsGender {
  String get storageValue => name;

  String get labelCn => switch (this) {
    ReadingTtsGender.female => 'Olivia Lin',
    ReadingTtsGender.male => 'Adrian Gao',
    ReadingTtsGender.luna => 'Luna Wang',
    ReadingTtsGender.nora => 'Nora Hu',
    ReadingTtsGender.ivy => 'Ivy Hu',
    ReadingTtsGender.alexander => 'Alexander Hu',
    ReadingTtsGender.james => 'James Zhao',
    ReadingTtsGender.ryan => 'Ryan Ma',
  };

  /// DashScope CosyVoice id (English-native).
  String get aliyunVoiceId => switch (this) {
    ReadingTtsGender.female => 'qwen-audio-3.0-tts-flash-loongolivialin',
    ReadingTtsGender.male => 'qwen-audio-3.0-tts-flash-loongadriangao',
    ReadingTtsGender.luna => 'qwen-audio-3.0-tts-flash-loonglunawang',
    ReadingTtsGender.nora => 'qwen-audio-3.0-tts-flash-loongnorahu',
    ReadingTtsGender.ivy => 'qwen-audio-3.0-tts-flash-loongivyhu',
    ReadingTtsGender.alexander => 'qwen-audio-3.0-tts-flash-loongalexanderhu',
    ReadingTtsGender.james => 'qwen-audio-3.0-tts-flash-loongjameszhao',
    ReadingTtsGender.ryan => 'qwen-audio-3.0-tts-flash-loongryanma',
  };

  /// Mandarin-capable bilingual CosyVoice ids (景行诗文 / 中文阅读).
  String get jingwayVoiceId => switch (this) {
    ReadingTtsGender.female => 'longanfengyue',
    ReadingTtsGender.male => 'longze_v3.1',
    ReadingTtsGender.luna => 'longanxiaoxin',
    ReadingTtsGender.nora => 'longanlingxi',
    ReadingTtsGender.ivy => 'longanhuan_v3.6',
    ReadingTtsGender.alexander => 'longxiaocheng_v3.1',
    ReadingTtsGender.james => 'longshu_v3.1',
    ReadingTtsGender.ryan => 'longchuanshu_v3.6',
  };

  static ReadingTtsGender fromStorage(String? raw) => ReadingTtsGender.values
      .firstWhere((v) => v.name == raw, orElse: () => ReadingTtsGender.female);
}

bool readingTextLooksChinese(String text) => _cjkSpeechRe.hasMatch(text);

bool isJingwaySpeechVoiceId(String id) {
  final String trimmed = id.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed.startsWith('long') || trimmed.startsWith('libai')) return true;
  return kJingwaySpeechVoiceCatalog.any(
    (JingwaySpeechVoice v) => v.id == trimmed,
  );
}

String jingwaySpeechVoiceLabel(String id) {
  for (final JingwaySpeechVoice v in kJingwaySpeechVoiceCatalog) {
    if (v.id == id) return v.label;
  }
  return id;
}

/// `zh` for Jingway or CJK text; otherwise `en`.
String readingSpeechLanguage(String text) {
  if (FlavorConfig.isJingwayProduct || readingTextLooksChinese(text)) {
    return 'zh';
  }
  return 'en';
}

String? loadReadingTtsVoiceId() {
  if (!Hive.isBoxOpen('prefs')) return null;
  final String? raw =
      Hive.box<String>('prefs').get(kReadingTtsVoiceIdKey)?.trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

Future<void> saveReadingTtsVoiceId(String voiceId) async {
  if (!Hive.isBoxOpen('prefs')) return;
  await Hive.box<String>('prefs').put(kReadingTtsVoiceIdKey, voiceId.trim());
}

ReadingTtsGender loadReadingTtsGender() {
  if (!Hive.isBoxOpen('prefs')) return ReadingTtsGender.female;
  return ReadingTtsGenderX.fromStorage(
    Hive.box<String>('prefs').get(kReadingTtsGenderKey),
  );
}

Future<void> saveReadingTtsGender(ReadingTtsGender gender) async {
  if (!Hive.isBoxOpen('prefs')) return;
  await Hive.box<String>(
    'prefs',
  ).put(kReadingTtsGenderKey, gender.storageValue);
}

/// Resolve Aliyun voice id for [text], honoring an explicit selection.
String readingSpeechVoiceId(
  ReadingTtsGender gender,
  String text, {
  String? voiceId,
  String? settingsVoice,
}) {
  final String language = readingSpeechLanguage(text);
  final String explicit = (voiceId ?? '').trim();
  if (explicit.isNotEmpty) return explicit;

  final String stored = (loadReadingTtsVoiceId() ?? '').trim();
  if (stored.isNotEmpty) {
    if (language == 'zh' || isJingwaySpeechVoiceId(stored)) return stored;
    if (language == 'en' && !isJingwaySpeechVoiceId(stored)) return stored;
  }

  final String fromSettings = (settingsVoice ?? '').trim();
  if (fromSettings.isNotEmpty) {
    if (language == 'zh') {
      return isJingwaySpeechVoiceId(fromSettings)
          ? fromSettings
          : gender.jingwayVoiceId;
    }
    return fromSettings;
  }

  return language == 'zh' ? gender.jingwayVoiceId : gender.aliyunVoiceId;
}

/// Prefer ECS Aliyun cache; for Chinese fall back to on-device TTS if cloud
/// fails (未登录 / 502 / 英音吞中文).
Future<void> speakReadingText(
  WidgetRef ref,
  String text, {
  double? rate,
  ReadingTtsGender? gender,
  String? voiceId,
}) async {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) return;
  final ReadingTtsGender voice = gender ?? loadReadingTtsGender();
  final String language = readingSpeechLanguage(trimmed);
  final String settingsVoice =
      ref.read(learningSettingsProvider).cloudTtsVoice;
  final String resolvedVoiceId = readingSpeechVoiceId(
    voice,
    trimmed,
    voiceId: voiceId,
    settingsVoice: settingsVoice,
  );
  final String ttsLocale = language == 'zh' ? 'zh-CN' : 'en-US';
  try {
    final String url = await ref
        .read(acquireApiClientProvider)
        .readingSpeech(trimmed, resolvedVoiceId, language: language);
    await ref
        .read(wordPronunciationServiceProvider)
        .speak(
          trimmed,
          recordedUrl: url,
          rate: rate,
          language: ttsLocale,
          allowSynthesisFallback: false,
        );
  } catch (_) {
    if (language != 'zh') rethrow;
    await ref
        .read(wordPronunciationServiceProvider)
        .speak(
          trimmed,
          rate: rate,
          language: ttsLocale,
          allowSynthesisFallback: true,
        );
  }
}
