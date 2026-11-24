import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../flavors/app_flavor.dart';
import '../../authentication/presentation/account_storage.dart';
import '../../sync/data/schedule_device_cloud_sync.dart';
import '../domain/reading_doc.dart';

const String kReadingLibraryKey = 'reading_library_v1';
const String kReadingProgressKey = 'reading_progress_v1';

/// English graded samples (AcquireEnglish flavor).
const List<String> kBuiltinReadingAssetPathsEn = <String>[
  'assets/reading/a1_morning_walk.json',
  'assets/reading/a1_tech_robot.json',
  'assets/reading/a2_tech_robot.json',
  'assets/reading/a2_lost_key.json',
  'assets/reading/b1_new_city.json',
  'assets/reading/b1_library_afternoon.json',
  'assets/reading/b2_small_business.json',
];

/// 景行仅保留 2 本中文测试书；正式内容靠用户导入。
const List<String> kBuiltinReadingAssetPathsZh = <String>[
  'assets/reading/cn_test_moon_well.json',
  'assets/reading/cn_test_train_window.json',
];

List<String> get kBuiltinReadingAssetPaths => FlavorConfig.isJingwayProduct
    ? kBuiltinReadingAssetPathsZh
    : kBuiltinReadingAssetPathsEn;

final RegExp _cjkInDocRe = RegExp(r'[\u4e00-\u9fff]');
final RegExp _latinWordRe = RegExp(r'[A-Za-z]{3,}');

/// English graded / starter samples that should not stay on Jingway shelves.
bool isEnglishDefaultReadingDoc(ReadingDoc doc) {
  final String id = doc.id.toLowerCase();
  if (id.startsWith('builtin_a') ||
      id.startsWith('builtin_b') ||
      id.startsWith('starter') ||
      id.contains('cefr') ||
      id.startsWith('onestop') ||
      id.startsWith('magic_')) {
    return true;
  }
  final String text = doc.plainText;
  if (text.trim().isEmpty) return false;
  if (_cjkInDocRe.hasMatch(text)) return false;
  return _latinWordRe.hasMatch(text);
}

class ReadingLibraryState {
  const ReadingLibraryState({
    this.builtin = const <ReadingDoc>[],
    this.userDocs = const <ReadingDoc>[],
    this.progress = const <String, ReadingProgress>{},
    this.ready = false,
  });

  final List<ReadingDoc> builtin;
  final List<ReadingDoc> userDocs;
  final Map<String, ReadingProgress> progress;
  final bool ready;

  List<ReadingDoc> get all => <ReadingDoc>[...builtin, ...userDocs];

  ReadingDoc? docById(String id) {
    for (final ReadingDoc doc in all) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  ReadingProgress? progressFor(String docId) => progress[docId];

  ReadingDoc? get continueDoc {
    ReadingProgress? latest;
    for (final ReadingProgress p in progress.values) {
      if (p.lastOpenedAt == null) continue;
      if (latest == null ||
          (p.lastOpenedAt!.isAfter(latest.lastOpenedAt ?? DateTime(0)))) {
        latest = p;
      }
    }
    if (latest == null) return null;
    return docById(latest.docId);
  }

  int get importCount => userDocs
      .where((ReadingDoc d) => d.sourceType == ReadingSourceType.import)
      .length;

  int get videoCount => userDocs
      .where((ReadingDoc d) => d.sourceType == ReadingSourceType.video)
      .length;

  ReadingLibraryState copyWith({
    List<ReadingDoc>? builtin,
    List<ReadingDoc>? userDocs,
    Map<String, ReadingProgress>? progress,
    bool? ready,
  }) => ReadingLibraryState(
    builtin: builtin ?? this.builtin,
    userDocs: userDocs ?? this.userDocs,
    progress: progress ?? this.progress,
    ready: ready ?? this.ready,
  );
}

class ReadingLibraryNotifier extends Notifier<ReadingLibraryState> {
  String get _account => ref.watch(studyAccountProvider);

  String get _libraryKey => studyStorageKey(kReadingLibraryKey, _account);

  String get _progressKey => studyStorageKey(kReadingProgressKey, _account);

  final ReadingQuota quota = const ReadingQuota();

  @override
  ReadingLibraryState build() {
    ref.watch(studyAccountProvider);
    Future<void>.microtask(_bootstrap);
    return const ReadingLibraryState();
  }

  Future<void> _bootstrap() async {
    final List<ReadingDoc> builtin = <ReadingDoc>[];
    for (final String path in kBuiltinReadingAssetPaths) {
      try {
        final String raw = await rootBundle.loadString(path);
        final ReadingDoc doc = ReadingDoc.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
          builtin: true,
        );
        if (doc.id.isNotEmpty && doc.plainText.trim().isNotEmpty) {
          builtin.add(doc);
        }
      } catch (_) {
        // Missing in tests.
      }
    }
    List<ReadingDoc> userDocs = _loadUserDocs();
    Map<String, ReadingProgress> progress = _loadProgress();
    if (FlavorConfig.isJingwayProduct) {
      final List<ReadingDoc> kept = userDocs
          .where((ReadingDoc d) => !isEnglishDefaultReadingDoc(d))
          .toList(growable: false);
      if (kept.length != userDocs.length) {
        final Set<String> removedIds = userDocs
            .where(isEnglishDefaultReadingDoc)
            .map((ReadingDoc d) => d.id)
            .toSet();
        userDocs = kept;
        progress = <String, ReadingProgress>{
          for (final MapEntry<String, ReadingProgress> e in progress.entries)
            if (!removedIds.contains(e.key)) e.key: e.value,
        };
        if (Hive.isBoxOpen('prefs')) {
          await Hive.box<String>('prefs').put(
            _libraryKey,
            jsonEncode(userDocs.map((ReadingDoc d) => d.toJson()).toList()),
          );
          await Hive.box<String>('prefs').put(
            _progressKey,
            jsonEncode(<String, Object?>{
              for (final MapEntry<String, ReadingProgress> e
                  in progress.entries)
                e.key: e.value.toJson(),
            }),
          );
        }
      }
    }
    if (!ref.mounted) return;
    state = ReadingLibraryState(
      builtin: List<ReadingDoc>.unmodifiable(builtin),
      userDocs: List<ReadingDoc>.unmodifiable(userDocs),
      progress: progress,
      ready: true,
    );
  }

  List<ReadingDoc> _loadUserDocs() {
    if (!Hive.isBoxOpen('prefs')) return const <ReadingDoc>[];
    final String? raw = Hive.box<String>('prefs').get(_libraryKey);
    if (raw == null || raw.isEmpty) return const <ReadingDoc>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <ReadingDoc>[];
      final List<ReadingDoc> docs = <ReadingDoc>[];
      for (final Object? item in decoded) {
        if (item is! Map) continue;
        final ReadingDoc doc = ReadingDoc.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (doc.id.isEmpty) continue;
        if (doc.hasBody ||
            (doc.contentHash != null && doc.contentHash!.isNotEmpty)) {
          docs.add(doc);
        }
      }
      return docs;
    } catch (_) {
      return const <ReadingDoc>[];
    }
  }

  Map<String, ReadingProgress> _loadProgress() {
    if (!Hive.isBoxOpen('prefs')) return const <String, ReadingProgress>{};
    final String? raw = Hive.box<String>('prefs').get(_progressKey);
    if (raw == null || raw.isEmpty) return const <String, ReadingProgress>{};
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, ReadingProgress>{};
      final Map<String, ReadingProgress> out = <String, ReadingProgress>{};
      for (final MapEntry<dynamic, dynamic> e in decoded.entries) {
        if (e.value is! Map) continue;
        final ReadingProgress p = ReadingProgress.fromJson(
          Map<String, dynamic>.from(e.value as Map),
        );
        if (p.docId.isNotEmpty) out[p.docId] = p;
      }
      return out;
    } catch (_) {
      return const <String, ReadingProgress>{};
    }
  }

  Future<void> _persistLibrary({bool scheduleSync = true}) async {
    if (!Hive.isBoxOpen('prefs')) return;
    final String payload = jsonEncode(
      state.userDocs.map((ReadingDoc d) => d.toJson()).toList(),
    );
    await Hive.box<String>('prefs').put(_libraryKey, payload);
    if (scheduleSync) scheduleDeviceCloudSync(key: 'reading');
  }

  Future<void> _persistProgress({bool scheduleSync = true}) async {
    if (!Hive.isBoxOpen('prefs')) return;
    final Map<String, Object?> payload = <String, Object?>{
      for (final MapEntry<String, ReadingProgress> e in state.progress.entries)
        e.key: e.value.toJson(),
    };
    await Hive.box<String>('prefs').put(_progressKey, jsonEncode(payload));
    if (scheduleSync) scheduleDeviceCloudSync(key: 'reading');
  }

  Future<ReadingDoc?> addDoc(ReadingDoc doc, {bool checkQuota = true}) async {
    if (doc.id.isEmpty || doc.plainText.trim().isEmpty) return null;
    if (checkQuota) {
      if (doc.sourceType == ReadingSourceType.import &&
          !quota.canImport(state.importCount)) {
        throw StateError('导入篇数已达上限（${quota.maxImportDocs}）');
      }
      if (doc.sourceType == ReadingSourceType.video &&
          !quota.canGenerateFromVideo(state.videoCount)) {
        throw StateError('视频生成篇数已达上限（${quota.maxVideoDocs}）');
      }
    }
    final List<ReadingDoc> next = <ReadingDoc>[
      for (final ReadingDoc d in state.userDocs)
        if (d.id != doc.id) d,
      doc,
    ];
    state = state.copyWith(
      userDocs: List<ReadingDoc>.unmodifiable(next),
    );
    await _persistLibrary();
    return doc;
  }

  Future<List<ReadingDoc>> addDocs(List<ReadingDoc> docs) async {
    final List<ReadingDoc> saved = <ReadingDoc>[];
    for (final ReadingDoc doc in docs) {
      final ReadingDoc? ok = await addDoc(doc);
      if (ok != null) saved.add(ok);
    }
    return saved;
  }

  Future<void> removeDoc(String docId) async {
    if (state.builtin.any((ReadingDoc d) => d.id == docId)) return;
    final List<ReadingDoc> next = state.userDocs
        .where((ReadingDoc d) => d.id != docId)
        .toList(growable: false);
    final Map<String, ReadingProgress> progress =
        <String, ReadingProgress>{
          for (final MapEntry<String, ReadingProgress> e
              in state.progress.entries)
            if (e.key != docId) e.key: e.value,
        };
    state = state.copyWith(
      userDocs: List<ReadingDoc>.unmodifiable(next),
      progress: progress,
    );
    await _persistLibrary();
    await _persistProgress();
  }

  Future<void> updateProgress({
    required String docId,
    required int offsetChars,
    required double percent,
    bool? completed,
  }) async {
    if (state.docById(docId) == null) return;
    final ReadingProgress prev =
        state.progress[docId] ?? ReadingProgress(docId: docId);
    final ReadingProgress next = prev.copyWith(
      offsetChars: offsetChars.clamp(0, 1 << 30),
      percent: percent.clamp(0.0, 1.0),
      lastOpenedAt: DateTime.now(),
      completed: completed ?? (percent >= 0.95 || prev.completed),
    );
    state = state.copyWith(
      progress: <String, ReadingProgress>{...state.progress, docId: next},
    );
    await _persistProgress();
  }

  Future<void> touchOpened(String docId) async {
    final ReadingProgress prev =
        state.progress[docId] ?? ReadingProgress(docId: docId);
    state = state.copyWith(
      progress: <String, ReadingProgress>{
        ...state.progress,
        docId: prev.copyWith(lastOpenedAt: DateTime.now()),
      },
    );
    await _persistProgress();
  }

  /// Apply merged cloud user docs + progress (builtin list unchanged).
  Future<void> replaceUserLibraryFromCloud({
    required List<ReadingDoc> userDocs,
    required Map<String, ReadingProgress> progress,
  }) async {
    state = state.copyWith(
      userDocs: List<ReadingDoc>.unmodifiable(userDocs),
      progress: Map<String, ReadingProgress>.unmodifiable(progress),
      ready: true,
    );
    await _persistLibrary(scheduleSync: false);
    await _persistProgress(scheduleSync: false);
  }
}

final NotifierProvider<ReadingLibraryNotifier, ReadingLibraryState>
readingLibraryProvider =
    NotifierProvider<ReadingLibraryNotifier, ReadingLibraryState>(
      ReadingLibraryNotifier.new,
    );
