import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../jingway/presentation/jingway_classical_text.dart';
import '../../jingway/presentation/jingway_colors.dart';
import '../../jingway/presentation/jingway_profile_provider.dart';
import '../../jingway/presentation/jingway_rice_paper.dart';
import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';

class PoetryUnit {
  const PoetryUnit({
    required this.id,
    required this.title,
    required this.author,
    required this.dynasty,
    required this.lines,
    required this.grades,
  });

  final String id;
  final String title;
  final String author;
  final String dynasty;
  final List<String> lines;
  final List<int> grades;

  factory PoetryUnit.fromJson(Map<String, dynamic> json) {
    return PoetryUnit(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      dynasty: json['dynasty'] as String? ?? '',
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => '$e')
          .toList(growable: false),
      grades: (json['grades'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => (e as num).toInt())
          .toList(growable: false),
    );
  }
}

final poetryCatalogProvider =
    FutureProvider.autoDispose<List<PoetryUnit>>((Ref ref) async {
  final String raw =
      await rootBundle.loadString('assets/jingway/poetry/exam_core.json');
  final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
  final List<dynamic> items = data['items'] as List<dynamic>? ?? const [];
  return items
      .map((dynamic e) => PoetryUnit.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
});

class PoetryCatalogScreen extends ConsumerWidget {
  const PoetryCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? grade = ref.watch(jingwayProfileProvider).grade;
    final async = ref.watch(poetryCatalogProvider);

    return PadScaffold(
      currentDestination: AppNavDestination.reading,
      showContinueLearning: false,
      backgroundColor: JingwayColors.cream,
      body: JingwayRicePaperBackdrop(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) =>
              Center(child: Text('加载失败：$e')),
          data: (List<PoetryUnit> all) {
            final List<PoetryUnit> items = grade == null
                ? all
                : all
                    .where((PoetryUnit u) => u.grades.contains(grade))
                    .toList(growable: false);
            if (items.isEmpty) {
              return const Center(child: Text('当前年级暂无必背篇目'));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              itemCount: items.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int i) {
                if (i == 0) {
                  return Text(
                    '古诗文 · ${grade == null ? '全部' : '$grade 年级'}',
                    style: jingwayClassicalTitleStyle(context).copyWith(
                      fontSize: 26,
                    ),
                  );
                }
                final PoetryUnit u = items[i - 1];
                return JingwayRicePaperPanel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(
                      u.title,
                      style: const TextStyle(
                        color: JingwayColors.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${u.dynasty} · ${u.author}',
                      style: const TextStyle(color: JingwayColors.hint),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: JingwayColors.section,
                    ),
                    onTap: () => context.push('/poetry/${u.id}'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
