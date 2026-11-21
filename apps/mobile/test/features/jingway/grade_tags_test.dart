import 'package:common_learn_english/features/jingway/domain/grade_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grade tag roundtrip', () {
    expect(gradeTag(7), 'grade:7');
    expect(gradeFromTags(<String>['exam:zhongkao', 'grade:7']), 7);
    expect(gradeFromReviewKey('g7:char:霜'), 7);
    expect(gradeFromReviewKey('entry:foo'), isNull);
  });
}
