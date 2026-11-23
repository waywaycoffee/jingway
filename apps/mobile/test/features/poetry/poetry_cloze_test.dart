import 'package:common_learn_english/features/poetry/domain/poetry_cloze.dart';
import 'package:common_learn_english/features/poetry/domain/poetry_comprehension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildPoetryCloze masks contiguous chars', () {
    final List<PoetryClozeItem> items = buildPoetryCloze(
      lines: const <String>['床前明月光', '疑是地上霜'],
      blanksPerPass: 2,
      seed: 1,
    );
    expect(items.length, 2);
    for (final PoetryClozeItem item in items) {
      expect(item.displayLine.contains('＿'), isTrue);
      expect(item.blank.isNotEmpty, isTrue);
      expect(acceptsPoetryCloze(item.blank, item.blank), isTrue);
      expect(acceptsPoetryCloze(item.blank, '错'), isFalse);
    }
  });

  test('comprehension accepts ordered blanks', () {
    expect(
      acceptsComprehensionAnswers(
        expected: const <String>['举头望明月', '低头思故乡'],
        actual: const <String>['举头望明月', '低头思故乡'],
      ),
      isTrue,
    );
    expect(
      acceptsComprehensionAnswers(
        expected: const <String>['举头望明月', '低头思故乡'],
        actual: const <String>['低头思故乡', '举头望明月'],
      ),
      isFalse,
    );
  });

  test('promptWithFills replaces placeholders', () {
    const PoetryComprehensionItem item = PoetryComprehensionItem(
      id: 't',
      poemId: 'jingye_si',
      title: '静夜思',
      author: '李白',
      prompt: r'句子是「$0，$1」。',
      answers: <String>['A', 'B'],
    );
    expect(item.promptWithFills(const <String>['甲', '乙']), '句子是「甲，乙」。');
  });
}
