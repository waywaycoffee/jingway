import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/cn_grade_registry.dart';
import 'jingway_profile_provider.dart';

class JingwayGradeSettingsScreen extends ConsumerWidget {
  const JingwayGradeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? current = ref.watch(jingwayProfileProvider).grade;
    return Scaffold(
      appBar: AppBar(title: const Text('选择年级')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final CnSchoolBand band in CnSchoolBand.values) ...<Widget>[
            Text(
              switch (band) {
                CnSchoolBand.primary => '小学',
                CnSchoolBand.junior => '初中',
                CnSchoolBand.senior => '高中',
              },
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cnGradesForBand(band).map((CnGrade g) {
                final bool selected = current == g.grade;
                return ChoiceChip(
                  label: Text(g.label),
                  selected: selected,
                  onSelected: (_) async {
                    await ref
                        .read(jingwayProfileProvider.notifier)
                        .setGrade(g.grade);
                    if (context.mounted) context.pop();
                  },
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 20),
          ],
          if (kDebugMode)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('研究内容实验室'),
              subtitle: const Text('NCR/CKnowEdit 原型 · 仅 debug'),
              trailing: const Icon(Icons.science_outlined),
              onTap: () => context.push('/settings/research-lab'),
            ),
        ],
      ),
    );
  }
}
