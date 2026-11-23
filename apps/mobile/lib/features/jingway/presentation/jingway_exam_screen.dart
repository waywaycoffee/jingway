import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../authentication/presentation/auth_session.dart';
import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../domain/jingway_practice.dart';
import 'jingway_profile_provider.dart';

class JingwayExamScreen extends ConsumerWidget {
  const JingwayExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(jingwayProfileProvider);
    final auth = ref.watch(authSessionProvider);
    final account = auth.isLoggedIn ? auth.email : 'guest';
    final packs = jingwayPracticePacks
        .where((pack) => pack.grade == profile.grade)
        .toList();

    return PadScaffold(
      currentDestination: AppNavDestination.exam,
      showContinueLearning: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
        children: [
          Text('语文专项', style: Theme.of(context).textTheme.headlineSmall),
          if (packs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('当前年级暂无专项题包。七年级已开放试练。'),
            ),
          for (final pack in packs)
            _PracticeCard(
              key: ValueKey((auth.isLoggedIn, account, pack.id)),
              pack: pack,
              storageKey: auth.isLoggedIn && auth.email.isEmpty
                  ? null
                  : 'jingway_practice:${auth.isLoggedIn ? 'user' : 'local'}:'
                        '$account:${pack.id}',
            ),
        ],
      ),
    );
  }
}

class _PracticeCard extends StatefulWidget {
  const _PracticeCard({
    super.key,
    required this.pack,
    required this.storageKey,
  });

  final JingwayPracticePack pack;
  final String? storageKey;

  @override
  State<_PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends State<_PracticeCard> {
  final _answers = <String, String>{};
  final _lastAnswers = <String, String>{};
  final _wrongCounts = <String, int>{};
  final _submissions = <Map<String, String>>[];
  bool _submitted = false;
  bool _retry = false;
  bool _saving = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final key = widget.storageKey;
    final raw = key == null ? null : Hive.box<String>('prefs').get(key);
    if (raw == null) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _answers.addAll(Map<String, String>.from(data['answers'] as Map));
    _lastAnswers.addAll(Map<String, String>.from(data['lastAnswers'] as Map));
    _wrongCounts.addAll(Map<String, int>.from(data['wrongCounts'] as Map));
    _submissions.addAll(
      (data['submissions'] as List).map(
        (item) => Map<String, String>.from(item as Map),
      ),
    );
    _submitted = data['submitted'] == true;
    _retry = data['retry'] == true;
  }

  Future<void> _save() async {
    final key = widget.storageKey;
    if (key == null) return;
    await Hive.box<String>('prefs').put(
      key,
      jsonEncode({
        'answers': _answers,
        'lastAnswers': _lastAnswers,
        'wrongCounts': _wrongCounts,
        'submissions': _submissions,
        'submitted': _submitted,
        'retry': _retry,
      }),
    );
  }

  Future<void> _update(VoidCallback update) async {
    final answers = Map<String, String>.of(_answers);
    final lastAnswers = Map<String, String>.of(_lastAnswers);
    final wrongCounts = Map<String, int>.of(_wrongCounts);
    final submissionCount = _submissions.length;
    final submitted = _submitted;
    final retry = _retry;

    setState(() {
      _saving = true;
      update();
    });
    try {
      await _save();
    } catch (_) {
      _answers
        ..clear()
        ..addAll(answers);
      _lastAnswers
        ..clear()
        ..addAll(lastAnswers);
      _wrongCounts
        ..clear()
        ..addAll(wrongCounts);
      _submissions.removeRange(submissionCount, _submissions.length);
      _submitted = submitted;
      _retry = retry;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请重试。')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<int> get _wrongIndexes => [
    for (final entry in widget.pack.questions.asMap().entries)
      if (_lastAnswers.containsKey('${entry.key}') &&
          !entry.value.accepts(_lastAnswers['${entry.key}']!))
        entry.key,
  ];

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final wrong = _wrongIndexes;
    final indexes = _retry && !_submitted
        ? wrong
        : _submitted
        ? (_answers.keys.map(int.parse).toList()..sort())
        : List<int>.generate(pack.questions.length, (index) => index);

    return Card(
      child: ExpansionTile(
        title: Text(pack.title),
        subtitle: Text(
          wrong.isEmpty
              ? '${pack.questions.length} 道题'
              : '${wrong.length} 道待订正',
        ),
        maintainState: true,
        onExpansionChanged: (expanded) => setState(() => _expanded = expanded),
        children: [
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pack.material case final material?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SelectableText(material),
                    ),
                  for (final index in indexes) _question(index),
                  if (!_submitted)
                    FilledButton(
                      onPressed:
                          _saving ||
                              indexes.any(
                                (i) => (_answers['$i'] ?? '').trim().isEmpty,
                              )
                          ? null
                          : () => _update(() {
                              _submissions.add(Map.of(_answers));
                              _lastAnswers.addAll(_answers);
                              for (final i in indexes) {
                                if (!pack.questions[i].accepts(
                                  _answers['$i']!,
                                )) {
                                  _wrongCounts.update(
                                    '$i',
                                    (count) => count + 1,
                                    ifAbsent: () => 1,
                                  );
                                }
                              }
                              _submitted = true;
                            }),
                      child: Text(_retry ? '提交订正' : '交卷'),
                    )
                  else ...[
                    Text(wrong.isEmpty ? '本组已完成' : '本组还有 ${wrong.length} 道待订正'),
                    if (wrong.isNotEmpty)
                      FilledButton(
                        onPressed: _saving ? null : () => _start(retry: true),
                        child: const Text('重做错题'),
                      ),
                    OutlinedButton(
                      onPressed: _saving ? null : () => _start(retry: false),
                      child: const Text('再练一组'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _start({required bool retry}) {
    _update(() {
      _retry = retry;
      _submitted = false;
      _answers.clear();
    });
  }

  Widget _question(int index) {
    final id = '$index';
    final question = widget.pack.questions[index];
    final answer = _answers[id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1}. ${question.prompt}'),
          if (_submitted) ...[
            Text(question.accepts(answer!) ? '答对了' : '你的答案：$answer'),
            Text('参考答案：${question.answers.join(' / ')}'),
            Text(question.explanation),
            if (_wrongCounts[id] case final count?) Text('累计答错 $count 次'),
          ] else if (question.options.isEmpty)
            TextFormField(
              key: ValueKey((index, _submissions.length)),
              initialValue: answer,
              readOnly: _saving,
              decoration: const InputDecoration(labelText: '填写答案'),
              onChanged: (value) {
                setState(() => _answers[id] = value);
                _save().catchError((Object _) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('草稿保存失败。')));
                  }
                });
              },
            )
          else
            Wrap(
              spacing: 8,
              children: [
                for (final option in question.options)
                  ChoiceChip(
                    label: Text(option),
                    selected: answer == option,
                    onSelected: _saving
                        ? null
                        : (_) => _update(() => _answers[id] = option),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
