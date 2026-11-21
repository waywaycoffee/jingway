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

/// Offline lookup: seed JSON built from chinese-xinhua (+ poetry chars).
///
/// Vendor raw dumps stay under `vendor/` (gitignored); the committed seed is the
/// runtime source so prod never depends on cloning research/vendor trees.
class XinhuaDictionary {
  Future<Map<String, XinhuaEntry>>? _cache;

  Future<XinhuaEntry?> lookup(String raw) async {
    final String term = raw.trim();
    if (term.isEmpty) return null;
    final Map<String, XinhuaEntry> map = await (_cache ??= _load());

    final XinhuaEntry? exact = map[term];
    if (exact != null) return exact;

    // Prefer longest matching idiom/word prefix, then fall back to first char.
    XinhuaEntry? best;
    for (int end = term.length; end >= 2; end--) {
      final XinhuaEntry? hit = map[term.substring(0, end)];
      if (hit != null && (hit.kind == 'idiom' || hit.kind == 'word')) {
        best = hit;
        break;
      }
    }
    if (best != null) return best;

    if (term.runes.isEmpty) return null;
    final String first = String.fromCharCode(term.runes.first);
    return map[first];
  }

  /// Prefix / contains search for dictionary UI (capped).
  Future<List<XinhuaEntry>> suggest(String raw, {int limit = 20}) async {
    final String q = raw.trim();
    if (q.isEmpty) return const <XinhuaEntry>[];
    final Map<String, XinhuaEntry> map = await (_cache ??= _load());
    final List<XinhuaEntry> prefix = <XinhuaEntry>[];
    final List<XinhuaEntry> contains = <XinhuaEntry>[];
    for (final XinhuaEntry e in map.values) {
      if (e.term == q) {
        prefix.insert(0, e);
        continue;
      }
      if (e.term.startsWith(q)) {
        prefix.add(e);
      } else if (e.term.contains(q) || e.gloss.contains(q)) {
        contains.add(e);
      }
      if (prefix.length >= limit) break;
    }
    final List<XinhuaEntry> out = <XinhuaEntry>[
      ...prefix,
      ...contains.take(limit - prefix.length),
    ];
    return out.take(limit).toList(growable: false);
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
      (data['words'] as Map?)?.cast<String, dynamic>(),
      'word',
    );
    addMap(
      (data['idioms'] as Map?)?.cast<String, dynamic>(),
      'idiom',
    );
    return out;
  }
}
