import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class XinhuaEntry {
  const XinhuaEntry({
    required this.term,
    required this.pinyin,
    required this.gloss,
    this.radical = '',
    this.strokes = 0,
    this.kind = 'char',
  });

  final String term;
  final String pinyin;
  final String gloss;
  final String radical;
  final int strokes;

  /// char | idiom | word
  final String kind;
}

final xinhuaDictionaryProvider = Provider<XinhuaDictionary>(
  (Ref ref) => XinhuaDictionary(),
);

/// Offline lookup backed by seed JSON; swap in full chinese-xinhua later.
class XinhuaDictionary {
  Future<Map<String, XinhuaEntry>>? _cache;

  Future<XinhuaEntry?> lookup(String raw) async {
    final String term = raw.trim();
    if (term.isEmpty) return null;
    final Map<String, XinhuaEntry> map = await (_cache ??= _load());
    final XinhuaEntry? exact = map[term];
    if (exact != null) return exact;
    if (term.runes.isEmpty) return null;
    final String first = String.fromCharCode(term.runes.first);
    return map[first];
  }

  Future<Map<String, XinhuaEntry>> _load() async {
    final String raw =
        await rootBundle.loadString('assets/jingway/dict/xinhua_seed.json');
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final Map<String, XinhuaEntry> out = <String, XinhuaEntry>{};

    void addMap(Map<String, dynamic>? src, String kind) {
      if (src == null) return;
      src.forEach((String key, dynamic value) {
        if (value is! Map) return;
        final Map<String, dynamic> m = Map<String, dynamic>.from(value);
        out[key] = XinhuaEntry(
          term: key,
          pinyin: '${m['pinyin'] ?? ''}',
          gloss: '${m['gloss'] ?? ''}',
          radical: '${m['radical'] ?? ''}',
          strokes: (m['strokes'] as num?)?.toInt() ?? 0,
          kind: kind,
        );
      });
    }

    addMap(
      (data['entries'] as Map?)?.cast<String, dynamic>(),
      'char',
    );
    addMap(
      (data['idioms'] as Map?)?.cast<String, dynamic>(),
      'idiom',
    );
    return out;
  }
}
