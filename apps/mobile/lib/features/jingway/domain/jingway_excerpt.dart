import 'dart:convert';

import 'package:hive_ce/hive.dart';

class JingwayExcerpt {
  const JingwayExcerpt({
    required this.docId,
    required this.title,
    required this.start,
    required this.text,
  });

  final String docId;
  final String title;
  final int start;
  final String text;

  static List<JingwayExcerpt> read(String scope) {
    final String? raw = Hive.box<String>(
      'prefs',
    ).get('jingway_excerpts_v1:$scope');
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).map((dynamic value) {
      final Map<String, dynamic> item = value as Map<String, dynamic>;
      return JingwayExcerpt(
        docId: item['docId'] as String,
        title: item['title'] as String,
        start: item['start'] as int,
        text: item['text'] as String,
      );
    }).toList();
  }

  static Future<void> save(String scope, List<JingwayExcerpt> excerpts) =>
      Hive.box<String>('prefs').put(
        'jingway_excerpts_v1:$scope',
        jsonEncode([
          for (final JingwayExcerpt excerpt in excerpts)
            {
              'docId': excerpt.docId,
              'title': excerpt.title,
              'start': excerpt.start,
              'text': excerpt.text,
            },
        ]),
      );

  Future<void> add(String scope) {
    final List<JingwayExcerpt> excerpts = read(scope);
    if (excerpts.any(
      (JingwayExcerpt item) => item.docId == docId && item.start == start,
    )) {
      return Future<void>.value();
    }
    return save(scope, [this, ...excerpts]);
  }
}

String? jingwayWritingScope({
  required bool signedIn,
  required String account,
}) => signedIn
    ? (account.trim().isEmpty ? null : 'user:${account.trim()}')
    : 'guest';
