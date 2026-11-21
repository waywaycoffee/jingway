import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/app_design_tokens.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../domain/cn_grade_registry.dart';
import 'jingway_profile_provider.dart';

/// Exam-oriented home: grade-scoped drills and due review entry points.
class JingwayExamHomeScreen extends ConsumerWidget {
  const JingwayExamHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(jingwayProfileProvider);
    final CnGrade? grade = profile.cnGrade;

    return PadScaffold(
      currentDestination: AppNavDestination.home,
      showContinueLearning: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: <Widget>[
          Text(
            '景行语文',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            grade == null
                ? '尚未选择年级'
                : '当前：${grade.label}${grade.examTrackHint.isEmpty ? '' : ' · ${grade.examTrackHint}'}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF57534E),
                ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/settings/grade'),
              child: const Text('更换年级'),
            ),
          ),
          const SizedBox(height: 16),
          _HomeCard(
            title: '今日复习',
            subtitle: '错字、默写与成语到期卡（按当前年级）',
            action: '开始复习',
            onTap: () => context.go('/review'),
          ),
          _HomeCard(
            title: '字词听写',
            subtitle: '生字、形近字、成语专项',
            action: '进入词书',
            onTap: () => context.go('/words/syllabus'),
          ),
          _HomeCard(
            title: '古诗文默写',
            subtitle: '年级必背：遮挡背诵 · 上下句 · 逐字默写',
            action: '打开诗文',
            onTap: () => context.go('/poetry'),
          ),
          _HomeCard(
            title: '考试专项',
            subtitle: '练习与错题本骨架（内容按年级过滤）',
            action: '进入专项',
            onTap: () => context.go('/exam'),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppDesignTokens.appWhite,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF78716C),
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  action,
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
