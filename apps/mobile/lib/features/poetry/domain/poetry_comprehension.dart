import 'dart:convert';

import 'package:flutter/services.dart';

/// Reciter「理解性默写」结构：题干含 `$0` `$1`… 占位，答案按序填空。
class PoetryComprehensionItem {
  const PoetryComprehensionItem({
    required this.id,
    required this.poemId,
    required this.title,
    required this.author,
    required this.prompt,
    required this.answers,
  });

  final String id;
  final String poemId;
  final String title;
  final String author;
  final String prompt;
  final List<String> answers;

  factory PoetryComprehensionItem.fromJson(Map<String, dynamic> json) {
    return PoetryComprehensionItem(
      id: json['id'] as String? ?? '',
      poemId: json['poemId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      prompt: json['content'] as String? ?? json['prompt'] as String? ?? '',
      answers: (json['answer'] as List<dynamic>? ??
              json['answers'] as List<dynamic>? ??
              const <dynamic>[])
          .map((dynamic e) {
            if (e is List) return e.map((dynamic x) => '$x').join('/');
            return '$e';
          })
          .toList(growable: false),
    );
  }

  /// 把 `$0` 替换成学生填写（或空方框）。
  String promptWithFills(List<String> fills) {
    String out = prompt;
    for (int i = 0; i < answers.length; i++) {
      final String token = fills.length > i && fills[i].trim().isNotEmpty
          ? fills[i].trim()
          : '______';
      out = out.replaceAll('\$$i', token);
    }
    return out;
  }
}

Future<List<PoetryComprehensionItem>> loadPoetryComprehensions() async {
  final String raw = await rootBundle.loadString(
    'assets/jingway/poetry/comprehensions_core.json',
  );
  final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
  final List<dynamic> items =
      data['comprehensions'] as List<dynamic>? ?? const <dynamic>[];
  return items
      .map(
        (dynamic e) =>
            PoetryComprehensionItem.fromJson(e as Map<String, dynamic>),
      )
      .toList(growable: false);
}

List<PoetryComprehensionItem> comprehensionsForPoem(
  List<PoetryComprehensionItem> all,
  String poemId,
) {
  return all
      .where((PoetryComprehensionItem i) => i.poemId == poemId)
      .toList(growable: false);
}

String _stripNoise(String s) => s.replaceAll(RegExp(r'\s+'), '').replaceAll(
      RegExp('[，。、；：？！（）【】《》…—·,.!?;:\\-"\']'),
      '',
    );

bool acceptsComprehensionAnswers({
  required List<String> expected,
  required List<String> actual,
}) {
  if (expected.length != actual.length) return false;
  for (int i = 0; i < expected.length; i++) {
    final String e = _stripNoise(expected[i]);
    final String a = _stripNoise(actual[i]);
    final List<String> alts = e.split('/');
    if (!alts.contains(a)) return false;
  }
  return true;
}
