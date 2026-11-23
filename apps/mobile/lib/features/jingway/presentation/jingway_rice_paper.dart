import 'package:flutter/material.dart';

import 'jingway_colors.dart';

/// Full-bleed warm 宣纸 canvas (solid color, no fiber noise).
class JingwayRicePaperBackdrop extends StatelessWidget {
  const JingwayRicePaperBackdrop({
    required this.child,
    this.baseColor = JingwayColors.cream,
    super.key,
  });

  final Widget child;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: baseColor,
      child: SizedBox.expand(child: child),
    );
  }
}

/// Soft rice-paper panel for poetry content.
class JingwayRicePaperPanel extends StatelessWidget {
  const JingwayRicePaperPanel({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 20, 18, 22),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: JingwayColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD6C4A8).withValues(alpha: 0.9),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
