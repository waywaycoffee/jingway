import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../domain/jingway_profile.dart';

const String kJingwayProfileHiveKey = 'jingway_profile_v1';

final jingwayProfileProvider =
    StateNotifierProvider<JingwayProfileNotifier, JingwayProfile>(
  (Ref ref) => JingwayProfileNotifier(),
);

class JingwayProfileNotifier extends StateNotifier<JingwayProfile> {
  JingwayProfileNotifier() : super(_load()) {
    // Ensure Hive box is available; _load tolerates missing box.
  }

  static JingwayProfile _load() {
    try {
      if (!Hive.isBoxOpen('prefs')) {
        return const JingwayProfile();
      }
      final Box<String> box = Hive.box<String>('prefs');
      final String? raw = box.get(kJingwayProfileHiveKey);
      if (raw != null && raw.isNotEmpty) {
        return JingwayProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {}
    return const JingwayProfile();
  }

  Future<void> _persist(JingwayProfile next) async {
    state = next;
    try {
      final Box<String> box = Hive.box<String>('prefs');
      await box.put(kJingwayProfileHiveKey, jsonEncode(next.toJson()));
    } catch (_) {}
  }

  Future<void> setGrade(int grade, {int? semester}) async {
    await _persist(
      state.copyWith(
        grade: grade,
        semester: semester,
        clearSemester: semester == null,
        onboardingDone: true,
      ),
    );
  }

  Future<void> setLimits({int? dailyNewLimit, int? dailyReviewLimit}) async {
    await _persist(
      state.copyWith(
        dailyNewLimit: dailyNewLimit,
        dailyReviewLimit: dailyReviewLimit,
      ),
    );
  }

  Future<void> completeOnboarding({required int grade, int? semester}) async {
    await setGrade(grade, semester: semester);
  }
}
