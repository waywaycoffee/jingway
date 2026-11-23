import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:go_router/go_router.dart';

import '../../authentication/presentation/auth_session.dart';
import '../../sync/data/acquire_api_client.dart';
import '../../writing/domain/writing_models.dart';
import 'jingway_profile_provider.dart';

const String _title = '那一次，我学会了等待';
const String _prompt =
    '写一件自己经历的事，交代起因、经过和结果，'
    '用动作或对话表现等待时的心情变化。不少于 400 字。';
const String _rubric = 'jingway_g7_narrative_v1';
const String _argumentRubric = 'jingway_argument_v1';
const String _argumentTitle = '课间要不要多到室外活动？';
const String _argumentPrompt =
    '明确提出自己的观点，给出至少一条相关理由及具体例子，'
    '回应一种不同意见。不少于 400 字。';

class JingwayWritingScreen extends ConsumerWidget {
  const JingwayWritingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? grade = ref.watch(jingwayProfileProvider).grade;
    final AuthSessionState auth = ref.watch(authSessionProvider);
    final String? scope = auth.isLoggedIn
        ? (auth.email.isEmpty ? null : 'user:${auth.email}')
        : 'guest';
    final bool argumentative = grade == 8 || grade == 9;
    final String rubric = argumentative ? _argumentRubric : _rubric;
    return Scaffold(
      appBar: AppBar(title: const Text('作文训练')),
      body: (grade == 7 || argumentative) && scope != null
          ? _WritingForm(
              key: ValueKey((grade, scope)),
              storageKey: grade == 9 ? '$rubric:g9:$scope' : '$rubric:$scope',
              argumentative: argumentative,
              grade: grade!,
            )
          : Center(child: Text(scope == null ? '请重新登录后开始训练' : '当前年级暂无作文训练')),
    );
  }
}

class _WritingForm extends ConsumerStatefulWidget {
  const _WritingForm({
    super.key,
    required this.storageKey,
    required this.argumentative,
    required this.grade,
  });
  final String storageKey;
  final bool argumentative;
  final int grade;

  @override
  ConsumerState<_WritingForm> createState() => _WritingFormState();
}

class _WritingFormState extends ConsumerState<_WritingForm> {
  final TextEditingController _text = TextEditingController();
  final TextEditingController _exercise = TextEditingController();
  final List<Map<String, dynamic>> _versions = [];
  final TextEditingController _claim = TextEditingController();
  final TextEditingController _evidence = TextEditingController();
  bool _busy = false;

  String get _taskTitle => widget.argumentative ? _argumentTitle : _title;
  String get _taskPrompt => widget.argumentative ? _argumentPrompt : _prompt;
  String get _taskRubric => widget.argumentative ? _argumentRubric : _rubric;

  Box<String> get _prefs => Hive.box<String>('prefs');

  @override
  void initState() {
    super.initState();
    final String? raw = _prefs.get(widget.storageKey);
    if (raw == null) return;
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    _text.text = data['draft'] as String? ?? '';
    _claim.text = data['claim'] as String? ?? '';
    _evidence.text = data['evidence'] as String? ?? '';
    _exercise.text = data['exercise'] as String? ?? '';
    _versions.addAll((data['versions'] as List).cast<Map<String, dynamic>>());
  }

  @override
  void dispose() {
    _text.dispose();
    _exercise.dispose();
    _claim.dispose();
    _evidence.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _prefs.put(
      widget.storageKey,
      jsonEncode({
        'draft': _text.text,
        'claim': _claim.text,
        'evidence': _evidence.text,
        'exercise': _exercise.text,
        'versions': _versions,
      }),
    );
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _grade() async {
    final String body = _text.text.trim();
    if (_busy || body.isEmpty) return;
    if (!ref.read(authSessionProvider).isLoggedIn) {
      _notice('请登录后使用云端作文批改。');
      return;
    }
    final int previous = _versions.indexWhere(
      (version) => version['body'] == body,
    );
    if (previous >= 0 && _versions[previous]['source'] == 'llm') {
      _notice('这份稿件已有批改结果。修改正文后可重新提交。');
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提交作文批改'),
        content: const Text('作文正文将发送到云端批改服务，请先删去姓名、学校等个人信息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('提交'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _busy) return;
    setState(() => _busy = true);
    try {
      final WritingGradeResult result = await ref
          .read(acquireApiClientProvider)
          .gradeWriting(
            text: body,
            prompt: widget.argumentative
                ? '${widget.grade} 年级。$_taskPrompt'
                : _taskPrompt,
            title: _taskTitle,
            rubric: _taskRubric,
          );
      if (!mounted) return;
      if (result.rubric != _taskRubric) {
        _notice('当前服务尚未启用语文作文批改。');
        return;
      }
      final Map<String, dynamic> record = {
        'body': body,
        'source': result.source,
        'summary': result.summary,
        'issues': [
          for (final WritingIssue issue in result.issues)
            {
              'type': issue.type,
              'excerpt': body.contains(issue.excerpt) ? issue.excerpt : '',
              'suggestion': issue.suggestion,
            },
        ],
      };
      final Map<String, dynamic>? old = previous < 0
          ? null
          : _versions[previous];
      if (previous < 0) {
        _versions.add(record);
      } else {
        _versions[previous] = record;
      }
      try {
        await _save();
      } catch (_) {
        if (old == null) {
          _versions.removeLast();
        } else {
          _versions[previous] = old;
        }
        rethrow;
      }
    } catch (_) {
      _notice('批改暂时不可用，请稍后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (widget.argumentative) ...[
        const ExpansionTile(
          title: Text('技巧课：论点、论据和论证'),
          children: [
            ListTile(
              title: Text('判断理由是否支持观点'),
              subtitle: Text(
                '观点是「课间应多到室外活动」。可以先用「长时间坐着后需要舒展身体」作理由，再举出课间活动的具体例子。最后回应天气不适合时怎么办。',
              ),
            ),
          ],
        ),
        if (widget.grade == 8)
          TextButton(
            onPressed: () => context.push('/exam?pack=g8-logic-v1'),
            child: const Text('先做思辨微练'),
          ),
        TextField(
          controller: _claim,
          readOnly: _busy,
          decoration: const InputDecoration(labelText: '提纲 · 我的论点'),
          onChanged: (_) => _save().catchError((Object _) => _notice('提纲保存失败')),
        ),
        TextField(
          controller: _evidence,
          readOnly: _busy,
          decoration: const InputDecoration(labelText: '提纲 · 我的理由与例子'),
          onChanged: (_) => _save().catchError((Object _) => _notice('提纲保存失败')),
        ),
      ] else
        const ExpansionTile(
          title: Text('技巧课：用动作表现心情'),
          children: [
            ListTile(
              title: Text('改写示例'),
              subtitle: Text(
                '「我很着急」可以改成「我踮起脚，朝拐角望了第三次」。'
                '用一个能观察到的动作替代抽象形容词。',
              ),
            ),
          ],
        ),
      TextField(
        controller: _exercise,
        readOnly: _busy,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: '片段练习',
          helperText: widget.argumentative ? '写一句回应不同意见的话。' : '用一个动作写出你等人时的心情。',
        ),
        onChanged: (_) => _save().catchError((Object _) => _notice('草稿保存失败')),
      ),
      const SizedBox(height: 20),
      Text(_taskTitle, style: Theme.of(context).textTheme.titleLarge),
      Text(_taskPrompt),
      TextField(
        controller: _text,
        readOnly: _busy,
        maxLength: 20000,
        maxLines: 10,
        decoration: const InputDecoration(labelText: '整篇作文草稿'),
        onChanged: (_) => _save().catchError((Object _) => _notice('草稿保存失败')),
      ),
      FilledButton(
        onPressed: _busy ? null : _grade,
        child: Text(_busy ? '正在批改…' : '提交批改'),
      ),
      for (final entry in _versions.asMap().entries.toList().reversed)
        ExpansionTile(
          title: Text('第 ${entry.key + 1} 稿批改'),
          subtitle: Text(entry.value['summary'] as String),
          children: [
            ListTile(
              title: const Text('提交稿'),
              subtitle: SelectableText(entry.value['body'] as String),
            ),
            if (entry.key > 0)
              ListTile(
                title: Text('对照第 ${entry.key} 稿'),
                subtitle: SelectableText(
                  _versions[entry.key - 1]['body'] as String,
                ),
              ),
            for (final Map<String, dynamic> issue
                in (entry.value['issues'] as List<dynamic>)
                    .cast<Map<String, dynamic>>())
              ListTile(
                title: Text(issue['type'] as String),
                subtitle: Text(
                  [
                    if ((issue['excerpt'] as String).isNotEmpty)
                      '原文：${issue['excerpt']}',
                    issue['suggestion'] as String,
                  ].join('\n'),
                ),
              ),
          ],
        ),
    ],
  );
}
