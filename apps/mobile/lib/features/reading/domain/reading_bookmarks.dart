import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../authentication/presentation/account_storage.dart';

class ReadingBookmark {
  const ReadingBookmark({
    required this.id,
    required this.docId,
    required this.offset,
    required this.snippet,
    required this.createdAtMs,
    this.chapterTitle = '',
  });

  final String id;
  final String docId;
  final int offset;
  final String snippet;
  final String chapterTitle;
  final int createdAtMs;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'docId': docId,
        'offset': offset,
        'snippet': snippet,
        'chapterTitle': chapterTitle,
        'createdAtMs': createdAtMs,
      };

  factory ReadingBookmark.fromJson(Map<String, dynamic> json) =>
      ReadingBookmark(
        id: '${json['id'] ?? ''}',
        docId: '${json['docId'] ?? ''}',
        offset: (json['offset'] as num?)?.toInt() ?? 0,
        snippet: '${json['snippet'] ?? ''}',
        chapterTitle: '${json['chapterTitle'] ?? ''}',
        createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
      );
}

const String kReadingBookmarksKey = 'reading_bookmarks_v1';

List<ReadingBookmark> loadReadingBookmarks(String account, String docId) {
  if (!Hive.isBoxOpen('prefs')) return const <ReadingBookmark>[];
  final String? raw =
      Hive.box<String>('prefs').get(studyStorageKey(kReadingBookmarksKey, account));
  if (raw == null || raw.isEmpty) return const <ReadingBookmark>[];
  final Object? decoded = jsonDecode(raw);
  if (decoded is! List) return const <ReadingBookmark>[];
  return decoded
      .whereType<Map>()
      .map(
        (Map e) => ReadingBookmark.fromJson(Map<String, dynamic>.from(e)),
      )
      .where((ReadingBookmark b) => b.docId == docId)
      .toList(growable: false);
}

Future<void> saveReadingBookmarks(
  String account,
  String docId,
  List<ReadingBookmark> forDoc,
) async {
  if (!Hive.isBoxOpen('prefs')) return;
  final String key = studyStorageKey(kReadingBookmarksKey, account);
  final String? raw = Hive.box<String>('prefs').get(key);
  final List<ReadingBookmark> others = <ReadingBookmark>[];
  if (raw != null && raw.isNotEmpty) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is List) {
      for (final Object? item in decoded) {
        if (item is! Map) continue;
        final ReadingBookmark b =
            ReadingBookmark.fromJson(Map<String, dynamic>.from(item));
        if (b.docId != docId) others.add(b);
      }
    }
  }
  final List<ReadingBookmark> all = <ReadingBookmark>[...others, ...forDoc];
  await Hive.box<String>('prefs').put(
    key,
    jsonEncode(all.map((ReadingBookmark b) => b.toJson()).toList()),
  );
}

Future<List<ReadingBookmark>> addReadingBookmark({
  required String account,
  required String docId,
  required int offset,
  required String snippet,
  String chapterTitle = '',
}) async {
  final List<ReadingBookmark> current =
      loadReadingBookmarks(account, docId).toList();
  if (current.any((ReadingBookmark b) => (b.offset - offset).abs() < 8)) {
    return current;
  }
  final ReadingBookmark next = ReadingBookmark(
    id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
    docId: docId,
    offset: offset,
    snippet: snippet.trim().isEmpty ? '书签' : snippet.trim(),
    chapterTitle: chapterTitle,
    createdAtMs: DateTime.now().millisecondsSinceEpoch,
  );
  final List<ReadingBookmark> updated = <ReadingBookmark>[next, ...current];
  await saveReadingBookmarks(account, docId, updated);
  return updated;
}

Future<List<ReadingBookmark>> removeReadingBookmark({
  required String account,
  required String docId,
  required String bookmarkId,
}) async {
  final List<ReadingBookmark> updated = loadReadingBookmarks(account, docId)
      .where((ReadingBookmark b) => b.id != bookmarkId)
      .toList();
  await saveReadingBookmarks(account, docId, updated);
  return updated;
}
