import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/theme_logic.dart';
import '../../../../flavors/app_flavor.dart';
import '../../../jingway/presentation/jingway_colors.dart';
import '../../../shared/presentation/pad/app_design_tokens.dart';

class ThemeWidget extends ConsumerWidget {
  const ThemeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool jingway = FlavorConfig.isJingwayProduct;
    final ThemeMode mode = ref.watch(themeLogicProvider).themeMode;
    final ThemeMode selected =
        mode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark;

    final Color titleColor =
        jingway ? JingwayColors.title : AppDesignTokens.textPrimary;
    final Color hintColor =
        jingway ? JingwayColors.hint : AppDesignTokens.textSecondary;
    final Color selectedBg =
        jingway ? JingwayColors.chipSelectedFill : AppDesignTokens.softGray;
    final Color selectedFg =
        jingway ? Colors.white : AppDesignTokens.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '界面主题',
          style: TextStyle(fontWeight: FontWeight.w800, color: titleColor),
        ),
        const SizedBox(height: 4),
        Text(
          jingway ? '默认宣纸浅色；也可切换深色。' : '默认深色；可切换为浅色。',
          style: TextStyle(fontSize: 13, color: hintColor),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith<Color>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return selectedFg;
              }
              return hintColor;
            }),
            backgroundColor: WidgetStateProperty.resolveWith<Color>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return selectedBg;
              }
              return Colors.transparent;
            }),
          ),
          selected: <ThemeMode>{selected},
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_rounded, size: 18),
              label: Text('深色'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_rounded, size: 18),
              label: Text('浅色'),
            ),
          ],
          onSelectionChanged: (Set<ThemeMode> next) {
            ref.read(themeLogicProvider.notifier).setThemeMode(next.first);
          },
        ),
      ],
    );
  }
}
