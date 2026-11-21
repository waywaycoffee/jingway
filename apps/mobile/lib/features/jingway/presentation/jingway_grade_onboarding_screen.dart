import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';

import '../../onboarding/presentation/onboarding_provider.dart';
import '../../shared/presentation/pad/app_design_tokens.dart';
import '../domain/cn_grade_registry.dart';
import 'jingway_profile_provider.dart';

/// First-open: pick K12 grade before any training surface.
class JingwayGradeOnboardingScreen extends ConsumerStatefulWidget {
  const JingwayGradeOnboardingScreen({super.key});

  @override
  ConsumerState<JingwayGradeOnboardingScreen> createState() =>
      _JingwayGradeOnboardingScreenState();
}

class _JingwayGradeOnboardingScreenState
    extends ConsumerState<JingwayGradeOnboardingScreen> {
  int? _grade;
  bool _saving = false;

  Future<void> _finish() async {
    final int? grade = _grade;
    if (grade == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(jingwayProfileProvider.notifier)
          .completeOnboarding(grade: grade);
      if (Hive.isBoxOpen('prefs')) {
        await Hive.box<String>('prefs').put(kOnboardingCompleteKey, '1');
      }
      if (!mounted) return;
      context.go('/home');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '景行语文',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1C1917),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '先选年级，我们会匹配对应的字词、古诗文与练习。',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF57534E),
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    _BandSection(
                      title: '小学',
                      grades: cnGradesForBand(CnSchoolBand.primary),
                      selected: _grade,
                      onSelect: (int g) => setState(() => _grade = g),
                    ),
                    const SizedBox(height: 20),
                    _BandSection(
                      title: '初中',
                      grades: cnGradesForBand(CnSchoolBand.junior),
                      selected: _grade,
                      onSelect: (int g) => setState(() => _grade = g),
                    ),
                    const SizedBox(height: 20),
                    _BandSection(
                      title: '高中（内容陆续开放）',
                      grades: cnGradesForBand(CnSchoolBand.senior),
                      selected: _grade,
                      onSelect: (int g) => setState(() => _grade = g),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _grade == null || _saving ? null : _finish,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9A3412),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_saving ? '保存中…' : '开始备考'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BandSection extends StatelessWidget {
  const _BandSection({
    required this.title,
    required this.grades,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<CnGrade> grades;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: grades.map((CnGrade g) {
            final bool active = selected == g.grade;
            return ChoiceChip(
              label: Text(
                g.examTrackHint.isEmpty
                    ? g.label
                    : '${g.label} · ${g.examTrackHint}',
              ),
              selected: active,
              onSelected: (_) => onSelect(g.grade),
              selectedColor: const Color(0xFFFDBA74),
              backgroundColor: AppDesignTokens.appWhite,
              labelStyle: TextStyle(
                color: active ? const Color(0xFF7C2D12) : const Color(0xFF44403C),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: active
                      ? const Color(0xFFEA580C)
                      : const Color(0xFFE7E5E4),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}
