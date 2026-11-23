import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import 'jingway_colors.dart';

/// Chinese exam specialty placeholder — not the CEFR English exam hub.
class JingwayExamStubScreen extends StatelessWidget {
  const JingwayExamStubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PadScaffold(
      currentDestination: AppNavDestination.exam,
      showContinueLearning: false,
      backgroundColor: JingwayColors.cream,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
        children: <Widget>[
          Text(
            '考试专项',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: JingwayColors.title,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '专项题包筹备中',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: JingwayColors.accent,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            '语文阅读理解、文言文、作文等专项练习将按年级陆续上线。'
            '现阶段请先用备考主页、古诗文默写与字词复习。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: JingwayColors.hint,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.go('/home'),
            style: FilledButton.styleFrom(
              backgroundColor: JingwayColors.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('返回备考主页'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/poetry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: JingwayColors.accent,
            ),
            child: const Text('去诗文默写'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => context.go('/review'),
            style: OutlinedButton.styleFrom(
              foregroundColor: JingwayColors.accent,
            ),
            child: const Text('去字词复习'),
          ),
        ],
      ),
    );
  }
}
