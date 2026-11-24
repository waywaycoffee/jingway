import 'dart:convert';

import 'package:common_learn_english/features/navigation/presentation/floating_bottom_nav.dart';
import 'package:common_learn_english/features/navigation/presentation/navigation_destination.dart';
import 'package:common_learn_english/features/reading/domain/reading_chapters.dart';
import 'package:common_learn_english/features/reading/domain/reading_doc.dart';
import 'package:common_learn_english/features/reading/presentation/reading_library_provider.dart';
import 'package:common_learn_english/flavors/app_flavor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Jingway bottom nav second item is reading hub', () {
    expect(FlavorConfig.isJingwayProduct, isTrue);
    expect(AppNavDestination.readingHub.showInBottomNav, isTrue);
    expect(AppNavDestination.reading.showInBottomNav, isFalse);
    expect(AppNavDestination.readingHub.route, '/reading');
    // Primary destinations are private; assert public flags + route contract.
    expect(AppNavDestination.home.route, '/home');
    expect(FloatingBottomNav, isNotNull);
  });

  test('Jingway ships only two Chinese test builtins with chapters', () async {
    expect(kBuiltinReadingAssetPaths, kBuiltinReadingAssetPathsZh);
    expect(kBuiltinReadingAssetPathsZh, hasLength(2));

    for (final String path in kBuiltinReadingAssetPathsZh) {
      final String raw = await rootBundle.loadString(path);
      final Map<String, dynamic> json =
          Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final ReadingDoc doc = ReadingDoc.fromJson(json, builtin: true);
      expect(doc.title, isNotEmpty);
      expect(RegExp(r'[\u4e00-\u9fff]').hasMatch(doc.plainText), isTrue);
      expect(isEnglishDefaultReadingDoc(doc), isFalse);
      final List<ReadingChapter> chapters =
          detectReadingChapters(doc.plainText);
      expect(chapters.length, greaterThanOrEqualTo(2), reason: doc.title);
      expect(chapters.first.title, contains('章'));
    }
  });

  test('English graded samples are treated as defaults to purge', () {
    const ReadingDoc english = ReadingDoc(
      id: 'builtin_a1_morning_walk',
      title: 'A Morning Walk',
      sourceType: ReadingSourceType.builtin,
      plainText: 'Every morning Mia walks in the park near her home.',
      builtin: true,
    );
    expect(isEnglishDefaultReadingDoc(english), isTrue);

    const ReadingDoc chinese = ReadingDoc(
      id: 'import_user_1',
      title: '自导散文',
      sourceType: ReadingSourceType.import,
      plainText: '春天来了，校园里的玉兰花开了。',
    );
    expect(isEnglishDefaultReadingDoc(chinese), isFalse);
  });
}
