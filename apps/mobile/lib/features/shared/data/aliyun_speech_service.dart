import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../flavors/app_flavor.dart';
import '../../authentication/presentation/auth_session.dart';
import '../../reading/data/reading_tts.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../sync/data/acquire_api_client.dart';

/// Default Aliyun Qwen voice. Jingway prefers Mandarin-capable 龙安风悦.
const String kDefaultAliyunTtsVoiceEn =
    'qwen-audio-3.0-tts-flash-loongolivialin';

String get kDefaultAliyunTtsVoice => FlavorConfig.isJingwayProduct
    ? kDefaultJingwaySpeechVoiceId
    : kDefaultAliyunTtsVoiceEn;

final Provider<AliyunSpeechService> aliyunSpeechServiceProvider =
    Provider<AliyunSpeechService>((Ref ref) {
      return AliyunSpeechService(
        api: ref.watch(acquireApiClientProvider),
        isLoggedIn: ref.watch(authSessionProvider).isLoggedIn,
        voice: ref.watch(
          learningSettingsProvider.select(
            (LearningSettingsState s) => s.cloudTtsVoice,
          ),
        ),
      );
    });

/// Resolves Aliyun TTS audio URLs (cached on ECS `/media/reading/speech`).
class AliyunSpeechService {
  AliyunSpeechService({
    required this.api,
    required this.isLoggedIn,
    required this.voice,
  });

  final AcquireApiClient api;
  final bool isLoggedIn;
  final String voice;

  String get resolvedVoice {
    final String trimmed = voice.trim();
    return trimmed.isEmpty ? kDefaultAliyunTtsVoice : trimmed;
  }

  bool get isAvailable => isLoggedIn;

  Future<String?> resolveAudioUrl(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty || !isAvailable) return null;
    try {
      final bool chinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(trimmed);
      final String voice = chinese && !isJingwaySpeechVoiceId(resolvedVoice)
          ? kDefaultJingwaySpeechVoiceId
          : resolvedVoice;
      return await api.readingSpeech(
        trimmed,
        voice,
        language: chinese ? 'zh' : 'en',
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchVoices() => api.readingVoices();
}
