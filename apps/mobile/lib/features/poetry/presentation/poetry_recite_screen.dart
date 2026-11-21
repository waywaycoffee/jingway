import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            children: <Widget>[
              Text(
                unit.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                '${unit.dynasty} · ${unit.author}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              if (_mode == _ReciteMode.mask) ..._buildMask(unit),
              if (_mode == _ReciteMode.nextLine) ..._buildNextLine(unit),
              if (_mode == _ReciteMode.dictation) ..._buildDictation(unit),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildMask(PoetryUnit unit) {
    return <Widget>[
      Row(
        children: <Widget>[
          ChoiceChip(
            label: const Text('首字提示'),
            selected: _maskLevel == 1,
            onSelected: (_) => setState(() => _maskLevel = 1),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('完全遮挡'),
            selected: _maskLevel == 2,
            onSelected: (_) => setState(() => _maskLevel = 2),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_maskLevel == 0)
        ...unit.lines.map(
          (String line) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(line, style: Theme.of(context).textTheme.titleMedium),
          ),
        )
      else
        ...unit.lines.map((String line) {
          final String shown = _maskLevel == 2
              ? List<String>.filled(line.runes.length, '＿').join()
              : (line.isEmpty
                  ? ''
                  : '${String.fromCharCode(line.runes.first)}${List<String>.filled(line.runes.length - 1, '＿').join()}');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(shown, style: Theme.of(context).textTheme.titleLarge),
          );
        }),
      TextButton(
        onPressed: () => setState(() => _maskLevel = 0),
        child: const Text('显示全文'),
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
      Text('上句', style: Theme.of(context).textTheme.labelLarge),
      Text(prompt, style: Theme.of(context).textTheme.headlineSmall),
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
      const Text('默写全文（标点可省略）'),
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
        onPressed: () {
          setState(() {
            _lastDiff =
                diffCnDictation(expected: expected, actual: _input.text);
          });
        },
        child: const Text('提交默写'),
      ),
      if (_lastDiff != null) ...<Widget>[
        const SizedBox(height: 12),
        Text(
          _lastDiff!.exact
              ? '全部正确'
              : '错/缺字：${_lastDiff!.reviewChars.join('、')}',
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
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              color: bg,
              child: Text(label),
            );
          }).toList(growable: false),
        ),
      ],
    ];
  }
}
