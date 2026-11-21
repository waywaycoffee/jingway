/// Grade tagging helpers for FSRS / word-book isolation.
const String kGradeTagPrefix = 'grade:';

String gradeTag(int grade) => '$kGradeTagPrefix$grade';

int? gradeFromTags(Iterable<String> tags) {
  for (final String tag in tags) {
    if (!tag.startsWith(kGradeTagPrefix)) continue;
    final int? g = int.tryParse(tag.substring(kGradeTagPrefix.length));
    if (g != null) return g;
  }
  return null;
}

/// Parse `g7:...` style keys used by Jingway review cards.
int? gradeFromReviewKey(String key) {
  final Match? m = RegExp(r'^g(\d+):').firstMatch(key);
  if (m == null) return null;
  return int.tryParse(m.group(1)!);
}

String jingwayCharReviewKey({required int grade, required String char}) =>
    'g$grade:char:$char';

String jingwayIdiomReviewKey({required int grade, required String idiom}) =>
    'g$grade:idiom:$idiom';

String jingwayWordReviewKey({required int grade, required String word}) =>
    'g$grade:word:$word';
