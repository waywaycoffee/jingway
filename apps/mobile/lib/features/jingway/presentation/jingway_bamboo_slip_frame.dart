import 'package:flutter/material.dart';

import 'jingway_colors.dart';

/// Decorative bamboo-slip (竹简) frame for classical Chinese text.
///
/// Draws vertical bamboo strips on left/right with cord bindings; content sits
/// on warm rice-paper fill. Does not load image assets.
class JingwayBambooSlipFrame extends StatelessWidget {
  const JingwayBambooSlipFrame({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(28, 24, 28, 28),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BambooSlipPainter(),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _BambooSlipPainter extends CustomPainter {
  const _BambooSlipPainter();

  static const Color _bamboo = Color(0xFFC4A574);
  static const Color _bambooDark = Color(0xFF8B6914);
  static const Color _bambooLight = Color(0xFFE8D5A8);
  static const Color _cord = Color(0xFF7C2D12);
  static const Color _paper = JingwayColors.cream;
  static const Color _paperEdge = Color(0xFFE0D2B8);

  @override
  void paint(Canvas canvas, Size size) {
    final RRect paper = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 10, size.width - 36, size.height - 20),
      const Radius.circular(6),
    );
    final Paint paperPaint = Paint()..color = _paper;
    canvas.drawRRect(paper, paperPaint);
    canvas.drawRRect(
      paper,
      Paint()
        ..color = _paperEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _drawStripColumn(canvas, x: 4, height: size.height, left: true);
    _drawStripColumn(
      canvas,
      x: size.width - 22,
      height: size.height,
      left: false,
    );

    // Binding cords near top & bottom.
    _drawCord(canvas, y: 28, width: size.width);
    _drawCord(canvas, y: size.height - 28, width: size.width);
  }

  void _drawStripColumn(
    Canvas canvas, {
    required double x,
    required double height,
    required bool left,
  }) {
    const double stripW = 16;
    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: left
            ? <Color>[_bambooDark, _bambooLight, _bamboo]
            : <Color>[_bamboo, _bambooLight, _bambooDark],
      ).createShader(Rect.fromLTWH(x, 0, stripW, height));
    final RRect strip = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, 8, stripW, height - 16),
      const Radius.circular(3),
    );
    canvas.drawRRect(strip, fill);

    // Node rings along the bamboo.
    final Paint ring = Paint()
      ..color = _bambooDark.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double y = 36; y < height - 36; y += 48) {
      canvas.drawLine(Offset(x + 1, y), Offset(x + stripW - 1, y), ring);
      canvas.drawLine(
        Offset(x + 1, y + 3),
        Offset(x + stripW - 1, y + 3),
        ring,
      );
    }

    // Soft highlight.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 3, 14, 3, height - 28),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  void _drawCord(Canvas canvas, {required double y, required double width}) {
    final Paint cord = Paint()
      ..color = _cord
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(14, y)
      ..cubicTo(width * 0.25, y - 4, width * 0.4, y + 5, width * 0.5, y)
      ..cubicTo(width * 0.6, y - 5, width * 0.75, y + 4, width - 14, y);
    canvas.drawPath(path, cord);

    // Knot dots on the bamboo edges.
    final Paint knot = Paint()..color = _cord;
    canvas.drawCircle(Offset(12, y), 3.2, knot);
    canvas.drawCircle(Offset(width - 12, y), 3.2, knot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Title style helper for classical pieces (calligraphy feel when font available).
TextStyle jingwayClassicalTitleStyle(BuildContext context) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontFamily: 'ZhiMangXing',
        fontFamilyFallback: const <String>[
          'Xingkai SC',
          'STXingkai',
          'KaiTi',
          'STKaiti',
        ],
        fontWeight: FontWeight.w500,
        color: JingwayColors.title,
        height: 1.25,
      ) ??
      const TextStyle(
        fontSize: 28,
        color: JingwayColors.title,
        fontFamilyFallback: <String>['Xingkai SC', 'STXingkai', 'KaiTi'],
      );
}

TextStyle jingwayClassicalBodyStyle(BuildContext context) {
  return Theme.of(context).textTheme.titleLarge?.copyWith(
        fontFamily: 'Noto Serif SC',
        fontFamilyFallback: const <String>['Songti SC', 'STSong', 'serif'],
        color: JingwayColors.body,
        height: 1.7,
      ) ??
      const TextStyle(
        fontSize: 20,
        height: 1.7,
        color: JingwayColors.body,
      );
}
