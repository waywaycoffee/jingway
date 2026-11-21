import 'cn_grade_registry.dart';

/// Persistent learning profile for 景行语文 (exam-oriented, grade-gated).
class JingwayProfile {
  const JingwayProfile({
    this.grade,
    this.semester,
    this.dailyNewLimit = 20,
    this.dailyReviewLimit = 80,
    this.onboardingDone = false,
  });

  /// Selected K12 grade 1–12; null means user must pick before training.
  final int? grade;

  /// 1 = 上册, 2 = 下册; null = whole grade.
  final int? semester;

  final int dailyNewLimit;
  final int dailyReviewLimit;
  final bool onboardingDone;

  CnGrade? get cnGrade => cnGradeByNumber(grade);

  bool get hasGrade => grade != null;

  JingwayProfile copyWith({
    int? grade,
    int? semester,
    int? dailyNewLimit,
    int? dailyReviewLimit,
    bool? onboardingDone,
    bool clearSemester = false,
    bool clearGrade = false,
  }) {
    return JingwayProfile(
      grade: clearGrade ? null : (grade ?? this.grade),
      semester: clearSemester ? null : (semester ?? this.semester),
      dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'grade': grade,
        'semester': semester,
        'dailyNewLimit': dailyNewLimit,
        'dailyReviewLimit': dailyReviewLimit,
        'onboardingDone': onboardingDone,
      };

  factory JingwayProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const JingwayProfile();
    return JingwayProfile(
      grade: (json['grade'] as num?)?.toInt(),
      semester: (json['semester'] as num?)?.toInt(),
      dailyNewLimit: (json['dailyNewLimit'] as num?)?.toInt() ?? 20,
      dailyReviewLimit: (json['dailyReviewLimit'] as num?)?.toInt() ?? 80,
      onboardingDone: json['onboardingDone'] == true,
    );
  }
}
