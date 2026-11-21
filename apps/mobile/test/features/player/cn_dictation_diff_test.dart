import 'package:common_learn_english/features/player/domain/cn_dictation_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exact match ignores punctuation and spaces', () {
    final CnDictationDiffResult r = diffCnDictation(
      expected: '床前明月光，',
      actual: '床前明月 光',
    );
    expect(r.exact, isTrue);
    expect(r.reviewChars, isEmpty);
  });

  test('wrong and missing chars collected for review', () {
    final CnDictationDiffResult r = diffCnDictation(
      expected: '床前明月光',
      actual: '床前名月',
    );
    expect(r.exact, isFalse);
    expect(r.reviewChars, isNotEmpty);
  });

  test('variant map treats traditional as correct', () {
    final CnDictationDiffResult r = diffCnDictation(
      expected: '学而时习之',
      actual: '學而時習之',
    );
    expect(r.exact, isTrue);
  });
}
