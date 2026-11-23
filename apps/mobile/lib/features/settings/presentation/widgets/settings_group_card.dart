import 'package:flutter/material.dart';

import '../../../../flavors/app_flavor.dart';
import '../../../jingway/presentation/jingway_colors.dart';
import '../../../shared/presentation/pad/app_design_tokens.dart';
import '../../../shared/presentation/pad/pad_compact.dart';

class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    required this.title,
    required this.icon,
    required this.children,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bool compact = context.isPadCompact;
    final bool jingway = FlavorConfig.isJingwayProduct;
    final Color accent =
        jingway ? JingwayColors.accentStrong : AppDesignTokens.brandGreenDark;
    final Color card =
        jingway ? JingwayColors.surface : AppDesignTokens.appWhite;
    final Color border =
        jingway ? JingwayColors.chipBorder : AppDesignTokens.borderGray;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: compact ? 16 : 18, color: accent),
            SizedBox(width: compact ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 12),
        // Material (not DecoratedBox) so ListTile ink/background paint correctly.
        Material(
          color: card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            side: BorderSide(color: border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
