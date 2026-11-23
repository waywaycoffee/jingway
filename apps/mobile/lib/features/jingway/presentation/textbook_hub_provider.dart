import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/textbook_catalog.dart';
import '../data/textbook_download.dart';
import '../domain/textbook_models.dart';
import 'jingway_profile_provider.dart';

final Provider<TextbookCatalogRepository> textbookCatalogRepositoryProvider =
    Provider<TextbookCatalogRepository>(
      (Ref ref) => const TextbookCatalogRepository(),
    );

final Provider<TextbookDownloadService> textbookDownloadServiceProvider =
    Provider<TextbookDownloadService>((Ref ref) => TextbookDownloadService());

final FutureProvider<TextbookCatalogBundle> textbookCatalogProvider =
    FutureProvider<TextbookCatalogBundle>((Ref ref) {
      return ref.read(textbookCatalogRepositoryProvider).load();
    });

class TextbookBandFilter extends Notifier<String?> {
  @override
  String? build() {
    final int? grade = ref.watch(jingwayProfileProvider).cnGrade?.grade;
    if (grade == null) return null;
    if (grade <= 6) return '小学';
    if (grade <= 9) return '初中';
    return '高中';
  }

  void setBand(String? band) => state = band;
}

final NotifierProvider<TextbookBandFilter, String?>
textbookBandFilterProvider =
    NotifierProvider<TextbookBandFilter, String?>(TextbookBandFilter.new);

class TextbookGradeFilter extends Notifier<int?> {
  @override
  int? build() {
    return ref.watch(jingwayProfileProvider).cnGrade?.grade;
  }

  void setGrade(int? grade) => state = grade;
}

final NotifierProvider<TextbookGradeFilter, int?> textbookGradeFilterProvider =
    NotifierProvider<TextbookGradeFilter, int?>(TextbookGradeFilter.new);

class TextbookYuwenVolume extends Notifier<String?> {
  @override
  String? build() => null;

  void setVolume(String? code) => state = code;
}

final NotifierProvider<TextbookYuwenVolume, String?>
textbookYuwenVolumeProvider =
    NotifierProvider<TextbookYuwenVolume, String?>(TextbookYuwenVolume.new);

List<TextbookItem> filterTextbookItems(
  List<TextbookItem> items, {
  String? band,
  int? grade,
}) {
  return items.where((TextbookItem item) {
    if (band != null && band.isNotEmpty && item.band != band) {
      return false;
    }
    if (grade != null && item.grade != null && item.grade != grade) {
      // Allow high-school shared packs (必修) when grade is 10–12 loosely.
      if (grade >= 10 && (item.grade ?? 0) >= 10) {
        return true;
      }
      return false;
    }
    return true;
  }).toList(growable: false);
}
