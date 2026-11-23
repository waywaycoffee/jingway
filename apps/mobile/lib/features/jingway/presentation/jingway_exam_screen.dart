import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../authentication/presentation/auth_session.dart';
import '../../daily_review/domain/daily_review.dart';
import '../../daily_review/domain/memory_item.dart';
import '../../daily_review/presentation/daily_review_provider.dart';
import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../domain/jingway_practice.dart';
import 'jingway_profile_provider.dart';

class JingwayExamScreen extends ConsumerStatefulWidget {
  const JingwayExamScreen({super.key, this.packId});

  final String? packId;

  @override
  ConsumerState<JingwayExamScreen> createState() => _JingwayExamScreenState();
}

class _JingwayExamScreenState extends ConsumerState<JingwayExamScreen> {
  bool _wrongOnly = false;

  @override
  Widget build(BuildContext context) {
    final String? packId = widget.packId;
    final profile = ref.watch(jingwayProfileProvider);
    final auth = ref.watch(authSessionProvider);
    final account = auth.isLoggedIn ? auth.email : 'guest';
    final packs = jingwayPracticePacks
        .where(
          (pack) =>
              pack.grade == profile.grade &&
              (packId == null || pack.id == packId),
        )
        .toList();

    return PadScaffold(
      currentDestination: AppNavDestination.exam,
      showContinueLearning: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
        children: [
          Text('语文专项', style: Theme.of(context).textTheme.headlineSmall),
          if (packId == null && packs.isNotEmpty)
            SwitchListTile(
              title: const Text('错题本'),
              subtitle: const Text('只显示有待订正错题的题组'),
              value: _wrongOnly,
              onChanged: (value) => setState(() => _wrongOnly = value),
            ),
          if (packs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('当前年级暂无对应专项题包。三、七、八年级已开放部分试练。'),
            ),
          for (final pack in packs)
            _PracticeCard(
              key: ValueKey((auth.isLoggedIn, account, pack.id)),
              pack: pack,
              wrongOnly: _wrongOnly,
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

class _PracticeCard extends ConsumerStatefulWidget {
  const _PracticeCard({
    super.key,
    required this.pack,
    required this.storageKey,
    required this.wrongOnly,
  });

  final JingwayPracticePack pack;
  final String? storageKey;
  final bool wrongOnly;

  @override
  ConsumerState<_PracticeCard> createState() => _PracticeCardState();
}

class _PracticeCardState extends ConsumerState<_PracticeCard> {
  final _answers = <String, String>{};
  final _lastAnswers = <String, String>{};
  final _wrongCounts = <String, int>{};
  final _submissions = <Map<String, String>>[];
  final Map<String, String> _notes = {};
  final Map<String, String> _verification = {};
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
    _notes.addAll(Map<String, String>.from(data['notes'] as Map? ?? {}));
    _verification.addAll(
      Map<String, String>.from(data['verification'] as Map? ?? {}),
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
        'notes': _notes,
        'verification': _verification,
        'retry': _retry,
      }),
    );
  }

  Future<void> _update(VoidCallback update) async {
    if (_saving) return;
    final answers = Map<String, String>.of(_answers);
    final lastAnswers = Map<String, String>.of(_lastAnswers);
    final wrongCounts = Map<String, int>.of(_wrongCounts);
    final submissionCount = _submissions.length;
    final verification = Map<String, String>.of(_verification);
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
      _verification
        ..clear()
        ..addAll(verification);
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

  String get _practiceSummary {
    int correct = 0;
    int total = 0;
    for (final submission in _submissions) {
      for (final entry in submission.entries) {
        total++;
        if (widget.pack.questions[int.parse(entry.key)].accepts(entry.value))
          correct++;
      }
    }
    final int checked = _verification.values
        .where((value) => value == 'pass')
        .length;
    return total == 0 ? '尚未作答' : '累计答对 $correct / $total · $checked 题已通过订正验证';
  }

  @override
  Widget build(BuildContext context) {
    final pack = widget.pack;
    final wrong = _wrongIndexes;
    if (widget.wrongOnly && wrong.isEmpty && !_expanded)
      return const SizedBox.shrink();
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
                  if (pack.method case final method?)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('解题方法'),
                      subtitle: Text(method),
                    ),
                  if (pack.material case final material?)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SelectableText(material),
                    ),
                  Text(_practiceSummary),
                  for (final index in indexes) _question(index),
                  for (final entry in _verification.entries)
                    if (entry.value == 'pending')
                      _verificationQuestion(int.parse(entry.key)),
                  if (widget.wrongOnly &&
                      !_submitted &&
                      !_retry &&
                      wrong.isNotEmpty)
                    OutlinedButton(
                      onPressed: _saving || _answers.isNotEmpty
                          ? null
                          : () => _start(retry: true),
                      child: const Text('重做错题'),
                    ),
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
                                  _verification.remove('$i');
                                  _wrongCounts.update(
                                    '$i',
                                    (count) => count + 1,
                                    ifAbsent: () => 1,
                                  );
                                } else if (_retry &&
                                    i <
                                        (jingwayVerificationItems[pack.id]
                                                ?.length ??
                                            0)) {
                                  _verification['$i'] = 'pending';
                                }
                              }
                              _submitted = true;
                            }),
                      child: Text(_retry ? '提交订正' : '交卷'),
                    )
                  else ...[
                    _SessionReport(
                      pack: pack,
                      lastAnswers: _lastAnswers,
                      wrongIndexes: wrong,
                    ),
                    Text(wrong.isEmpty ? '本组已完成' : '本组还有 ${wrong.length} 道待订正'),
                    if (wrong.isNotEmpty)
                      FilledButton(
                        onPressed: _saving ? null : () => _start(retry: true),
                        child: const Text('重做错题'),
                      ),
                    OutlinedButton(
                      onPressed:
                          _saving || _verification.containsValue('pending')
                          ? null
                          : () => _start(retry: false),
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

  Widget _verificationQuestion(int index) {
    final JingwayPracticeQuestion question =
        jingwayVerificationItems[widget.pack.id]![index];
    return _VerificationQuestion(
      key: ValueKey(index),
      question: question,
      saving: _saving,
      onAnswer: (String? answer) => _update(() {
        _verification['$index'] = answer == null
            ? 'skipped'
            : question.accepts(answer)
            ? 'pass'
            : 'fail';
      }),
    );
  }

  Future<void> _addToReview(int index) async {
    final JingwayPracticePack pack = widget.pack;
    final JingwayPracticeQuestion question = pack.questions[index];
    try {
      await ref
          .read(dailyReviewProvider.notifier)
          .ingestMemoryItem(
            MemoryItem(
              key: 'g${pack.grade}:practice:${pack.id}:$index',
              grade: pack.grade,
              kind: ReviewKind.sentence,
              question: question.prompt,
              answer: question.answers.first,
              english: question.answers.first,
              chinese: question.explanation,
              sourceLabel: pack.title,
              origin: 'jingway_practice',
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已加入知识复习')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂时无法加入知识复习，请重试。')));
      }
    }
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
          if (question.skill case final skill?)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                skill,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          Text('${index + 1}. ${question.prompt}'),
          if (_submitted) ...[
            Text(question.accepts(answer!) ? '答对了' : '你的答案：$answer'),
            Text('参考答案：${question.answers.join(' / ')}'),
            Text(question.explanation),
            if (widget.pack.material == null && _wrongCounts.containsKey(id))
              TextButton(
                onPressed: () => _addToReview(index),
                child: const Text('加入知识复习'),
              ),
            if (_wrongCounts[id] case final count?) ...[
              Text('累计答错 $count 次'),
              TextFormField(
                key: ValueKey(('note', id)),
                initialValue: _notes[id],
                readOnly: _saving,
                decoration: const InputDecoration(labelText: '记录错因'),
                onChanged: (String note) {
                  _notes[id] = note;
                  _save().catchError((Object _) {
                    if (mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('错因保存失败')));
                  });
                },
              ),
            ],
            if (_verification[id] == 'pass') const Text('订正验证通过'),
            if (_verification[id] == 'fail') const Text('订正验证未通过'),
            if (_verification[id] == 'skipped') const Text('本次订正未验证'),
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

/// congcong-school 式交卷小结：正确率 + 能力层对错分布。
class _SessionReport extends StatelessWidget {
  const _SessionReport({
    required this.pack,
    required this.lastAnswers,
    required this.wrongIndexes,
  });

  final JingwayPracticePack pack;
  final Map<String, String> lastAnswers;
  final List<int> wrongIndexes;

  @override
  Widget build(BuildContext context) {
    final int total = lastAnswers.length;
    if (total == 0) return const SizedBox.shrink();
    final int wrong = wrongIndexes.length;
    final int right = total - wrong;
    final Map<String, int> skillRight = <String, int>{};
    final Map<String, int> skillTotal = <String, int>{};
    for (final MapEntry<String, String> e in lastAnswers.entries) {
      final int i = int.tryParse(e.key) ?? -1;
      if (i < 0 || i >= pack.questions.length) continue;
      final String skill = pack.questions[i].skill ?? '未标注';
      skillTotal[skill] = (skillTotal[skill] ?? 0) + 1;
      if (pack.questions[i].accepts(e.value)) {
        skillRight[skill] = (skillRight[skill] ?? 0) + 1;
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('学习报告', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '本组成绩：$right / $total 正确'
              '${wrong == 0 ? '' : ' · $wrong 道待订正'}',
            ),
            if (skillTotal.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              for (final MapEntry<String, int> e in skillTotal.entries)
                Text(
                  '${e.key}：${skillRight[e.key] ?? 0}/${e.value}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerificationQuestion extends StatefulWidget {
  const _VerificationQuestion({
    super.key,
    required this.question,
    required this.saving,
    required this.onAnswer,
  });
  final JingwayPracticeQuestion question;
  final bool saving;
  final ValueChanged<String?> onAnswer;

  @override
  State<_VerificationQuestion> createState() => _VerificationQuestionState();
}

class _VerificationQuestionState extends State<_VerificationQuestion> {
  String _answer = '';

  @override
  Widget build(BuildContext context) {
    final JingwayPracticeQuestion question = widget.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('订正验证'),
        Text(question.prompt),
        if (question.options.isEmpty)
          TextField(
            readOnly: widget.saving,
            onChanged: (String value) => setState(() => _answer = value),
          )
        else
          Wrap(
            spacing: 8,
            children: [
              for (final String option in question.options)
                ChoiceChip(
                  label: Text(option),
                  selected: _answer == option,
                  onSelected: widget.saving
                      ? null
                      : (_) => setState(() => _answer = option),
                ),
            ],
          ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: widget.saving || _answer.trim().isEmpty
                  ? null
                  : () => widget.onAnswer(_answer),
              child: const Text('提交验证'),
            ),
            TextButton(
              onPressed: widget.saving
                  ? null
                  : () async {
                      final bool? skip = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('跳过验证？'),
                          content: const Text('本次订正将记为未验证。'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('继续验证'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('跳过'),
                            ),
                          ],
                        ),
                      );
                      if (mounted && skip == true) widget.onAnswer(null);
                    },
              child: const Text('跳过'),
            ),
          ],
        ),
      ],
    );
  }
}
