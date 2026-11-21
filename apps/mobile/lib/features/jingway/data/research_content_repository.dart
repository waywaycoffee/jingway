import 'dart:convert';
import 'dart:io';

import '../domain/research_content_gate.dart';
import '../domain/research_models.dart';

/// Loads research corpora only when [ResearchContentGate.isEnabled].
///
/// Prod must never register these paths under Flutter assets. Prefer local
/// files under [ResearchContentPaths] or in-memory JSON for tests.
class ResearchContentRepository {
  ResearchContentRepository({
    this.gate = kResearchContentGate,
    this.rootOverride,
  });

  final ResearchContentGate gate;

  /// Optional absolute/relative root for tests.
  final String? rootOverride;

  String get _root => rootOverride ?? ResearchContentPaths.root;

  void _ensureEnabled() {
    if (!gate.isEnabled) {
      throw StateError(
        'Research content is disabled. '
        'Enable ResearchContentGate only in debug/internal builds.',
      );
    }
  }

  List<NcrReadingItem> parseNcrBundle(String rawJson) {
    _ensureEnabled();
    final Object? decoded = jsonDecode(rawJson);
    final List<dynamic> items;
    if (decoded is Map<String, dynamic>) {
      items = decoded['items'] as List<dynamic>? ?? const <dynamic>[];
    } else if (decoded is List<dynamic>) {
      items = decoded;
    } else {
      items = const <dynamic>[];
    }
    return items
        .map(
          (dynamic e) => NcrReadingItem.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  List<CknowEditClozeItem> parseCknowEditBundle(String rawJson) {
    _ensureEnabled();
    final Object? decoded = jsonDecode(rawJson);
    final List<dynamic> items;
    if (decoded is Map<String, dynamic>) {
      items = decoded['items'] as List<dynamic>? ?? const <dynamic>[];
    } else if (decoded is List<dynamic>) {
      items = decoded;
    } else {
      items = const <dynamic>[];
    }
    return items
        .map(
          (dynamic e) =>
              CknowEditClozeItem.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<List<NcrReadingItem>> loadNcrFromDisk({
    String fileName = 'items.json',
  }) async {
    _ensureEnabled();
    final File file = File('$_root/ncr/$fileName');
    if (!await file.exists()) {
      return const <NcrReadingItem>[];
    }
    return parseNcrBundle(await file.readAsString());
  }

  Future<List<CknowEditClozeItem>> loadCknowEditFromDisk({
    String fileName = 'items.json',
  }) async {
    _ensureEnabled();
    final File file = File('$_root/cknow_edit/$fileName');
    if (!await file.exists()) {
      return const <CknowEditClozeItem>[];
    }
    return parseCknowEditBundle(await file.readAsString());
  }

  /// Tiny synthetic samples for schema / UI validation — not NCR/CKnowEdit text.
  static const String syntheticNcrJson = '''
{
  "items": [
    {
      "id": "synth_ncr_g7_01",
      "grades": [7],
      "passage": "春日课间，同学在走廊轻声朗读古诗，铃声响后迅速回到座位。",
      "question": "文中同学朗读的主要目的最可能是？",
      "options": ["消磨时间", "准备默写检查", "躲避值日", "练习英文"],
      "answerIndex": 1,
      "errorCategory": "inference",
      "methodCard": "抓「铃声响后回到座位」与「朗读古诗」的情境，推断备考默写。"
    }
  ]
}
''';

  static const String syntheticCknowJson = '''
{
  "items": [
    {
      "id": "synth_ck_g7_01",
      "grades": [7],
      "prompt": "床前明月光，疑是____霜。",
      "answer": "地上",
      "genre": "poetry_cloze"
    },
    {
      "id": "synth_ck_g7_02",
      "grades": [7],
      "prompt": "《静夜思》作者是____。",
      "answer": "李白",
      "genre": "literary_knowledge"
    }
  ]
}
''';
}
