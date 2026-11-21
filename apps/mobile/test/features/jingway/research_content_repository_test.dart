import 'dart:io';

import 'package:common_learn_english/features/jingway/data/research_content_repository.dart';
import 'package:common_learn_english/features/jingway/domain/research_content_gate.dart';
import 'package:common_learn_english/features/jingway/domain/research_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository refuses to parse when gate is off', () {
    final ResearchContentRepository repo = ResearchContentRepository(
      gate: const ResearchContentGate(debugOverride: false),
    );
    expect(
      () => repo.parseNcrBundle(ResearchContentRepository.syntheticNcrJson),
      throwsA(isA<StateError>()),
    );
  });

  test('synthetic NCR parses with error category and method card', () {
    final ResearchContentRepository repo = ResearchContentRepository(
      gate: const ResearchContentGate(debugOverride: true),
    );
    final List<NcrReadingItem> items =
        repo.parseNcrBundle(ResearchContentRepository.syntheticNcrJson);
    expect(items, isNotEmpty);
    expect(items.first.grades, contains(7));
    expect(items.first.errorCategory, ResearchErrorCategory.inference);
    expect(items.first.methodCard, isNotEmpty);
    expect(items.first.answerIndex, 1);
  });

  test('synthetic CKnowEdit cloze parses poetry blank', () {
    final ResearchContentRepository repo = ResearchContentRepository(
      gate: const ResearchContentGate(debugOverride: true),
    );
    final List<CknowEditClozeItem> items = repo
        .parseCknowEditBundle(ResearchContentRepository.syntheticCknowJson);
    expect(items.length, greaterThanOrEqualTo(2));
    expect(items.first.genre, CknowEditGenre.poetryCloze);
    expect(items.first.answer, '地上');
  });

  test('pubspec assets must not register research corpora', () {
    final File pubspec = File('pubspec.yaml');
    expect(pubspec.existsSync(), isTrue);
    final String text = pubspec.readAsStringSync();
    expect(text.contains('data/research'), isFalse);
    expect(text.contains('research/ncr'), isFalse);
    expect(text.contains('cknow_edit'), isFalse);
  });

  testWidgets('research files are not Flutter assets', (WidgetTester tester) async {
    expect(
      () => rootBundle.loadString('data/research/ncr/items.json'),
      throwsA(isA<FlutterError>()),
    );
  });
}
