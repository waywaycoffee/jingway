import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../daily_review/data/memory_item_store.dart';
import '../../daily_review/domain/daily_review.dart';
import '../../daily_review/domain/memory_item.dart';
import '../../jingway/data/xinhua_dictionary.dart';
import '../../jingway/domain/grade_tags.dart';
import '../../jingway/presentation/jingway_classical_text.dart';
import '../../jingway/presentation/jingway_colors.dart';
import '../../jingway/presentation/jingway_profile_provider.dart';
import '../../jingway/presentation/jingway_rice_paper.dart';
import '../../jingway/presentation/xinhua_lookup_sheet.dart';
import '../../navigation/presentation/navigation_destination.dart';
import '../../player/domain/cn_dictation_diff.dart';
import '../../reading/data/reading_tts.dart';
import '../../reading/presentation/reading_voice_picker.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../domain/poetry_cloze.dart';
import '../domain/poetry_comprehension.dart';
import 'poetry_catalog_screen.dart';

enum _ReciteMode { listen, mask, nextLine, cloze, comprehension, dictation }

final poetryComprehensionProvider =
    FutureProvider.autoDispose<List<PoetryComprehensionItem>>((Ref ref) {
  return loadPoetryComprehensions();
});

class PoetryReciteScreen extends ConsumerStatefulWidget {
  const PoetryReciteScreen({required this.unitId, super.key});

  final String unitId;

  @override
  ConsumerState<PoetryReciteScreen> createState() => _PoetryReciteScreenState();
}

class _PoetryReciteScreenState extends ConsumerState<PoetryReciteScreen> {
  _ReciteMode _mode = _ReciteMode.listen;
  JingwayWritingDirection _writing = JingwayWritingDirection.horizontalLtr;
  int _maskLevel = 1;
  int _lineIndex = 0;
  final TextEditingController _input = TextEditingController();
  final List<TextEditingController> _blankInputs = <TextEditingController>[];
  CnDictationDiffResult? _lastDiff;
  List<PoetryClozeItem> _cloze = const <PoetryClozeItem>[];
  int _clozeIndex = 0;
  bool _clozeOk = false;
  String? _clozeHint;
  int _compIndex = 0;
  bool? _compOk;
  int? _speakLine;
  bool _speaking = false;
  String _voiceId = kDefaultJingwaySpeechVoiceId;

  @override
  void initState() {
    super.initState();
    final String? stored = loadReadingTtsVoiceId();
    if (stored != null && stored.isNotEmpty) {
      _voiceId = stored;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    for (final TextEditingController c in _blankInputs) {
      c.dispose();
    }
    super.dispose();
  }

  PoetryUnit? _find(List<PoetryUnit> all) {
    for (final PoetryUnit u in all) {
      if (u.id == widget.unitId) return u;
    }
    return null;
  }

  void _resetPracticeState() {
    _lastDiff = null;
    _input.clear();
    _clozeOk = false;
    _clozeHint = null;
    _compOk = null;
    for (final TextEditingController c in _blankInputs) {
      c.clear();
    }
  }

  void _ensureCloze(PoetryUnit unit) {
    if (_cloze.isNotEmpty) return;
    _cloze = buildPoetryCloze(lines: unit.lines, blanksPerPass: 2);
    _clozeIndex = 0;
  }

  void _syncBlankControllers(int count) {
    while (_blankInputs.length < count) {
      _blankInputs.add(TextEditingController());
    }
    while (_blankInputs.length > count) {
      _blankInputs.removeLast().dispose();
    }
  }

  Future<void> _speakLines(PoetryUnit unit) async {
    if (_speaking) return;
    setState(() {
      _speaking = true;
      _mode = _ReciteMode.listen;
      _speakLine = 0;
    });
    try {
      for (int i = 0; i < unit.lines.length; i++) {
        if (!mounted) return;
        setState(() => _speakLine = i);
        final String line = unit.lines[i].trim();
        if (line.isEmpty) continue;
        await speakReadingText(ref, line, voiceId: _voiceId);
        // Estimate dwell so highlight stays readable between network TTS calls.
        final int ms = (line.runes.length * 280).clamp(600, 3200);
        await Future<void>.delayed(Duration(milliseconds: ms ~/ 4));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('朗读暂不可用：请确认已登录，或检查系统中文语音引擎'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _speaking = false;
          _speakLine = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(poetryCatalogProvider);
    final compsAsync = ref.watch(poetryComprehensionProvider);
    return async.when(
      loading: () => const PadScaffold(
        currentDestination: AppNavDestination.reading,
        showContinueLearning: false,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace st) => PadScaffold(
        currentDestination: AppNavDestination.reading,
        showContinueLearning: false,
        body: Center(child: Text('$e')),
      ),
      data: (List<PoetryUnit> all) {
        final PoetryUnit? unit = _find(all);
        if (unit == null) {
          return PadScaffold(
            currentDestination: AppNavDestination.reading,
            showContinueLearning: false,
            body: Center(
              child: TextButton(
                onPressed: () => context.go('/poetry'),
                child: const Text('返回目录'),
              ),
            ),
          );
        }
        final List<PoetryComprehensionItem> comps = compsAsync.maybeWhen(
          data: (List<PoetryComprehensionItem> allComps) =>
              comprehensionsForPoem(allComps, unit.id),
          orElse: () => const <PoetryComprehensionItem>[],
        );
        return PadScaffold(
          currentDestination: AppNavDestination.reading,
          showContinueLearning: false,
          backgroundColor: JingwayColors.cream,
          body: JingwayRicePaperBackdrop(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: <Widget>[
                JingwayRicePaperPanel(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          for (final _ReciteMode m in _ReciteMode.values)
                            ChoiceChip(
                              label: Text(switch (m) {
                                _ReciteMode.listen => '朗读',
                                _ReciteMode.mask => '遮挡',
                                _ReciteMode.nextLine => '上下句',
                                _ReciteMode.cloze => '挖空',
                                _ReciteMode.comprehension => '理解默写',
                                _ReciteMode.dictation => '全文',
                              }),
                              selected: _mode == m,
                              onSelected: (_) {
                                setState(() {
                                  _mode = m;
                                  _resetPracticeState();
                                  if (m == _ReciteMode.cloze) {
                                    _cloze = const <PoetryClozeItem>[];
                                    _ensureCloze(unit);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<JingwayWritingDirection>(
                        segments:
                            const <ButtonSegment<JingwayWritingDirection>>[
                          ButtonSegment(
                            value: JingwayWritingDirection.horizontalLtr,
                            label: Text('横排 · 左→右'),
                          ),
                          ButtonSegment(
                            value: JingwayWritingDirection.verticalRtl,
                            label: Text('竖排 · 右→左'),
                          ),
                        ],
                        selected: <JingwayWritingDirection>{_writing},
                        onSelectionChanged: (Set<JingwayWritingDirection> s) {
                          setState(() => _writing = s.first);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                JingwayRicePaperPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (_mode == _ReciteMode.listen) ..._buildListen(unit),
                      if (_mode == _ReciteMode.mask) ..._buildMask(unit),
                      if (_mode == _ReciteMode.nextLine)
                        ..._buildNextLine(unit),
                      if (_mode == _ReciteMode.cloze) ..._buildCloze(unit),
                      if (_mode == _ReciteMode.comprehension)
                        ..._buildComprehension(unit, comps),
                      if (_mode == _ReciteMode.dictation)
                        ..._buildDictation(unit),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickVoice() async {
    final String? picked = await showReadingVoicePicker(
      context,
      ref,
      currentVoiceId: _voiceId,
    );
    if (picked == null || !mounted) return;
    setState(() => _voiceId = picked);
  }

  List<Widget> _buildListen(PoetryUnit unit) {
    final List<String> display = <String>[
      for (int i = 0; i < unit.lines.length; i++) unit.lines[i],
    ];
    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: _speaking ? null : () => unawaited(_speakLines(unit)),
              icon: Icon(_speaking ? Icons.volume_up : Icons.play_arrow),
              label: Text(_speaking ? '朗读中…' : '逐句朗读'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _speaking ? null : () => unawaited(_pickVoice()),
            icon: const Icon(Icons.record_voice_over_outlined),
            label: Text(
              jingwaySpeechVoiceLabel(_voiceId).split(' · ').first,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '当前音色：${jingwaySpeechVoiceLabel(_voiceId)}',
        style: const TextStyle(color: JingwayColors.hint, fontSize: 12),
      ),
      const SizedBox(height: 12),
      JingwayClassicalText(
        lines: display,
        direction: _writing,
        title: unit.title,
        meta: '${unit.dynasty} · ${unit.author} · 素扉式逐句高亮',
        highlightLineIndex: _speakLine,
      ),
      const SizedBox(height: 8),
      const Text(
        '点句可查新华释义。点右侧按钮可选龙安风悦、李白等音色。音频走 ECS。',
        style: TextStyle(color: JingwayColors.hint, fontSize: 12),
      ),
    ];
  }

  List<Widget> _buildMask(PoetryUnit unit) {
    final List<String> displayLines = _maskLevel == 0
        ? unit.lines
        : unit.lines.map((String line) {
            if (_maskLevel == 2) {
              return List<String>.filled(line.runes.length, '＿').join();
            }
            if (line.isEmpty) return '';
            return '${String.fromCharCode(line.runes.first)}'
                '${List<String>.filled(line.runes.length - 1, '＿').join()}';
          }).toList(growable: false);

    return <Widget>[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          ChoiceChip(
            label: const Text('首字提示'),
            selected: _maskLevel == 1,
            onSelected: (_) => setState(() => _maskLevel = 1),
          ),
          ChoiceChip(
            label: const Text('完全遮挡'),
            selected: _maskLevel == 2,
            onSelected: (_) => setState(() => _maskLevel = 2),
          ),
          ChoiceChip(
            label: const Text('显示全文'),
            selected: _maskLevel == 0,
            onSelected: (_) => setState(() => _maskLevel = 0),
          ),
        ],
      ),
      const SizedBox(height: 14),
      JingwayClassicalText(
        lines: displayLines,
        direction: _writing,
        title: unit.title,
        meta: '${unit.dynasty} · ${unit.author}',
      ),
    ];
  }

  List<Widget> _buildNextLine(PoetryUnit unit) {
    if (unit.lines.length < 2) return const <Widget>[Text('正文不足两句')];
    final int maxPrompt = unit.lines.length - 2;
    final int i = _lineIndex.clamp(0, maxPrompt);
    final String prompt = unit.lines[i];
    final String answer = unit.lines[i + 1];
    return <Widget>[
      JingwayClassicalText(
        lines: <String>[prompt],
        direction: _writing,
        title: unit.title,
        meta: '上句 · ${unit.dynasty} · ${unit.author}',
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _input,
        decoration: const InputDecoration(
          labelText: '写下句',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () {
          setState(() {
            _lastDiff = diffCnDictation(expected: answer, actual: _input.text);
          });
        },
        child: const Text('核对'),
      ),
      if (_lastDiff != null) ...<Widget>[
        const SizedBox(height: 8),
        Text(_lastDiff!.exact ? '正确' : '再试试：参考「$answer」'),
        TextButton(
          onPressed: () {
            setState(() {
              _lineIndex = i >= maxPrompt ? 0 : i + 1;
              _input.clear();
              _lastDiff = null;
            });
          },
          child: const Text('下一组'),
        ),
      ],
    ];
  }

  List<Widget> _buildCloze(PoetryUnit unit) {
    _ensureCloze(unit);
    if (_cloze.isEmpty) {
      return const <Widget>[Text('本篇过短，暂无法挖空')];
    }
    final PoetryClozeItem item =
        _cloze[_clozeIndex.clamp(0, _cloze.length - 1)];
    return <Widget>[
      Text(
        '挖空 ${_clozeIndex + 1} / ${_cloze.length}（Reciter 结构）',
        style: const TextStyle(color: JingwayColors.hint, fontSize: 12),
      ),
      const SizedBox(height: 8),
      JingwayClassicalText(
        lines: <String>[item.displayLine],
        direction: _writing,
        title: unit.title,
        meta: '${unit.dynasty} · ${unit.author}',
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _input,
        decoration: const InputDecoration(
          labelText: '填入空缺字',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () {
          final bool ok = acceptsPoetryCloze(item.blank, _input.text);
          setState(() {
            _clozeOk = ok;
            _clozeHint = ok ? null : item.blank;
          });
          if (!ok) {
            unawaited(
              _enqueueWrongChars(
                unit,
                diffCnDictation(expected: item.blank, actual: _input.text),
              ),
            );
          }
        },
        child: const Text('核对'),
      ),
      if (_clozeOk) ...<Widget>[
        const SizedBox(height: 8),
        const Text('正确'),
        TextButton(
          onPressed: () {
            setState(() {
              if (_clozeIndex >= _cloze.length - 1) {
                _cloze = const <PoetryClozeItem>[];
                _ensureCloze(unit);
                _clozeIndex = 0;
              } else {
                _clozeIndex += 1;
              }
              _input.clear();
              _clozeOk = false;
              _clozeHint = null;
            });
          },
          child: const Text('下一空'),
        ),
      ] else if (_clozeHint != null) ...<Widget>[
        const SizedBox(height: 8),
        Text('参考：$_clozeHint'),
      ],
    ];
  }

  List<Widget> _buildComprehension(
    PoetryUnit unit,
    List<PoetryComprehensionItem> comps,
  ) {
    if (comps.isEmpty) {
      return const <Widget>[
        Text('本篇暂无理解性默写题。可先用挖空或全文默写。'),
      ];
    }
    final int i = _compIndex.clamp(0, comps.length - 1);
    final PoetryComprehensionItem item = comps[i];
    _syncBlankControllers(item.answers.length);
    return <Widget>[
      Text(
        '理解默写 ${i + 1} / ${comps.length}',
        style: const TextStyle(color: JingwayColors.hint, fontSize: 12),
      ),
      const SizedBox(height: 8),
      Text(
        item.promptWithFills(
          _blankInputs.map((TextEditingController c) => c.text).toList(),
        ),
        style: const TextStyle(fontSize: 16, height: 1.6),
      ),
      const SizedBox(height: 12),
      for (int b = 0; b < item.answers.length; b++) ...<Widget>[
        TextField(
          controller: _blankInputs[b],
          decoration: InputDecoration(
            labelText: '空 ${b + 1}',
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
      ],
      FilledButton(
        onPressed: () {
          final List<String> fills = _blankInputs
              .take(item.answers.length)
              .map((TextEditingController c) => c.text)
              .toList(growable: false);
          final bool ok = acceptsComprehensionAnswers(
            expected: item.answers,
            actual: fills,
          );
          setState(() => _compOk = ok);
          if (!ok) {
            final String expectedJoined = item.answers.join();
            final String actualJoined = fills.join();
            unawaited(
              _enqueueWrongChars(
                unit,
                diffCnDictation(
                  expected: expectedJoined,
                  actual: actualJoined,
                ),
              ),
            );
          }
        },
        child: const Text('提交'),
      ),
      if (_compOk == true) ...<Widget>[
        const SizedBox(height: 8),
        const Text('正确'),
        TextButton(
          onPressed: () {
            setState(() {
              _compIndex = i >= comps.length - 1 ? 0 : i + 1;
              _compOk = null;
              for (final TextEditingController c in _blankInputs) {
                c.clear();
              }
            });
          },
          child: const Text('下一题'),
        ),
      ] else if (_compOk == false) ...<Widget>[
        const SizedBox(height: 8),
        Text('参考：${item.answers.join('，')}'),
      ],
    ];
  }

  List<Widget> _buildDictation(PoetryUnit unit) {
    final String expected = unit.lines.join();
    return <Widget>[
      JingwayClassicalText(
        lines: const <String>[],
        direction: _writing,
        title: unit.title,
        meta: '${unit.dynasty} · ${unit.author} · 默写全文（标点可省略）',
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _input,
        maxLines: 5,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '在此输入',
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () async {
          final CnDictationDiffResult diff =
              diffCnDictation(expected: expected, actual: _input.text);
          setState(() => _lastDiff = diff);
          await _enqueueWrongChars(unit, diff);
        },
        child: const Text('提交默写'),
      ),
      if (_lastDiff != null) ...<Widget>[
        const SizedBox(height: 12),
        Text(
          _lastDiff!.exact
              ? '全部正确'
              : '错/缺字：${_lastDiff!.reviewChars.join('、')}（已入复习）',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _lastDiff!.marks.map((CnDictationTokenMark m) {
            final Color bg = switch (m.kind) {
              CnDictationTokenKind.correct => const Color(0xFFDCFCE7),
              CnDictationTokenKind.wrong => const Color(0xFFFEE2E2),
              CnDictationTokenKind.missing => const Color(0xFFFEF3C7),
              CnDictationTokenKind.extra => const Color(0xFFE0E7FF),
            };
            final String label = m.kind == CnDictationTokenKind.missing
                ? (m.expected.isEmpty ? '?' : m.expected)
                : (m.actual.isEmpty ? m.expected : m.actual);
            return InkWell(
              onTap: label.isEmpty || label == '?'
                  ? null
                  : () => showXinhuaLookupSheet(context, ref, term: label),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: bg,
                child: Text(label),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    ];
  }

  Future<void> _enqueueWrongChars(
    PoetryUnit unit,
    CnDictationDiffResult diff,
  ) async {
    if (diff.exact || diff.reviewChars.isEmpty) return;
    final int grade = ref.read(jingwayProfileProvider).grade ?? 7;
    final MemoryItemStore store = ref.read(memoryItemStoreProvider.notifier);
    final dict = ref.read(xinhuaDictionaryProvider);
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (final String ch in diff.reviewChars) {
      final entry = await dict.lookup(ch);
      final String gloss = entry?.gloss.trim().isNotEmpty == true
          ? entry!.gloss
          : '默写错字 · ${unit.title}';
      await store.upsert(
        MemoryItem(
          key: jingwayCharReviewKey(grade: grade, char: ch),
          kind: ReviewKind.word,
          question: ch,
          answer: gloss,
          english: entry?.pinyin ?? '',
          chinese: ch,
          sourceLabel: '古诗文默写 · ${unit.title}',
          origin: 'poetry',
          grade: grade,
          createdAtMs: now,
        ),
      );
    }
  }
}
