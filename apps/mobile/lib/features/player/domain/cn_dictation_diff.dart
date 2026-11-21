/// Character-level Chinese dictation grading for 景行语文.
///
/// Punctuation and whitespace are ignored. Optional variant map treats
/// traditional/simplified (or other) pairs as correct.
library;

enum CnDictationTokenKind { correct, missing, extra, wrong }

class CnDictationTokenMark {
  const CnDictationTokenMark({
    required this.expected,
    required this.actual,
    required this.kind,
  });

  final String expected;
  final String actual;
  final CnDictationTokenKind kind;
}

class CnDictationDiffResult {
  const CnDictationDiffResult({
    required this.exact,
    required this.marks,
    required this.missingChars,
    required this.extraChars,
    required this.wrongChars,
  });

  final bool exact;
  final List<CnDictationTokenMark> marks;
  final List<String> missingChars;
  final List<String> extraChars;
  final List<String> wrongChars;

  /// Unique wrong/missing Han characters for FSRS enqueue (same day dedupe
  /// is handled by the caller).
  List<String> get reviewChars {
    final Set<String> out = <String>{};
    for (final String c in missingChars) {
      if (_isHan(c)) out.add(c);
    }
    for (final String c in wrongChars) {
      if (_isHan(c)) out.add(c);
    }
    return out.toList(growable: false);
  }

  static bool _isHan(String c) =>
      c.isNotEmpty && RegExp(r'[\u4e00-\u9fff]').hasMatch(c);
}

/// Minimal variant table; extend via assets later.
const Map<String, String> kDefaultCnVariantMap = <String, String>{
  '裡': '里',
  '裏': '里',
  '爲': '为',
  '後': '后',
  '來': '来',
  '說': '说',
  '這': '这',
  '個': '个',
  '麼': '么',
  '對': '对',
  '時': '时',
  '會': '会',
  '學': '学',
  '國': '国',
  '語': '语',
  '書': '书',
  '長': '长',
  '發': '发',
  '門': '门',
  '開': '开',
  '習': '习',
};

final RegExp _cnIgnorable = RegExp(
  r'[\s\p{P}\p{S}·—…「」『』《》〈〉【】（）()\[\]{}""'']+',
  unicode: true,
);

String normalizeCnChar(String c, Map<String, String> variants) {
  if (c.isEmpty) return c;
  return variants[c] ?? c;
}

List<String> tokenizeCnDictation(
  String raw, {
  Map<String, String> variants = kDefaultCnVariantMap,
}) {
  final String stripped = raw.replaceAll(_cnIgnorable, '');
  if (stripped.isEmpty) return const <String>[];
  final List<String> out = <String>[];
  for (final int rune in stripped.runes) {
    final String ch = String.fromCharCode(rune);
    out.add(normalizeCnChar(ch, variants));
  }
  return out;
}

CnDictationDiffResult diffCnDictation({
  required String expected,
  required String actual,
  Map<String, String> variants = kDefaultCnVariantMap,
}) {
  final List<String> exp = tokenizeCnDictation(expected, variants: variants);
  final List<String> act = tokenizeCnDictation(actual, variants: variants);
  if (exp.isEmpty && act.isEmpty) {
    return const CnDictationDiffResult(
      exact: true,
      marks: <CnDictationTokenMark>[],
      missingChars: <String>[],
      extraChars: <String>[],
      wrongChars: <String>[],
    );
  }

  final int n = exp.length;
  final int m = act.length;
  final List<List<int>> dp = List<List<int>>.generate(
    n + 1,
    (_) => List<int>.filled(m + 1, 0),
  );
  for (int i = 1; i <= n; i++) {
    for (int j = 1; j <= m; j++) {
      if (exp[i - 1] == act[j - 1]) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
      } else {
        dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
      }
    }
  }

  final List<CnDictationTokenMark> marks = <CnDictationTokenMark>[];
  final List<String> missing = <String>[];
  final List<String> extra = <String>[];
  final List<String> wrong = <String>[];

  int i = n;
  int j = m;
  final List<CnDictationTokenMark> rev = <CnDictationTokenMark>[];
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0 && exp[i - 1] == act[j - 1]) {
      rev.add(
        CnDictationTokenMark(
          expected: exp[i - 1],
          actual: act[j - 1],
          kind: CnDictationTokenKind.correct,
        ),
      );
      i--;
      j--;
    } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
      rev.add(
        CnDictationTokenMark(
          expected: '',
          actual: act[j - 1],
          kind: CnDictationTokenKind.extra,
        ),
      );
      extra.add(act[j - 1]);
      j--;
    } else if (i > 0 && (j == 0 || dp[i][j - 1] < dp[i - 1][j])) {
      // Prefer marking as wrong when both sides still have tokens and this
      // cell is not an LCS match — check diagonal mismatch.
      if (j > 0 && i > 0 && exp[i - 1] != act[j - 1] && dp[i - 1][j - 1] == dp[i][j]) {
        rev.add(
          CnDictationTokenMark(
            expected: exp[i - 1],
            actual: act[j - 1],
            kind: CnDictationTokenKind.wrong,
          ),
        );
        wrong.add(exp[i - 1]);
        i--;
        j--;
      } else {
        rev.add(
          CnDictationTokenMark(
            expected: exp[i - 1],
            actual: '',
            kind: CnDictationTokenKind.missing,
          ),
        );
        missing.add(exp[i - 1]);
        i--;
      }
    } else {
      break;
    }
  }

  marks.addAll(rev.reversed);

  final bool exact =
      missing.isEmpty && extra.isEmpty && wrong.isEmpty && exp.length == act.length;

  return CnDictationDiffResult(
    exact: exact,
    marks: marks,
    missingChars: missing,
    extraChars: extra,
    wrongChars: wrong,
  );
}
