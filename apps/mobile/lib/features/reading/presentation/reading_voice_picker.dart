import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/settings_provider.dart';
import '../../shared/data/aliyun_speech_service.dart';
import '../data/reading_tts.dart';

/// Shows Mandarin-capable Aliyun voices and persists the choice for 诗文/阅读.
Future<String?> showReadingVoicePicker(
  BuildContext context,
  WidgetRef ref, {
  String? currentVoiceId,
}) async {
  final String initial = (currentVoiceId ??
          loadReadingTtsVoiceId() ??
          ref.read(learningSettingsProvider).cloudTtsVoice)
      .trim();
  final String effective = initial.isEmpty
      ? kDefaultJingwaySpeechVoiceId
      : initial;

  final String? picked = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext ctx) {
      return _ReadingVoicePickerSheet(selectedId: effective);
    },
  );
  if (picked == null || picked.isEmpty) return null;

  await saveReadingTtsVoiceId(picked);
  ref.read(learningSettingsProvider.notifier).setCloudTtsVoice(picked);
  JingwaySpeechVoice? meta;
  for (final JingwaySpeechVoice v in kJingwaySpeechVoiceCatalog) {
    if (v.id == picked) {
      meta = v;
      break;
    }
  }
  if (meta != null) {
    await saveReadingTtsGender(
      meta.gender == 'male' ? ReadingTtsGender.male : ReadingTtsGender.female,
    );
  }
  return picked;
}

class _ReadingVoicePickerSheet extends ConsumerStatefulWidget {
  const _ReadingVoicePickerSheet({required this.selectedId});

  final String selectedId;

  @override
  ConsumerState<_ReadingVoicePickerSheet> createState() =>
      _ReadingVoicePickerSheetState();
}

class _ReadingVoicePickerSheetState
    extends ConsumerState<_ReadingVoicePickerSheet> {
  late String _selected;
  List<JingwaySpeechVoice> _voices = kJingwaySpeechVoiceCatalog;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedId;
    unawaited(_loadRemote());
  }

  Future<void> _loadRemote() async {
    try {
      final Map<String, dynamic> data =
          await ref.read(aliyunSpeechServiceProvider).fetchVoices();
      if (!mounted) return;
      final Map<String, String> labels =
          (data['labels'] as Map<String, dynamic>? ?? <String, dynamic>{}).map(
        (String k, dynamic v) => MapEntry<String, String>(k, '$v'),
      );
      final Map<String, String> genders =
          (data['gender'] as Map<String, dynamic>? ?? <String, dynamic>{}).map(
        (String k, dynamic v) => MapEntry<String, String>(k, '$v'),
      );
      final List<String> ids =
          (data['voices'] as List<dynamic>? ?? <dynamic>[])
              .map((dynamic e) => '$e')
              .where((String id) => isJingwaySpeechVoiceId(id))
              .toList(growable: false);
      if (ids.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _voices = <JingwaySpeechVoice>[
          for (final String id in ids)
            JingwaySpeechVoice(
              id: id,
              label: labels[id] ?? jingwaySpeechVoiceLabel(id),
              gender: genders[id] ??
                  (id.contains('fengyue') ||
                          id.contains('xiaoxin') ||
                          id.contains('lingxi') ||
                          id.contains('huan')
                      ? 'female'
                      : 'male'),
            ),
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                '选择朗读音色',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _loading ? '正在同步云端音色…' : '音频缓存在服务器，不打进安装包',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _voices.length,
                itemBuilder: (BuildContext context, int i) {
                  final JingwaySpeechVoice voice = _voices[i];
                  final bool selected = voice.id == _selected;
                  return ListTile(
                    title: Text(voice.label),
                    subtitle: Text(voice.gender == 'female' ? '女声' : '男声'),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    selected: selected,
                    onTap: () => Navigator.pop(context, voice.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
