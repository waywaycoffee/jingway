import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../daily_review/data/memory_item_store.dart';
import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../domain/cn_grade_registry.dart';
import 'jingway_colors.dart';
import 'jingway_profile_provider.dart';

/// Chinese review hub for Jingway bottom-nav「复习」.
///
/// Replaces the AcquireEnglish ReviewHubScreen (背单词) entry so prod never
/// lands on English vocab volume UX from this tab.
class JingwayReviewHubScreen extends ConsumerWidget {
  const JingwayReviewHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(jingwayProfileProvider);
    final CnGrade? grade = profile.cnGrade;
    final int gradeNum = grade?.grade ?? -1;
    final int memoryCount = ref.watch(
      memoryItemStoreProvider.select(
        (items) => items
            .where((m) => gradeNum < 0 || m.grade == gradeNum)
            .length,
      ),
    );

    return PadScaffold(
      currentDestination: AppNavDestination.review,
      showContinueLearning: false,
      backgroundColor: JingwayColors.cream,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: <Widget>[
          Text(
            '字词复习',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: JingwayColors.title,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '错字、默写与成语到期卡（按当前年级）',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: JingwayColors.hint,
                ),
          ),
          if (grade != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              '当前：${grade.label}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: JingwayColors.muted,
                  ),
            ),
          ],
          const SizedBox(height: 20),
          _PrimaryCta(
            title: memoryCount > 0 ? '开始今日复习 · $memoryCount' : '开始今日复习',
            subtitle: memoryCount > 0
                ? '本年级错字/默写卡 $memoryCount 张，按 FSRS 到期复习'
                : '进入到期队列，巩固错字与默写',
            onTap: () => context.push('/review/session'),
          ),
          const SizedBox(height: 22),
          Text(
            '更多练习',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: JingwayColors.section,
                ),
          ),
          const SizedBox(height: 10),
          _SecondaryCard(
            title: '字词听写',
            subtitle: '生字、形近字、成语专项（内置年级词书）',
            onTap: () => context.go('/words/syllabus'),
          ),
          _SecondaryCard(
            title: '诗文默写',
            subtitle: '年级必背：遮挡背诵 · 上下句 · 逐字默写',
            onTap: () => context.go('/poetry'),
          ),
          _SecondaryCard(
            title: '考试专项',
            subtitle: '专项题包筹备中',
            onTap: () => context.go('/exam'),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: JingwayColors.accent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  const _SecondaryCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: JingwayColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: JingwayColors.title,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: JingwayColors.hint,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: JingwayColors.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
