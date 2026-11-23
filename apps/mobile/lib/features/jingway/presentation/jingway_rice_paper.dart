import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'jingway_colors.dart';

/// Full-bleed 宣纸 backdrop with rough pulp-fiber texture only.
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
    return CustomPaint(
      painter: JingwayRicePaperPainter(baseColor: baseColor),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: JingwayRicePaperPainter(
          baseColor: JingwayColors.surface,
          intensity: 1.1,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD6C4A8).withValues(alpha: 0.9),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Procedural xuan-paper: warm base + tangled rough fibers only.
class JingwayRicePaperPainter extends CustomPainter {
  const JingwayRicePaperPainter({
    this.baseColor = JingwayColors.cream,
    this.intensity = 1,
  });

  final Color baseColor;
  final double intensity;

  static const Color _fiberDark = Color(0xFF8A7355);
  static const Color _fiberMid = Color(0xFFA89070);
  static const Color _fiberLight = Color(0xFFF7F0DC);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    final _Rng rng = _Rng(
      0xC0FFEE ^
          size.width.round() * 73856093 ^
          size.height.round() * 19349663,
    );

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Dense short pulp fibers — mostly near-horizontal, some vertical tangle.
    final int shortCount =
        (size.width * size.height / 220 * intensity).round().clamp(320, 1400);
    for (int i = 0; i < shortCount; i++) {
      final double x = rng.next() * size.width;
      final double y = rng.next() * size.height;
      final double len = 4 + rng.next() * 22;
      final double angle = rng.next() < 0.7
          ? (rng.next() - 0.5) * 0.55
          : math.pi / 2 + (rng.next() - 0.5) * 0.7;
      final int tone = (rng.next() * 3).floor();
      final Color base = tone == 0
          ? _fiberDark
          : tone == 1
              ? _fiberMid
              : _fiberLight;
      final double alpha = tone == 2
          ? 0.22 * intensity
          : (0.09 + rng.next() * 0.08) * intensity;
      stroke
        ..strokeWidth = 0.55 + rng.next() * 1.35
        ..color = base.withValues(alpha: alpha);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        stroke,
      );
    }

    // Longer wavy strands for coarse paper tooth.
    final int longCount =
        (size.width * size.height / 5200 * intensity).round().clamp(40, 120);
    for (int i = 0; i < longCount; i++) {
      final double x = rng.next() * size.width;
      final double y = rng.next() * size.height;
      final double len = 28 + rng.next() * 64;
      final double angle = (rng.next() - 0.5) * 0.65;
      final double wobble = (rng.next() - 0.5) * 14;
      final Path path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + math.cos(angle) * len * 0.5 + wobble,
          y + math.sin(angle) * len * 0.5 + (rng.next() - 0.5) * 10,
          x + math.cos(angle) * len,
          y + math.sin(angle) * len,
        );
      stroke
        ..strokeWidth = 0.7 + rng.next() * 1.2
        ..color = _fiberDark.withValues(
          alpha: (0.07 + rng.next() * 0.06) * intensity,
        );
      canvas.drawPath(path, stroke);
    }

    // Sparse crossing fibers (斜向交织) for roughness.
    final int crossCount =
        (size.width * size.height / 900 * intensity).round().clamp(80, 320);
    for (int i = 0; i < crossCount; i++) {
      final double x = rng.next() * size.width;
      final double y = rng.next() * size.height;
      final double len = 8 + rng.next() * 18;
      final double angle = math.pi / 4 + (rng.next() - 0.5) * 0.9;
      stroke
        ..strokeWidth = 0.5 + rng.next() * 0.9
        ..color = _fiberMid.withValues(
          alpha: (0.08 + rng.next() * 0.05) * intensity,
        );
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant JingwayRicePaperPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.intensity != intensity;
}

class _Rng {
  _Rng(int seed) : _state = seed == 0 ? 1 : seed;

  int _state;

  double next() {
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}
