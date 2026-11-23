import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../flavors/app_flavor.dart';
import '../../shared/data/word_pronunciation_service.dart';
import '../../sync/data/acquire_api_client.dart';

const String kReadingTtsGenderKey = 'reading_tts_gender_v1';

final RegExp _cjkSpeechRe = RegExp(r'[\u4e00-\u9fff]');

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
    ReadingTtsGender.male => 'longchuanshu_v3.6',
    ReadingTtsGender.luna => 'longanxiaoxin',
    ReadingTtsGender.nora => 'longanlingxi',
    ReadingTtsGender.ivy => 'longanhuan_v3.6',
    ReadingTtsGender.alexander => 'longchuanshu_v3.6',
    ReadingTtsGender.james => 'longchuanshu_v3.6',
    ReadingTtsGender.ryan => 'longhuohuo_v3.6',
  };

  static ReadingTtsGender fromStorage(String? raw) => ReadingTtsGender.values
      .firstWhere((v) => v.name == raw, orElse: () => ReadingTtsGender.female);
}

bool readingTextLooksChinese(String text) => _cjkSpeechRe.hasMatch(text);

/// `zh` for Jingway or CJK text; otherwise `en`.
String readingSpeechLanguage(String text) {
  if (FlavorConfig.isJingwayProduct || readingTextLooksChinese(text)) {
    return 'zh';
  }
  return 'en';
}

String readingSpeechVoiceId(ReadingTtsGender gender, String text) {
  return readingSpeechLanguage(text) == 'zh'
      ? gender.jingwayVoiceId
      : gender.aliyunVoiceId;
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

/// Prefer ECS Aliyun cache; for Chinese fall back to on-device TTS if cloud
/// fails (未登录 / 502 / 英音吞中文).
Future<void> speakReadingText(
  WidgetRef ref,
  String text, {
  double? rate,
  ReadingTtsGender? gender,
}) async {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) return;
  final ReadingTtsGender voice = gender ?? loadReadingTtsGender();
  final String language = readingSpeechLanguage(trimmed);
  final String voiceId = readingSpeechVoiceId(voice, trimmed);
  final String ttsLocale = language == 'zh' ? 'zh-CN' : 'en-US';
  try {
    final String url = await ref
        .read(acquireApiClientProvider)
        .readingSpeech(trimmed, voiceId, language: language);
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
