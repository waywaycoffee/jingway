import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'jingway_colors.dart';

/// Full-bleed 宣纸 backdrop with visible pulp / fiber texture.
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
          intensity: 1.15,
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

/// Procedural xuan-paper: warm wash + interlocking pulp fibers + flecks.
class JingwayRicePaperPainter extends CustomPainter {
  const JingwayRicePaperPainter({
    this.baseColor = JingwayColors.cream,
    this.intensity = 1,
  });

  final Color baseColor;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = baseColor);

    // Soft warm mottling (云状色斑).
    final _Rng rng = _Rng(
      0x9E3779B9 ^
          size.width.round() * 73856093 ^
          size.height.round() * 19349663,
    );
    final int blotches =
        (12 * intensity).round().clamp(8, 22);
    for (int i = 0; i < blotches; i++) {
      final double cx = rng.next() * size.width;
      final double cy = rng.next() * size.height;
      final double rx = 40 + rng.next() * size.width * 0.28;
      final double ry = 28 + rng.next() * size.height * 0.18;
      final bool warm = rng.next() > 0.45;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx, height: ry),
        Paint()
          ..color = (warm ? const Color(0xFFE8D9B0) : const Color(0xFFDCC9A0))
              .withValues(alpha: 0.10 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    // Edge burn / aged rim.
    final Paint edge = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.45),
        math.max(size.width, size.height) * 0.72,
        <Color>[
          const Color(0x00C4A574),
          const Color(0x14A67C52),
        ],
        <double>[0.55, 1],
      );
    canvas.drawRect(bounds, edge);

    // Interlocking plant fibers (纤维) — short strokes in two dominant angles.
    final int fiberCount =
        (size.width * size.height / 380 * intensity).round().clamp(180, 900);
    final Paint fiberPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < fiberCount; i++) {
      final double x = rng.next() * size.width;
      final double y = rng.next() * size.height;
      final double len = 6 + rng.next() * 28;
      // Mostly horizontal pulp with a secondary diagonal family.
      final double angle = rng.next() < 0.62
          ? (rng.next() - 0.5) * 0.35
          : (math.pi / 2) + (rng.next() - 0.5) * 0.5;
      final double dx = math.cos(angle) * len;
      final double dy = math.sin(angle) * len;
      final bool dark = rng.next() > 0.55;
      fiberPaint
        ..strokeWidth = 0.45 + rng.next() * 1.1
        ..color = (dark ? const Color(0xFF8B7355) : const Color(0xFFFBF6E8))
            .withValues(alpha: (dark ? 0.10 : 0.16) * intensity);
      canvas.drawLine(Offset(x, y), Offset(x + dx, y + dy), fiberPaint);
    }

    // Longer sparse bark-like strands.
    final int longFibers =
        (28 * intensity).round().clamp(16, 48);
    for (int i = 0; i < longFibers; i++) {
      final double x = rng.next() * size.width;
      final double y = rng.next() * size.height;
      final double len = 36 + rng.next() * 70;
      final double angle = (rng.next() - 0.5) * 0.55;
      final Path path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(
          x + math.cos(angle) * len * 0.5 + (rng.next() - 0.5) * 10,
          y + math.sin(angle) * len * 0.5 + (rng.next() - 0.5) * 8,
          x + math.cos(angle) * len,
          y + math.sin(angle) * len,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF7A6145).withValues(alpha: 0.07 * intensity)
          ..strokeWidth = 0.7 + rng.next() * 0.9
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Cotton flecks / pulp dots.
    final int flecks =
        (size.width * size.height / 1400 * intensity).round().clamp(60, 260);
    for (int i = 0; i < flecks; i++) {
      final double x = rng.next() * size.width;
      final double y = rng.next() * size.height;
      final double r = 0.4 + rng.next() * 1.8;
      final bool dark = rng.next() > 0.4;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = (dark ? const Color(0xFF6B5428) : const Color(0xFFFFFBF0))
              .withValues(alpha: (dark ? 0.08 : 0.18) * intensity),
      );
    }

    // Fine cross-hatch veil for paper tooth.
    final Paint veil = Paint()
      ..color = const Color(0xFF9A8160).withValues(alpha: 0.03 * intensity)
      ..strokeWidth = 0.6;
    for (double y = 0; y < size.height; y += 7 + rng.next() * 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 1.5), veil);
    }
    for (double x = 0; x < size.width; x += 9 + rng.next() * 4) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 1.2, size.height),
        veil..color = const Color(0xFFBFA888).withValues(alpha: 0.025 * intensity),
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
