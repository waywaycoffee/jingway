import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../daily_review/data/memory_item_store.dart';
import '../../daily_review/domain/daily_review.dart';
import '../../daily_review/domain/memory_item.dart';
import '../../jingway/data/xinhua_dictionary.dart';
import '../../jingway/domain/grade_tags.dart';
import '../../jingway/presentation/jingway_bamboo_slip_frame.dart';
import '../../jingway/presentation/jingway_colors.dart';
import '../../jingway/presentation/jingway_profile_provider.dart';
import '../../jingway/presentation/xinhua_lookup_sheet.dart';
import '../../navigation/presentation/navigation_destination.dart';
import '../../player/domain/cn_dictation_diff.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import 'poetry_catalog_screen.dart';

enum _ReciteMode { mask, nextLine, dictation }

class PoetryReciteScreen extends ConsumerStatefulWidget {
  const PoetryReciteScreen({required this.unitId, super.key});

  final String unitId;

  @override
  ConsumerState<PoetryReciteScreen> createState() => _PoetryReciteScreenState();
}

class _PoetryReciteScreenState extends ConsumerState<PoetryReciteScreen> {
  _ReciteMode _mode = _ReciteMode.mask;
  JingwayWritingDirection _writing =
      JingwayWritingDirection.horizontalLtr;
  int _maskLevel = 1;
  int _lineIndex = 0;
  final TextEditingController _input = TextEditingController();
  CnDictationDiffResult? _lastDiff;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  PoetryUnit? _find(List<PoetryUnit> all) {
    for (final PoetryUnit u in all) {
      if (u.id == widget.unitId) return u;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(poetryCatalogProvider);
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
        return PadScaffold(
          currentDestination: AppNavDestination.reading,
          showContinueLearning: false,
          backgroundColor: JingwayColors.cream,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: <Widget>[
              SegmentedButton<_ReciteMode>(
                segments: const <ButtonSegment<_ReciteMode>>[
                  ButtonSegment(value: _ReciteMode.mask, label: Text('遮挡')),
                  ButtonSegment(
                    value: _ReciteMode.nextLine,
                    label: Text('上下句'),
                  ),
                  ButtonSegment(
                    value: _ReciteMode.dictation,
                    label: Text('默写'),
                  ),
                ],
                selected: <_ReciteMode>{_mode},
                onSelectionChanged: (Set<_ReciteMode> s) {
                  setState(() {
                    _mode = s.first;
                    _lastDiff = null;
                    _input.clear();
                  });
                },
              ),
              const SizedBox(height: 10),
              SegmentedButton<JingwayWritingDirection>(
                segments: const <ButtonSegment<JingwayWritingDirection>>[
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
              const SizedBox(height: 16),
              JingwayBambooSlipFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (_mode == _ReciteMode.mask) ..._buildMask(unit),
                    if (_mode == _ReciteMode.nextLine) ..._buildNextLine(unit),
                    if (_mode == _ReciteMode.dictation) ..._buildDictation(unit),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
