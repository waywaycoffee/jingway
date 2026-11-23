import 'dart:io';

import 'package:common_learn_english/features/reading/domain/reading_bookmarks.dart';
import 'package:common_learn_english/features/reading/domain/reading_chapters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('detectReadingChapters', () {
    test('splits on 第N章 headings', () {
      const String text = '序\n\n第一章 开端\n很久以前。\n\n第二章 发展\n后来。\n';
      final List<ReadingChapter> chapters = detectReadingChapters(text);
      expect(chapters.length, greaterThanOrEqualTo(2));
      expect(chapters.any((ReadingChapter c) => c.title.contains('开端')), isTrue);
      expect(chapters.any((ReadingChapter c) => c.title.contains('发展')), isTrue);
    });

    test('splits on EPUB ＃＃＃ markers', () {
      const String text = '＃＃＃ 楔子\n从前有座山。\n\n＃＃＃ 正文\n山里有座庙。\n';
      final List<ReadingChapter> chapters = detectReadingChapters(text);
      expect(chapters.length, 2);
      expect(chapters.first.title, '楔子');
      expect(chapters.last.body, contains('庙'));
      expect(chapters.last.bodyStart, greaterThan(chapters.last.start));
    });

    test('falls back to single chapter', () {
      const String text = '这是一篇没有标题的短文。';
      final List<ReadingChapter> chapters = detectReadingChapters(text);
      expect(chapters.length, 1);
      expect(chapters.first.title, '全文');
    });

    test('search finds hits across chapters', () {
      const String text = '＃＃＃ 一\n苹果很好吃。\n＃＃＃ 二\n香蕉也好吃。\n';
      final List<ReadingChapter> chapters = detectReadingChapters(text);
      final List<ReadingSearchHit> hits = searchReadingText(
        plainText: text,
        query: '好吃',
        chapters: chapters,
      );
      expect(hits.length, 2);
      expect(hits.first.chapterIndex, 0);
      expect(hits.last.chapterIndex, 1);
    });

    test('global percent grows with chapter index', () {
      final String text =
          '＃＃＃ A\n${'啊' * 100}\n＃＃＃ B\n${'吧' * 100}\n';
      final List<ReadingChapter> chapters = detectReadingChapters(text);
      final double early = readingGlobalPercent(
        chapters: chapters,
        chapterIndex: 0,
        localPercent: 0,
      );
      final double late = readingGlobalPercent(
        chapters: chapters,
        chapterIndex: 1,
        localPercent: 1,
      );
      expect(late, greaterThan(early));
    });
  });

  group('bookmarks store', () {
    late Box<String> prefs;

    setUp(() async {
      final String path =
          '${Directory.systemTemp.path}/jw_bm_${DateTime.now().microsecondsSinceEpoch}';
      Hive.init(path);
      prefs = await Hive.openBox<String>('prefs');
    });

    tearDown(() async {
      await prefs.clear();
      await prefs.close();
    });

    test('add and remove', () async {
      final List<ReadingBookmark> added = await addReadingBookmark(
        account: 'guest',
        docId: 'novel-1',
        offset: 120,
        snippet: '从前有座山',
        chapterTitle: '楔子',
      );
      expect(added.length, 1);
      expect(loadReadingBookmarks('guest', 'novel-1').length, 1);
      final List<ReadingBookmark> removed = await removeReadingBookmark(
        account: 'guest',
        docId: 'novel-1',
        bookmarkId: added.first.id,
      );
      expect(removed, isEmpty);
    });
  });
}
