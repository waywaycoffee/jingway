import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import 'jingway_colors.dart';

/// Soft landing when an AcquireEnglish-only route is opened on Jingway.
class JingwayUnavailableScreen extends StatelessWidget {
  const JingwayUnavailableScreen({
    this.title = '暂未开放',
    this.message = '景行语文当前不提供该英语能力入口，请返回备考主页继续学习。',
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return PadScaffold(
      currentDestination: AppNavDestination.home,
      showContinueLearning: false,
      backgroundColor: JingwayColors.cream,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: JingwayColors.title,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
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
          ],
        ),
      ),
    );
  }
}
