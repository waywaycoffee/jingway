import 'dart:convert';
import 'dart:io';

import 'package:common_learn_english/features/jingway/domain/jingway_excerpt.dart';
import 'package:common_learn_english/features/jingway/domain/jingway_practice.dart';
import 'package:common_learn_english/features/poetry/domain/poetry_cloze.dart';
import 'package:common_learn_english/features/poetry/domain/poetry_comprehension.dart';
import 'package:common_learn_english/features/reading/data/reading_continuous_tts.dart';
import 'package:common_learn_english/features/reading/data/reading_gloss.dart';
import 'package:common_learn_english/features/reading/presentation/reading_text_spans.dart';
import 'package:common_learn_english/features/words/presentation/word_book_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CJK tokenize + speak units', () {
    test('tokenizes Han characters as words', () {
      final List<ReadingToken> tokens = tokenizeReadingText('放学时下起了雨。');
      final List<String> words = tokens
          .where((ReadingToken t) => t.isWord)
          .map((ReadingToken t) => t.raw)
          .toList();
      expect(words, containsAll(<String>['放', '学', '时', '雨']));
      expect(tokens.any((ReadingToken t) => t.raw == '。' && !t.isWord), isTrue);
    });

    test('keeps English tokenization', () {
      final List<ReadingToken> tokens = tokenizeReadingText("Don't give up.");
      expect(tokens.map((ReadingToken t) => t.raw).toList(), <String>[
        "Don't",
        ' ',
        'give',
        ' ',
        'up',
        '.',
      ]);
    });

    test('splitReadingSpeakUnits works for Chinese', () {
      const String text = '放学时下起了雨。小宁把伞挪了挪。';
      final List<ReadingSpeakUnit> units = splitReadingSpeakUnits(text);
      expect(units.length, greaterThanOrEqualTo(2));
      expect(units.first.wordCount, greaterThan(0));
      expect(extractReadingWordTokens(text), isNotEmpty);
    });

    test('normalizeWord keeps CJK', () {
      expect(normalizeWord('雨'), '雨');
      expect(normalizeWord(' 清新 '), '清新');
      expect(normalizeWord('Hello!'), 'hello');
    });
  });

  group('practice packs + skills', () {
    test('g7/g3 packs and doc mapping', () {
      expect(jingwayPracticePackForDoc(jingwayReadingSampleId), jingwayReadingPracticeId);
      expect(jingwayPracticePackForDoc(jingwayG3StoryDocId), jingwayG3StoryPracticeId);
      expect(isJingwayOriginalDoc('other'), isFalse);

      final JingwayPracticePack g7 = jingwayPracticePacks.firstWhere(
        (JingwayPracticePack p) => p.id == jingwayReadingPracticeId,
      );
      expect(g7.questions.every((JingwayPracticeQuestion q) => q.skill != null), isTrue);

      final JingwayPracticePack g3 = jingwayPracticePacks.firstWhere(
        (JingwayPracticePack p) => p.id == jingwayG3StoryPracticeId,
      );
      expect(g3.grade, 3);
      expect(g3.material, isNotNull);
    });

    test('verification items cover reading packs', () {
      expect(jingwayVerificationItems[jingwayReadingPracticeId], isNotEmpty);
      expect(jingwayVerificationItems[jingwayG3StoryPracticeId], isNotEmpty);
      expect(
        jingwayVerificationItems[jingwayReadingPracticeId]!
            .every((JingwayPracticeQuestion q) => q.skill != null),
        isTrue,
      );
    });
  });

  group('poetry cloze + comprehension asset', () {
    test('cloze accepts stripped punctuation', () {
      expect(acceptsPoetryCloze('明月光', '明月，光'), isTrue);
    });

    test('comprehensions_core.json loads and covers poems', () async {
      final String raw = await rootBundle.loadString(
        'assets/jingway/poetry/comprehensions_core.json',
      );
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> items =
          data['comprehensions'] as List<dynamic>? ?? const <dynamic>[];
      expect(items.length, greaterThanOrEqualTo(6));
      final List<PoetryComprehensionItem> parsed = items
          .map(
            (dynamic e) =>
                PoetryComprehensionItem.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      expect(
        comprehensionsForPoem(parsed, 'jingye_si'),
        isNotEmpty,
      );
      expect(
        acceptsComprehensionAnswers(
          expected: const <String>['疑是地上霜'],
          actual: const <String>['疑是地上霜'],
        ),
        isTrue,
      );
    });
  });

  group('excerpt store', () {
    late Box<String> prefs;

    setUp(() async {
      final String path = '${Directory.systemTemp.path}/jw_excerpt_${DateTime.now().microsecondsSinceEpoch}';
      Hive.init(path);
      prefs = await Hive.openBox<String>('prefs');
    });

    tearDown(() async {
      await prefs.clear();
      await prefs.close();
    });

    test('add dedupes by doc+start', () async {
      const String scope = 'guest';
      await const JingwayExcerpt(
        docId: 'jingway-g7-rain-v1',
        title: '雨中的伞',
        start: 10,
        text: '小宁把伞挪了挪',
      ).add(scope);
      await const JingwayExcerpt(
        docId: 'jingway-g7-rain-v1',
        title: '雨中的伞',
        start: 10,
        text: '小宁把伞挪了挪',
      ).add(scope);
      expect(JingwayExcerpt.read(scope).length, 1);
      expect(jingwayWritingScope(signedIn: false, account: ''), 'guest');
      expect(jingwayWritingScope(signedIn: true, account: ''), isNull);
    });
  });
}
