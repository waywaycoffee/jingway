import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:media_kit/media_kit.dart';
import '../../sync/data/acquire_api_client.dart';
import '../../../flavors/app_flavor.dart';

import '../../authentication/presentation/account_storage.dart';
import '../../authentication/presentation/auth_session.dart';
import '../../jingway/domain/jingway_excerpt.dart';
import '../../jingway/presentation/xinhua_lookup_sheet.dart';
import '../../daily_review/data/word_encounter_store.dart';
import '../../navigation/presentation/navigation_destination.dart';
import '../../player/presentation/widgets/subtitle_chunk_highlight.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../shared/data/word_lookup_service.dart';
import '../../shared/data/word_pronunciation_service.dart';
import '../../shared/presentation/pad/app_design_tokens.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../../shared/presentation/pad/pad_top_bar.dart';
import '../../shared/presentation/word_lookup_popup.dart';
import '../../daily_review/presentation/foundation_media_video_sheet.dart';
import '../../learning_modules/assessment_panel.dart';
import '../../jingway/domain/jingway_practice.dart';
import '../../words/data/offline_word_dictionary.dart';
import '../../words/domain/foundation_media.dart';
import '../../words/presentation/foundation_media_provider.dart';
import '../../words/presentation/learned_vocabulary_provider.dart';
import '../../words/presentation/word_book_provider.dart';
import '../data/reading_continuous_tts.dart';
import '../data/reading_gloss.dart';
import '../data/reading_tts.dart';
import '../data/reading_vocab_lists.dart';
import '../domain/reading_bookmarks.dart';
import '../domain/reading_chapters.dart';
import '../domain/reading_doc.dart';
import '../domain/reading_study_mode.dart';
import 'content_media_provider.dart';
import 'reading_chunk_provider.dart';
import 'reading_digital_human_ball.dart';
import 'reading_library_provider.dart';
import 'reading_text_spans.dart';
import 'reading_voice_picker.dart';
import 'reading_vocab_lists_sheet.dart';

const String kReadingSlowModeKey = 'reading_slow_mode_v1';
const String kReadingSoeEnabledKey = 'reading_soe_enabled_v1';

class ReadingReaderScreen extends ConsumerStatefulWidget {
  const ReadingReaderScreen({required this.docId, super.key});

  final String docId;

  @override
  ConsumerState<ReadingReaderScreen> createState() =>
      _ReadingReaderScreenState();
}

class _ReadingReaderScreenState extends ConsumerState<ReadingReaderScreen> {
  final ScrollController _scroll = ScrollController();
  double _fontSize = 20;
  final double _lineHeight = 1.7;
  bool _dark = false;
  ReadingStudyMode _mode = ReadingStudyMode.immersion;
  bool _sentenceTranslate = false;
  int _freqThreshold = kReadingDefaultFreqThreshold;
  Timer? _saveDebounce;
  bool _opened = false;
  bool _playingRemote = false;
  bool _speakingSentence = false;
  bool _continuousPlaying = false;
  bool _slowMode = false;
  bool _soeEnabled = false;
  ReadingTtsGender _ttsGender = ReadingTtsGender.female;
  String _ttsVoiceId = kDefaultJingwaySpeechVoiceId;
  int? _highlightWordIndex;
  int _continuousGeneration = 0;
  Player? _readingAudio;
  Completer<void>? _readingDone;
  String? _glossDocId;
  int _glossThreshold = -1;
  int _glossListsSig = -1;
  Map<String, String> _hardGlosses = const <String, String>{};
  bool _glossLoading = false;
  double? _unknownRate;
  String _focusedSentence = '';
  List<ReadingChapter> _chapters = const <ReadingChapter>[];
  int _chapterIndex = 0;
  String? _chaptersDocId;
  List<ReadingBookmark> _bookmarks = const <ReadingBookmark>[];
  bool _restoredProgress = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _ensureChapters(ReadingDoc doc) {
    if (_chaptersDocId == doc.id && _chapters.isNotEmpty) return;
    _chapters = detectReadingChapters(doc.plainText);
    _chaptersDocId = doc.id;
    _chapterIndex = 0;
    _bookmarks = loadReadingBookmarks(ref.read(studyAccountProvider), doc.id);
  }

  ReadingChapter get _currentChapter {
    if (_chapters.isEmpty) {
      return const ReadingChapter(
        index: 0,
        title: '全文',
        start: 0,
        end: 0,
        bodyStart: 0,
        body: '',
      );
    }
    return _chapters[_chapterIndex.clamp(0, _chapters.length - 1)];
  }

  Future<void> _goChapter(int index, {double localPercent = 0}) async {
    if (_chapters.isEmpty) return;
    setState(() => _chapterIndex = index.clamp(0, _chapters.length - 1));
    await Future<void>.delayed(Duration.zero);
    if (!_scroll.hasClients) return;
    final double max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo((localPercent.clamp(0.0, 1.0) * max).clamp(0.0, max));
  }

  Future<void> _jumpToGlobalOffset(ReadingDoc doc, int offset) async {
    _ensureChapters(doc);
    final int idx = chapterIndexForOffset(_chapters, offset);
    final ReadingChapter ch = _chapters[idx];
    final int bodyLen = ch.body.length;
    final double local = bodyLen <= 0
        ? 0
        : ((offset - ch.bodyStart) / bodyLen).clamp(0.0, 1.0);
    await _goChapter(idx, localPercent: local);
  }

  void _loadPrefs() {
    if (!Hive.isBoxOpen('prefs')) return;
    final Box<String> prefs = Hive.box<String>('prefs');
    _mode = ReadingStudyModeX.fromStorage(prefs.get(kReadingStudyModeKey));
    // Migrate legacy chinese toggle if mode key missing.
    if (prefs.get(kReadingStudyModeKey) == null) {
      final String? legacy = prefs.get('reading_show_inline_chinese_v1');
      if (legacy == '1') {
        _mode = ReadingStudyMode.intensive;
      } else if (legacy == '0') {
        _mode = ReadingStudyMode.immersion;
      }
    }
    _sentenceTranslate = prefs.get(kReadingSentenceTranslateKey) == '1';
    _slowMode = prefs.get(kReadingSlowModeKey) == '1';
    _soeEnabled = prefs.get(kReadingSoeEnabledKey) == '1';
    _ttsGender = ReadingTtsGenderX.fromStorage(prefs.get(kReadingTtsGenderKey));
    final String? voiceId = prefs.get(kReadingTtsVoiceIdKey)?.trim();
    if (voiceId != null && voiceId.isNotEmpty) {
      _ttsVoiceId = voiceId;
    } else if (FlavorConfig.isJingwayProduct) {
      _ttsVoiceId = _ttsGender.jingwayVoiceId;
    }
    final int? thr = int.tryParse(prefs.get(kReadingFreqThresholdKey) ?? '');
    if (thr != null && kReadingFreqThresholdBands.contains(thr)) {
      _freqThreshold = thr;
    }
  }

  @override
  void dispose() {
    _continuousGeneration += 1;
    if (_readingDone?.isCompleted == false) _readingDone!.complete();
    unawaited(_readingAudio?.stop());
    _saveDebounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _persistPrefs() async {
    if (!Hive.isBoxOpen('prefs')) return;
    final Box<String> prefs = Hive.box<String>('prefs');
    await prefs.put(kReadingStudyModeKey, _mode.storageValue);
    await prefs.put(
      kReadingSentenceTranslateKey,
      _sentenceTranslate ? '1' : '0',
    );
    await prefs.put(kReadingFreqThresholdKey, '$_freqThreshold');
    await prefs.put(kReadingSlowModeKey, _slowMode ? '1' : '0');
    await prefs.put(kReadingSoeEnabledKey, _soeEnabled ? '1' : '0');
    await prefs.put(kReadingTtsGenderKey, _ttsGender.storageValue);
    await prefs.put(kReadingTtsVoiceIdKey, _ttsVoiceId);
  }

  Future<void> _speakReading(String text, {double? rate}) {
    return speakReadingText(
      ref,
      text,
      rate: rate ?? _effectiveRate,
      gender: _ttsGender,
      voiceId: _ttsVoiceId,
    );
  }

  Future<void> _pickTtsVoice() async {
    final String? selected = await showReadingVoicePicker(
      context,
      ref,
      currentVoiceId: _ttsVoiceId,
    );
    if (selected == null || !mounted) return;
    await _stopContinuous();
    if (!mounted) return;
    setState(() {
      _ttsVoiceId = selected;
      _ttsGender = loadReadingTtsGender();
    });
    await _persistPrefs();
  }

  double get _effectiveRate {
    final double base = ref.read(learningSettingsProvider).ttsRate;
    return _slowMode ? (base * 0.55).clamp(0.5, 1.0) : base.clamp(0.5, 1.8);
  }

  Future<void> _stopContinuous() async {
    _continuousGeneration += 1;
    if (_readingDone?.isCompleted == false) _readingDone!.complete();
    unawaited(_readingAudio?.stop());
    await ref.read(wordPronunciationServiceProvider).stop();
    if (!mounted) return;
    setState(() {
      _continuousPlaying = false;
      _highlightWordIndex = null;
    });
  }

  Future<void> _playContinuous(ReadingDoc doc) async {
    if (_continuousPlaying) {
      await _stopContinuous();
      return;
    }
    final int generation = ++_continuousGeneration;
    _ensureChapters(doc);
    final List<ReadingSpeakUnit> units =
        splitReadingSpeakUnits(_currentChapter.body);
    if (units.isEmpty) return;
    setState(() => _continuousPlaying = true);
    final double rate = _effectiveRate;
    final player = Player();
    _readingAudio = player;
    try {
      for (final unit in units) {
        if (!mounted || generation != _continuousGeneration) return;
        final url = await ref.read(acquireApiClientProvider).readingSpeech(
              unit.text,
              readingSpeechVoiceId(
                _ttsGender,
                unit.text,
                voiceId: _ttsVoiceId,
              ),
              language: readingSpeechLanguage(unit.text),
            );
        if (!mounted || generation != _continuousGeneration) return;
        final done = Completer<void>();
        _readingDone = done;
        final completed = player.stream.completed.listen((value) {
          if (value && !done.isCompleted) done.complete();
        });
        final errors = player.stream.error.listen((error) {
          if (!done.isCompleted) done.completeError(StateError(error));
        });
        final position = player.stream.position.listen((position) {
          if (!mounted || generation != _continuousGeneration) {
            if (!done.isCompleted) done.complete();
            return;
          }
          final duration = player.state.duration.inMilliseconds;
          if (duration <= 0) return;
          // Relative word positions are estimated within the real audio duration.
          final local = (position.inMilliseconds / duration * unit.wordCount)
              .floor()
              .clamp(0, unit.wordCount - 1);
          setState(() => _highlightWordIndex = unit.firstWordIndex + local);
        });
        try {
          await player.open(Media(url));
          await player.setRate(rate);
          await done.future.timeout(const Duration(minutes: 3));
        } finally {
          if (identical(_readingDone, done)) _readingDone = null;
          await completed.cancel();
          await errors.cancel();
          await position.cancel();
        }
      }
    } catch (_) {
      if (mounted && generation == _continuousGeneration) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('阿里云朗读暂不可用，请检查网络后重试')));
      }
    } finally {
      if (identical(_readingAudio, player)) _readingAudio = null;
      await player.dispose();
      if (mounted && generation == _continuousGeneration) {
        setState(() {
          _continuousPlaying = false;
          _highlightWordIndex = null;
        });
      }
    }
  }

  Future<void> _openMouthVideo(String lexeme) async {
    final FoundationMediaManifest manifest = await ref.read(
      foundationMediaManifestProvider.future,
    );
    final String key = normalizeWord(lexeme);
    FoundationMediaItem? hit;
    for (final String book in const <String>[
      'foundation_ipa_48',
      'foundation_phonics',
      'phonics_jolly',
      'ipa',
    ]) {
      hit = manifest.lookup(book, key);
      if (hit?.hasVideo ?? false) break;
      hit = null;
    }
    // Fall back: any item whose key matches.
    if (hit == null) {
      final String want = FoundationMediaManifest.normKey(key);
      for (final FoundationMediaItem item in manifest.items) {
        if (FoundationMediaManifest.normKey(item.key) == want &&
            item.hasVideo) {
          hit = item;
          break;
        }
      }
    }
    if (!mounted) return;
    if (hit == null || !(hit.hasVideo)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无该词/音素的口型视频（需已上传到服务器）')));
      return;
    }
    await showFoundationMediaVideoSheet(
      context,
      title: '口型示范 · $key',
      videoUrl: hit.videoUrl!,
    );
  }

  int _listsSignature(ReadingVocabLists lists, Set<String> learned) {
    final List<String> knownSorted = lists.known.toList()..sort();
    final List<String> focusSorted = lists.focus.toList()..sort();
    return Object.hash(
      Object.hashAll(knownSorted),
      Object.hashAll(focusSorted),
      learned.length,
    );
  }

  Future<void> _ensureGlosses(ReadingDoc doc) async {
    final ReadingVocabLists lists = ref.read(readingVocabListsProvider);
    final Set<String> learned = ref.read(learnedVocabularyProvider);
    final int listsSig = _listsSignature(lists, learned);
    if (_glossDocId == doc.id &&
        _glossThreshold == _freqThreshold &&
        _glossListsSig == listsSig) {
      return;
    }
    _glossDocId = doc.id;
    _glossThreshold = _freqThreshold;
    _glossListsSig = listsSig;
    if (mounted) setState(() => _glossLoading = true);
    try {
      final ReadingFrequencyLexicon lexicon = await ref.read(
        readingFrequencyLexiconProvider.future,
      );
      final OfflineWordDictionary dictionary = ref.read(
        offlineWordDictionaryProvider,
      );
      final Set<String> known = effectiveKnownWords(
        lists: lists,
        learned: learned,
      );
      final List<String> tokens = extractReadingWordTokens(doc.plainText);
      final Map<String, String> glosses = await buildHardWordGlosses(
        words: tokens.toSet(),
        lexicon: lexicon,
        dictionary: dictionary,
        threshold: _freqThreshold,
        known: known,
        focus: lists.focus,
      );
      final double rate = unknownWordRate(
        words: tokens,
        lexicon: lexicon,
        threshold: _freqThreshold,
        known: known,
        focus: lists.focus,
      );
      if (!mounted || _glossDocId != doc.id) return;
      setState(() {
        _hardGlosses = glosses;
        _unknownRate = rate;
        _glossLoading = false;
      });
    } catch (_) {
      if (!mounted || _glossDocId != doc.id) return;
      setState(() {
        _hardGlosses = const <String, String>{};
        _unknownRate = null;
        _glossLoading = false;
      });
    }
  }

  Future<void> _playRemoteAudio(FoundationMediaItem item) async {
    final String? url = item.audioUrl;
    if (url == null || url.isEmpty || _playingRemote) return;
    setState(() => _playingRemote = true);
    try {
      await ref
          .read(wordPronunciationServiceProvider)
          .speak(item.key, recordedUrl: url, allowSynthesisFallback: false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('朗读音频暂不可用（需已上传到服务器）')));
      }
    } finally {
      if (mounted) setState(() => _playingRemote = false);
    }
  }

  void _scheduleProgressSave(ReadingDoc doc) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!_scroll.hasClients || !mounted) return;
      _ensureChapters(doc);
      final double max = _scroll.position.maxScrollExtent;
      final double offset = _scroll.offset;
      final double local = max <= 0 ? 1.0 : (offset / max).clamp(0.0, 1.0);
      final ReadingChapter ch = _currentChapter;
      final double percent = readingGlobalPercent(
        chapters: _chapters,
        chapterIndex: _chapterIndex,
        localPercent: local,
      );
      final int offsetChars = (ch.bodyStart + local * ch.body.length)
          .round()
          .clamp(0, doc.plainText.length);
      unawaited(
        ref.read(readingLibraryProvider.notifier).updateProgress(
              docId: doc.id,
              offsetChars: offsetChars,
              percent: percent,
            ),
      );
    });
  }

  Future<void> _showToc(ReadingDoc doc) async {
    _ensureChapters(doc);
    final int? selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.7,
            child: ListView.builder(
              itemCount: _chapters.length,
              itemBuilder: (BuildContext context, int i) {
                final ReadingChapter ch = _chapters[i];
                return ListTile(
                  selected: i == _chapterIndex,
                  title: Text(ch.title),
                  subtitle: Text('约 ${ch.body.runes.length} 字'),
                  onTap: () => Navigator.pop(ctx, i),
                );
              },
            ),
          ),
        );
      },
    );
    if (selected != null) await _goChapter(selected);
  }

  Future<void> _showSearch(ReadingDoc doc) async {
    _ensureChapters(doc);
    final TextEditingController q = TextEditingController();
    List<ReadingSearchHit> hits = const <ReadingSearchHit>[];
    final ReadingSearchHit? hit = await showModalBottomSheet<ReadingSearchHit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheet) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom + 12,
                ),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: q,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '在全书中搜索',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (String value) {
                        setSheet(() {
                          hits = searchReadingText(
                            plainText: doc.plainText,
                            query: value,
                            chapters: _chapters,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: hits.length,
                        itemBuilder: (BuildContext context, int i) {
                          final ReadingSearchHit h = hits[i];
                          final String title = _chapters[h.chapterIndex].title;
                          return ListTile(
                            title: Text(h.snippet, maxLines: 2),
                            subtitle: Text(title),
                            onTap: () => Navigator.pop(ctx, h),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    q.dispose();
    if (hit != null) await _jumpToGlobalOffset(doc, hit.offset);
  }

  Future<void> _showBookmarks(ReadingDoc doc) async {
    final String account = ref.read(studyAccountProvider);
    setState(() {
      _bookmarks = loadReadingBookmarks(account, doc.id);
    });
    final ReadingBookmark? picked =
        await showModalBottomSheet<ReadingBookmark>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        if (_bookmarks.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('暂无书签。可点工具栏「书签」添加当前位置。'),
            ),
          );
        }
        return SafeArea(
          child: ListView(
            children: <Widget>[
              for (final ReadingBookmark b in _bookmarks)
                ListTile(
                  title: Text(b.snippet, maxLines: 2),
                  subtitle: Text(
                    b.chapterTitle.isEmpty ? '位置 ${b.offset}' : b.chapterTitle,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final List<ReadingBookmark> next =
                          await removeReadingBookmark(
                        account: account,
                        docId: doc.id,
                        bookmarkId: b.id,
                      );
                      if (!ctx.mounted) return;
                      setState(() => _bookmarks = next);
                      Navigator.pop(ctx);
                      unawaited(_showBookmarks(doc));
                    },
                  ),
                  onTap: () => Navigator.pop(ctx, b),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) await _jumpToGlobalOffset(doc, picked.offset);
  }

  Future<void> _addBookmarkHere(ReadingDoc doc) async {
    _ensureChapters(doc);
    final ReadingChapter ch = _currentChapter;
    double local = 0;
    if (_scroll.hasClients) {
      final double max = _scroll.position.maxScrollExtent;
      local = max <= 0 ? 0 : (_scroll.offset / max).clamp(0.0, 1.0);
    }
    final int offset = (ch.bodyStart + local * ch.body.length).round();
    final int snipEnd = (offset + 40).clamp(0, doc.plainText.length);
    final int snipStart = offset.clamp(0, doc.plainText.length);
    final String snippet =
        doc.plainText.substring(snipStart, snipEnd).replaceAll('\n', ' ');
    final List<ReadingBookmark> next = await addReadingBookmark(
      account: ref.read(studyAccountProvider),
      docId: doc.id,
      offset: offset,
      snippet: snippet,
      chapterTitle: ch.title,
    );
    if (!mounted) return;
    setState(() => _bookmarks = next);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已添加书签')),
    );
  }

  Future<void> _recordLearnedContext(String rawWord, String sentence) async {
    final String word = normalizeWord(rawWord);
    if (word.isEmpty) return;
    if (!ref.read(learnedVocabularyProvider).contains(word)) return;
    try {
      await WordEncounterStore(
        account: ref.read(studyAccountProvider),
      ).recordContext(word, sentence);
    } catch (_) {}
  }

  Future<void> _showLookupCard({
    required ReadingDoc doc,
    required String rawLexeme,
    required String sentence,
  }) async {
    final String lexeme = rawLexeme.trim();
    final bool cjk = RegExp(r'[\u4e00-\u9fff]').hasMatch(lexeme);
    if (!cjk && lexeme.length < 2) return;
    if (cjk && lexeme.isEmpty) return;
    if (sentence.trim().isNotEmpty) {
      setState(() => _focusedSentence = sentence.trim());
    }
    unawaited(_recordLearnedContext(lexeme, sentence));
    if (!mounted) return;
    if (FlavorConfig.isJingwayProduct && cjk) {
      await showXinhuaLookupSheet(context, ref, term: lexeme);
      return;
    }
    final String fallback =
        _hardGlosses[normalizeWord(lexeme)] ??
        _hardGlosses[lexeme.toLowerCase()] ??
        '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        final double maxH = MediaQuery.sizeOf(ctx).height * 0.62;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              MediaQuery.paddingOf(ctx).bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    TextButton.icon(
                      onPressed: () {
                        unawaited(
                          _speakReading(
                            lexeme,
                            rate: (_effectiveRate * 0.7).clamp(0.5, 1.0),
                          ),
                        );
                      },
                      icon: const Icon(Icons.slow_motion_video_rounded),
                      label: const Text('慢读'),
                    ),
                    TextButton.icon(
                      onPressed: () => unawaited(_openMouthVideo(lexeme)),
                      icon: const Icon(Icons.face_retouching_natural_outlined),
                      label: const Text('口型'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        unawaited(
                          ref
                              .read(readingVocabListsProvider.notifier)
                              .markKnown(lexeme),
                        );
                        setState(() => _glossDocId = null);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已加入白名单：$lexeme')),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('已会'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        unawaited(
                          ref
                              .read(readingVocabListsProvider.notifier)
                              .markFocus(lexeme),
                        );
                        setState(() => _glossDocId = null);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已加入黑名单：$lexeme')),
                        );
                      },
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('生词'),
                    ),
                  ],
                ),
                WordLookupPopupCard(
                  rawWord: lexeme,
                  contextSentence: sentence,
                  episodeId: doc.episodeId ?? 'reading:${doc.id}',
                  fallbackDefinitionCn: fallback.isEmpty ? null : fallback,
                  maxHeight: maxH,
                  onClose: () => Navigator.pop(ctx),
                  onPronounce: () {
                    unawaited(_speakReading(lexeme));
                  },
                  onFavorite: (String? definitionCn) {
                    final bool ok = ref
                        .read(wordBookProvider.notifier)
                        .addFavoriteWord(
                          rawWord: lexeme,
                          episodeId: doc.episodeId ?? 'reading:${doc.id}',
                          course: '阅读 · ${doc.title}',
                          episode: doc.episodeTitle.isEmpty
                              ? doc.title
                              : doc.episodeTitle,
                          time: '',
                          lineKey: 'reading:${doc.id}:$lexeme',
                          sentence: sentence,
                          chinese: '',
                          generatedDefinition:
                              (definitionCn ?? '').trim().isEmpty
                              ? null
                              : definitionCn!.trim(),
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? '已加入词书：$lexeme' : '无法加入：$lexeme'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSentenceLongPress({
    required ReadingDoc doc,
    required int start,
    required int end,
  }) async {
    final ({int start, int end, String text}) bounds = sentenceBounds(
      doc.plainText,
      start,
      end,
    );
    final String sentence = bounds.text;
    if (sentence.isEmpty) return;
    setState(() => _focusedSentence = sentence);

    String? zh;
    if (_sentenceTranslate && FlavorConfig.enableMachineTranslation) {
      try {
        zh = await ref
            .read(wordLookupServiceProvider)
            .translateSentence(
              sentence: sentence,
              settings: ref.read(learningSettingsProvider),
            );
      } catch (_) {
        zh = null;
      }
    }
    if (!mounted) return;

    // Auto-speak when long-pressing a sentence.
    unawaited(() async {
      if (!mounted) return;
      setState(() => _speakingSentence = true);
      try {
        await _speakReading(sentence);
      } finally {
        if (mounted) setState(() => _speakingSentence = false);
      }
    }());

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '整句',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                sentence,
                style: const TextStyle(height: 1.45, fontSize: 16),
              ),
              if ((zh ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  zh!.trim(),
                  style: const TextStyle(
                    height: 1.4,
                    fontSize: 15,
                    color: Color(0xFF4A4A52),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _speakingSentence
                    ? null
                    : () async {
                        setState(() => _speakingSentence = true);
                        try {
                          await _speakReading(sentence);
                        } finally {
                          if (mounted) {
                            setState(() => _speakingSentence = false);
                          }
                        }
                      },
                icon: Icon(
                  _speakingSentence
                      ? Icons.hourglass_top_rounded
                      : Icons.volume_up_rounded,
                ),
                label: Text(_speakingSentence ? '朗读中…' : '再读一遍'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppDesignTokens.brandGreenDark,
                ),
              ),
              if (FlavorConfig.isJingwayProduct &&
                  isJingwayOriginalDoc(doc.id))
                TextButton(
                  onPressed: () async {
                    final AuthSessionState auth =
                        ref.read(authSessionProvider);
                    final String? scope = jingwayWritingScope(
                      signedIn: auth.isLoggedIn,
                      account: auth.email,
                    );
                    if (scope == null) return;
                    try {
                      await JingwayExcerpt(
                        docId: doc.id,
                        title: doc.title,
                        start: bounds.start,
                        text: sentence,
                      ).add(scope);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已保存到作文素材本')),
                        );
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('素材保存失败，请重试')),
                        );
                      }
                    }
                  },
                  child: const Text('摘录到作文素材本'),
                ),
              if (FlavorConfig.enableMachineTranslation) ...<Widget>[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    final bool next = !_sentenceTranslate;
                    setState(() => _sentenceTranslate = next);
                    unawaited(_persistPrefs());
                    Navigator.pop(ctx);
                    if (next) {
                      unawaited(
                        _onSentenceLongPress(doc: doc, start: start, end: end),
                      );
                    }
                  },
                  child: Text(
                    _sentenceTranslate ? '句译：开（点此关闭）' : '句译：关（点此开启）',
                  ),
                ),
              ],
              if (_soeEnabled) ...<Widget>[
                const SizedBox(height: 12),
                AssessmentPanel(reference: sentence),
              ] else
                TextButton(
                  onPressed: () {
                    setState(() => _soeEnabled = true);
                    unawaited(_persistPrefs());
                    Navigator.pop(ctx);
                    unawaited(
                      _onSentenceLongPress(doc: doc, start: start, end: end),
                    );
                  },
                  child: const Text('开启跟读评测（可选）'),
                ),
            ],
          ),
        );
      },
    );
  }

  void _addHardWordsToBook(ReadingDoc doc) {
    int added = 0;
    for (final MapEntry<String, String> e in _hardGlosses.entries.take(25)) {
      final bool ok = ref
          .read(wordBookProvider.notifier)
          .addFavoriteWord(
            rawWord: e.key,
            episodeId: doc.episodeId ?? 'reading:${doc.id}',
            course: '阅读难词 · ${doc.title}',
            episode: doc.title,
            time: '',
            lineKey: 'reading:${doc.id}:hard:${e.key}',
            sentence: '',
            chinese: '',
            generatedDefinition: e.value,
          );
      if (ok) added += 1;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(added == 0 ? '没有可加入的难词' : '已加入 $added 个难词到词书')),
    );
  }

  void _openFreqSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.paddingOf(ctx).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    '自动生词阈值',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '高亮 / 词下中文：词频排名 > $_freqThreshold',
                    style: const TextStyle(color: Color(0xFF626262)),
                  ),
                  Slider(
                    value: kReadingFreqThresholdBands
                        .indexOf(_freqThreshold)
                        .clamp(0, kReadingFreqThresholdBands.length - 1)
                        .toDouble(),
                    min: 0,
                    max: (kReadingFreqThresholdBands.length - 1).toDouble(),
                    divisions: kReadingFreqThresholdBands.length - 1,
                    label: '$_freqThreshold',
                    onChanged: (double v) {
                      final int next = kReadingFreqThresholdBands[v.round()];
                      setModal(() => _freqThreshold = next);
                      setState(() {
                        _freqThreshold = next;
                        _glossDocId = null;
                      });
                      unawaited(_persistPrefs());
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      for (final int band in kReadingFreqThresholdBands)
                        ChoiceChip(
                          label: Text('${band ~/ 1000}k'),
                          selected: _freqThreshold == band,
                          onSelected: (_) {
                            setModal(() => _freqThreshold = band);
                            setState(() {
                              _freqThreshold = band;
                              _glossDocId = null;
                            });
                            unawaited(_persistPrefs());
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      unawaited(showReadingVocabListsSheet(context, ref));
                    },
                    icon: const Icon(Icons.rule_folder_outlined),
                    label: const Text('管理黑白名单'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReadingLibraryState library = ref.watch(readingLibraryProvider);
    final ReadingDoc? doc = library.docById(widget.docId);
    if (!library.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('阅读')),
        body: const Center(child: Text('找不到这篇读物')),
      );
    }
    _ensureChapters(doc);
    if (!_opened) {
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          ref.read(readingLibraryProvider.notifier).touchOpened(doc.id),
        );
        if (!mounted || _restoredProgress) return;
        _restoredProgress = true;
        final ReadingProgress? p = library.progressFor(doc.id);
        if (p == null) return;
        unawaited(
          _jumpToGlobalOffset(
            doc,
            p.offsetChars > 0
                ? p.offsetChars
                : (p.percent * doc.plainText.length).round(),
          ),
        );
      });
    }
    unawaited(_ensureGlosses(doc));
    final ReadingChapter chapter = _currentChapter;
    final String chapterText =
        chapter.body.isEmpty ? doc.plainText : chapter.body;
    final int charCount = doc.plainText.runes.length;
    final String metaLabel = FlavorConfig.isJingwayProduct
        ? '${_chapterIndex + 1}/${_chapters.length} · $charCount 字'
        : '${doc.level} · ${doc.wordCount} words';

    final bool showChinese = _mode.showInlineChinese;
    final Color bg = readingBackgroundColor(_dark);
    final Color fg = readingForegroundColor(_dark);
    final AsyncValue<FoundationMediaManifest> mediaAsync = ref.watch(
      readingContentMediaProvider,
    );
    final FoundationMediaItem? remoteMedia = mediaAsync.maybeWhen(
      data: (FoundationMediaManifest m) =>
          readingMediaForDoc(m, doc.id) ??
          readingMediaForDoc(m, doc.title) ??
          readingMediaForDoc(m, doc.sourceLabel),
      orElse: () => null,
    );
    final SubtitleChunkHighlighter? chunks = ref
        .watch(readingChunkHighlighterProvider)
        .asData
        ?.value;
    final Set<String> learned = ref.watch(learnedVocabularyProvider);
    final String rateLabel = _unknownRate == null
        ? ''
        : ' · 生词率 ${(_unknownRate! * 100).toStringAsFixed(1)}%';

    return PadScaffold(
      currentDestination: AppNavDestination.readingHub,
      showContinueLearning: false,
      showNavigation: false,
      topBar: PadTopBar(
        title: doc.title,
        trailing: const SizedBox.shrink(),
        description: '${chapter.title} · $metaLabel$rateLabel',
        leading: PadBackButton(onPressed: () => context.pop()),
        actions: <Widget>[
          IconButton(
            tooltip: '目录',
            onPressed: () => unawaited(_showToc(doc)),
            icon: const Icon(Icons.list_alt_rounded),
          ),
          IconButton(
            tooltip: '搜索',
            onPressed: () => unawaited(_showSearch(doc)),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: '添加书签',
            onPressed: () => unawaited(_addBookmarkHere(doc)),
            onLongPress: () => unawaited(_showBookmarks(doc)),
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
          if (FlavorConfig.isJingwayProduct &&
              jingwayPracticePackForDoc(doc.id) != null)
            IconButton(
              tooltip: '篇后练习',
              icon: const Icon(Icons.quiz_outlined),
              onPressed: () => context.push(
                '/exam?pack=${jingwayPracticePackForDoc(doc.id)}',
              ),
            ),
          IconButton(
            tooltip: _continuousPlaying ? '停止朗读' : '朗读本章',
            onPressed: () => unawaited(_playContinuous(doc)),
            icon: Icon(
              _continuousPlaying
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline_rounded,
              color: _continuousPlaying ? AppDesignTokens.brandGreenDark : null,
            ),
          ),
          IconButton(
            tooltip: _mode == ReadingStudyMode.immersion ? '切换精读' : '切换沉浸',
            onPressed: () {
              setState(() {
                _mode = _mode == ReadingStudyMode.immersion
                    ? ReadingStudyMode.intensive
                    : ReadingStudyMode.immersion;
              });
              unawaited(_persistPrefs());
            },
            icon: Icon(
              _mode == ReadingStudyMode.immersion
                  ? Icons.menu_book_outlined
                  : Icons.auto_stories_rounded,
              color: _mode == ReadingStudyMode.intensive
                  ? AppDesignTokens.brandGreenDark
                  : null,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '更多',
            onSelected: (String value) {
              switch (value) {
                case 'voice':
                  unawaited(_pickTtsVoice());
                case 'slow':
                  setState(() => _slowMode = !_slowMode);
                  unawaited(_persistPrefs());
                case 'freq':
                  _openFreqSheet();
                case 'hard':
                  _addHardWordsToBook(doc);
                case 'remote':
                  if (remoteMedia != null) {
                    unawaited(_playRemoteAudio(remoteMedia));
                  }
                case 'lists':
                  unawaited(showReadingVocabListsSheet(context, ref));
                case 'font':
                  setState(() {
                    _fontSize = _fontSize >= 24 ? 18 : _fontSize + 2;
                  });
                case 'theme':
                  setState(() => _dark = !_dark);
                case 'episode':
                  if ((doc.episodeId ?? '').isNotEmpty) {
                    context.push(
                      '/episodes/${Uri.encodeComponent(doc.episodeId!)}',
                    );
                  }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'voice',
                child: Text(
                  '音色：${jingwaySpeechVoiceLabel(_ttsVoiceId).split(' · ').first}',
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'slow',
                child: Text(_slowMode ? '关闭慢读' : '慢读模式'),
              ),
              const PopupMenuItem<String>(
                value: 'freq',
                child: Text('词频阈值 / 名单'),
              ),
              const PopupMenuItem<String>(value: 'lists', child: Text('黑白名单')),
              if (_hardGlosses.isNotEmpty)
                const PopupMenuItem<String>(
                  value: 'hard',
                  child: Text('难词进词书'),
                ),
              if (remoteMedia?.hasAudio ?? false)
                PopupMenuItem<String>(
                  value: 'remote',
                  enabled: !_playingRemote,
                  child: Text(_playingRemote ? '朗读中…' : '服务器朗读'),
                ),
              const PopupMenuItem<String>(value: 'font', child: Text('字号')),
              PopupMenuItem<String>(
                value: 'theme',
                child: Text(_dark ? '浅色' : '深色'),
              ),
              if (doc.sourceType == ReadingSourceType.video &&
                  (doc.episodeId ?? '').isNotEmpty)
                const PopupMenuItem<String>(
                  value: 'episode',
                  child: Text('打开原集'),
                ),
            ],
          ),
        ],
      ),
      body: ReadingDigitalHumanBallHost(
        enabled: !FlavorConfig.isJingwayProduct ||
            isJingwayOriginalDoc(doc.id),
        doc: doc,
        focusedSentence: _focusedSentence,
        child: ColoredBox(
          color: bg,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification n) {
              if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
                _scheduleProgressSave(doc);
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    doc.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.25,
                      fontFamily: 'Georgia',
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metaLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  if (_chapters.length > 1) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      chapter.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (_mode.showChunkLegend || showChinese)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          if (_mode.showChunkLegend) ...<Widget>[
                            _LegendChip(
                              color: SubtitleChunkHighlighter.legendColor(
                                SubtitleChunkKind.phrase,
                              ),
                              label: '词组',
                              dark: _dark,
                            ),
                            _LegendChip(
                              color: SubtitleChunkHighlighter.legendColor(
                                SubtitleChunkKind.chunk,
                              ),
                              label: '语块',
                              dark: _dark,
                            ),
                            _LegendChip(
                              color: SubtitleChunkHighlighter.legendColor(
                                SubtitleChunkKind.usage,
                              ),
                              label: '用法',
                              dark: _dark,
                            ),
                          ],
                          Text(
                            showChinese
                                ? (_glossLoading
                                      ? '难词释义加载中…'
                                      : '词下灰字 = 词频>$_freqThreshold · 双击语块 · 长按整句')
                                : '沉浸模式 · 点词/双击语块/长按整句',
                            style: TextStyle(
                              fontSize: 12,
                              color: _dark
                                  ? const Color(0xFF9A9AA2)
                                  : const Color(0xFF6B6B76),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text.rich(
                    TextSpan(
                      children: buildReadingTextSpans(
                        text: chapterText,
                        textColor: fg,
                        fontSize: _fontSize,
                        lineHeight: _lineHeight,
                        dark: _dark,
                        showChinese: showChinese,
                        showChunks: !FlavorConfig.isJingwayProduct,
                        learnedWords: learned,
                        hardGlosses: _hardGlosses,
                        chunkHighlighter: chunks,
                        onWordTap: (String word, int start, int end) {
                          final String sentence = sentenceBounds(
                            chapterText,
                            start,
                            end,
                          ).text;
                          unawaited(
                            _showLookupCard(
                              doc: doc,
                              rawLexeme: word,
                              sentence: sentence,
                            ),
                          );
                        },
                        onWordLongPress: (String word, int start, int end) {
                          unawaited(
                            _onSentenceLongPress(
                              doc: doc,
                              start: chapter.bodyStart + start,
                              end: chapter.bodyStart + end,
                            ),
                          );
                        },
                        onChunkDoubleTap: (String phrase, int start, int end) {
                          final String sentence = sentenceBounds(
                            chapterText,
                            start,
                            end,
                          ).text;
                          unawaited(
                            _showLookupCard(
                              doc: doc,
                              rawLexeme: phrase,
                              sentence: sentence,
                            ),
                          );
                        },
                        onChunkLongPress: (String phrase, int start, int end) {
                          unawaited(
                            _onSentenceLongPress(
                              doc: doc,
                              start: chapter.bodyStart + start,
                              end: chapter.bodyStart + end,
                            ),
                          );
                        },
                        highlightWordIndex: _highlightWordIndex,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_chapters.length > 1)
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _chapterIndex <= 0
                                ? null
                                : () => unawaited(_goChapter(_chapterIndex - 1)),
                            child: const Text('上一章'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _chapterIndex >= _chapters.length - 1
                                ? null
                                : () => unawaited(_goChapter(_chapterIndex + 1)),
                            child: const Text('下一章'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomBar: Material(
        color: bg,
        elevation: 6,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: fg.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Text(
                      '${((library.progressFor(doc.id)?.percent ?? 0) * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: (library.progressFor(doc.id)?.percent ?? 0)
                      .clamp(0.0, 1.0),
                  onChanged: (double v) {
                    final int offset = (v * doc.plainText.length).round();
                    unawaited(_jumpToGlobalOffset(doc, offset));
                    unawaited(
                      ref.read(readingLibraryProvider.notifier).updateProgress(
                            docId: doc.id,
                            offsetChars: offset,
                            percent: v,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.dark,
  });

  final Color color;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: dark ? const Color(0xFFF2F2F7) : const Color(0xFF2A2A32),
        ),
      ),
    );
  }
}
