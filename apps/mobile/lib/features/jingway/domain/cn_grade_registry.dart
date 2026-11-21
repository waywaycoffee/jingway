/// K12 Chinese grade registry for 景行语文 (exam-oriented).
enum CnSchoolBand { primary, junior, senior }

class CnGrade {
  const CnGrade({
    required this.grade,
    required this.id,
    required this.label,
    required this.band,
    this.examTrackHint = '',
  });

  /// 1–12 numeric grade (P0 content focuses on 1–9).
  final int grade;
  final String id;
  final String label;
  final CnSchoolBand band;

  /// Suggested exam track label shown on home (e.g. 中考).
  final String examTrackHint;
}

const List<CnGrade> kCnGrades = <CnGrade>[
  CnGrade(grade: 1, id: 'g1', label: '一年级', band: CnSchoolBand.primary),
  CnGrade(grade: 2, id: 'g2', label: '二年级', band: CnSchoolBand.primary),
  CnGrade(grade: 3, id: 'g3', label: '三年级', band: CnSchoolBand.primary),
  CnGrade(grade: 4, id: 'g4', label: '四年级', band: CnSchoolBand.primary),
  CnGrade(grade: 5, id: 'g5', label: '五年级', band: CnSchoolBand.primary),
  CnGrade(
    grade: 6,
    id: 'g6',
    label: '六年级',
    band: CnSchoolBand.primary,
    examTrackHint: '小升初',
  ),
  CnGrade(grade: 7, id: 'g7', label: '七年级', band: CnSchoolBand.junior),
  CnGrade(grade: 8, id: 'g8', label: '八年级', band: CnSchoolBand.junior),
  CnGrade(
    grade: 9,
    id: 'g9',
    label: '九年级',
    band: CnSchoolBand.junior,
    examTrackHint: '中考',
  ),
  CnGrade(grade: 10, id: 'g10', label: '高一', band: CnSchoolBand.senior),
  CnGrade(grade: 11, id: 'g11', label: '高二', band: CnSchoolBand.senior),
  CnGrade(
    grade: 12,
    id: 'g12',
    label: '高三',
    band: CnSchoolBand.senior,
    examTrackHint: '高考',
  ),
];

CnGrade? cnGradeByNumber(int? grade) {
  if (grade == null) return null;
  for (final CnGrade g in kCnGrades) {
    if (g.grade == grade) return g;
  }
  return null;
}

CnGrade? cnGradeById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final CnGrade g in kCnGrades) {
    if (g.id == id) return g;
  }
  return null;
}

List<CnGrade> cnGradesForBand(CnSchoolBand band) =>
    kCnGrades.where((CnGrade g) => g.band == band).toList(growable: false);

/// Whether a content pack tagged with [packGrades] should show for [userGrade].
bool contentMatchesGrade({
  required int userGrade,
  required List<int> packGrades,
  int? gradeMin,
  int? gradeMax,
}) {
  if (packGrades.isNotEmpty) return packGrades.contains(userGrade);
  if (gradeMin != null || gradeMax != null) {
    final int lo = gradeMin ?? 1;
    final int hi = gradeMax ?? 12;
    return userGrade >= lo && userGrade <= hi;
  }
  // Untagged packs are not recommended into the default stream.
  return false;
}
