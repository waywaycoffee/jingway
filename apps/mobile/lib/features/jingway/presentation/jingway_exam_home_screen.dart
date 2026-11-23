import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/assets.dart';
import '../../daily_review/data/memory_item_store.dart';
import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../domain/cn_grade_registry.dart';
import 'jingway_colors.dart';
import 'jingway_profile_provider.dart';
import 'xinhua_lookup_sheet.dart';

/// Exam-oriented home: grade-scoped drills and due review entry points.
class JingwayExamHomeScreen extends ConsumerStatefulWidget {
  const JingwayExamHomeScreen({super.key});

  @override
  ConsumerState<JingwayExamHomeScreen> createState() =>
      _JingwayExamHomeScreenState();
}

class _JingwayExamHomeScreenState extends ConsumerState<JingwayExamHomeScreen> {
  final TextEditingController _lookup = TextEditingController();

  @override
  void dispose() {
    _lookup.dispose();
    super.dispose();
  }

  Future<void> _openLookup() async {
    final String term = _lookup.text.trim();
    if (term.isEmpty) return;
    await showXinhuaLookupSheet(context, ref, term: term);
  }

  @override
  Widget build(BuildContext context) {
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
      currentDestination: AppNavDestination.home,
      showContinueLearning: false,
      backgroundColor: JingwayColors.cream,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: <Widget>[
          Column(
            children: <Widget>[
              Image.asset(
                Assets.logo,
                width: 64,
                height: 64,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 12),
              Text(
                '景行语文',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: JingwayColors.title,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '高山仰止，景行行止',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: JingwayColors.slogan,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            grade == null
                ? '尚未选择年级'
                : '当前：${grade.label}${grade.examTrackHint.isEmpty ? '' : ' · ${grade.examTrackHint}'}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: JingwayColors.hint,
                ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/settings/grade'),
              style: TextButton.styleFrom(
                foregroundColor: JingwayColors.accent,
              ),
              child: const Text('更换年级'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lookup,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _openLookup(),
            style: const TextStyle(color: JingwayColors.body),
            decoration: InputDecoration(
              hintText: '查字 / 成语（离线新华）',
              hintStyle: const TextStyle(color: JingwayColors.muted),
              filled: true,
              fillColor: JingwayColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: JingwayColors.section),
                onPressed: _openLookup,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _HomeCard(
            title: '今日复习',
            subtitle: memoryCount > 0
                ? '本年级错字/默写卡 $memoryCount 张，按 FSRS 到期复习'
                : '错字、默写与成语到期卡（按当前年级）',
            action: memoryCount > 0 ? '开始复习 · $memoryCount' : '开始复习',
            onTap: () => context.go('/review'),
          ),
          _HomeCard(
            title: '字词听写',
            subtitle: '生字、形近字、成语专项（内置年级词书）',
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
            title: '阅读',
            subtitle: '导入读物与书架，按篇精读',
            action: '打开书架',
            onTap: () => context.go('/reading'),
          ),
          _HomeCard(
            title: '视频导入',
            subtitle: '导入本地视频与已有字幕（不自动翻译 / 生成字幕）',
            action: '开始导入',
            onTap: () => context.go('/importCourse'),
          ),
          _HomeCard(
            title: '考试专项',
            subtitle: '专项题包筹备中（阅读 / 文言 / 作文将按年级上线）',
            action: '查看说明',
            onTap: () => context.go('/exam'),
          ),
          if (kDebugMode)
            _HomeCard(
              title: '研究内容（内测）',
              subtitle: 'NCR 选择题 / CKnowEdit 填空原型 · 不进正式包',
              action: '打开实验室',
              onTap: () => context.push('/settings/research-lab'),
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
        color: JingwayColors.surface,
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
                const SizedBox(height: 12),
                Text(
                  action,
                  style: const TextStyle(
                    color: JingwayColors.accent,
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
