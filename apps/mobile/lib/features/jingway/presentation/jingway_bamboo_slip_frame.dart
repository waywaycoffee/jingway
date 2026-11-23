import 'package:flutter/material.dart';

import 'jingway_colors.dart';

/// Classical writing direction for 古文/诗文.
enum JingwayWritingDirection {
  /// 横排：左 → 右
  horizontalLtr,

  /// 竖排：列从右 → 左，字从上 → 下
  verticalRtl,
}

/// Full-bleed vertical bamboo-slip (竹简) page background.
class JingwayBambooSlipBackdrop extends StatelessWidget {
  const JingwayBambooSlipBackdrop({
    required this.child,
    this.stripWidth = 32,
    super.key,
  });

  final Widget child;
  final double stripWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BambooSlipBackgroundPainter(
        stripWidth: stripWidth,
        washOpacity: 0.22,
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

/// Framed bamboo panel for poetry content (also paints vertical slips).
class JingwayBambooSlipFrame extends StatelessWidget {
  const JingwayBambooSlipFrame({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 20, 18, 22),
    this.stripWidth = 30,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double stripWidth;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: BambooSlipBackgroundPainter(
          stripWidth: stripWidth,
          washOpacity: 0.28,
          drawCords: true,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF6B5428).withValues(alpha: 0.45),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Paints vertical bamboo slips edge-to-edge.
class BambooSlipBackgroundPainter extends CustomPainter {
  const BambooSlipBackgroundPainter({
    required this.stripWidth,
    this.washOpacity = 0.25,
    this.drawCords = true,
  });

  final double stripWidth;
  final double washOpacity;
  final bool drawCords;

  static const Color _bamboo = Color(0xFFC4A574);
  static const Color _bambooDark = Color(0xFF7A5C28);
  static const Color _bambooMid = Color(0xFFA8884A);
  static const Color _bambooLight = Color(0xFFE8D5A8);
  static const Color _gap = Color(0xFF4A3818);
  static const Color _cord = Color(0xFF7C2D12);
  static const Color _node = Color(0xFF5C4318);

  @override
  void paint(Canvas canvas, Size size) {
    // Dark base so gaps between slips read clearly.
    canvas.drawRect(Offset.zero & size, Paint()..color = _gap);

    final double gap = 4;
    final double pitch = stripWidth + gap;
    int i = 0;
    for (double x = -stripWidth * 0.25; x < size.width + pitch; x += pitch, i++) {
      _drawStrip(
        canvas,
        Rect.fromLTWH(x, 0, stripWidth, size.height),
        mirror: i.isOdd,
      );
    }

    if (washOpacity > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = JingwayColors.surface.withValues(alpha: washOpacity),
      );
    }

    if (drawCords) {
      _drawCord(canvas, y: 18, width: size.width);
      _drawCord(canvas, y: size.height - 18, width: size.width);
    }
  }

  void _drawStrip(Canvas canvas, Rect rect, {required bool mirror}) {
    final Paint fill = Paint()
      ..shader = LinearGradient(
        colors: mirror
            ? const <Color>[_bambooLight, _bamboo, _bambooDark]
            : const <Color>[_bambooDark, _bambooMid, _bambooLight],
      ).createShader(rect);

    final RRect slip = RRect.fromRectAndRadius(
      rect.deflate(0.4),
      const Radius.circular(3),
    );
    canvas.drawRRect(slip, fill);

    // Edge bevel for strip separation.
    canvas.drawLine(
      Offset(rect.left + 0.8, rect.top),
      Offset(rect.left + 0.8, rect.bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.2,
    );
    canvas.drawLine(
      Offset(rect.right - 0.8, rect.top),
      Offset(rect.right - 0.8, rect.bottom),
      Paint()
        ..color = _gap.withValues(alpha: 0.55)
        ..strokeWidth = 1.4,
    );

    // Bamboo nodes (节).
    final Paint ring = Paint()
      ..color = _node.withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final Paint ringFill = Paint()..color = _node.withValues(alpha: 0.18);
    for (double y = 36; y < rect.height - 36; y += 52) {
      final Rect band = Rect.fromLTWH(
        rect.left + 1,
        rect.top + y,
        rect.width - 2,
        5,
      );
      canvas.drawRect(band, ringFill);
      canvas
        ..drawLine(
          Offset(rect.left + 1, rect.top + y),
          Offset(rect.right - 1, rect.top + y),
          ring,
        )
        ..drawLine(
          Offset(rect.left + 1, rect.top + y + 5),
          Offset(rect.right - 1, rect.top + y + 5),
          ring,
        );
    }

    // Specular highlight down the slip.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 5, rect.top + 8, 3.2, rect.height - 16),
        const Radius.circular(1.5),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  void _drawCord(Canvas canvas, {required double y, required double width}) {
    final Paint cord = Paint()
      ..color = _cord.withValues(alpha: 0.9)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(6, y)
      ..cubicTo(width * 0.28, y - 4, width * 0.42, y + 5, width * 0.5, y)
      ..cubicTo(width * 0.58, y - 5, width * 0.72, y + 4, width - 6, y);
    canvas.drawPath(path, cord);

    // Binding knots.
    final Paint knot = Paint()..color = _cord;
    for (final double kx in <double>[
      18,
      width * 0.25,
      width * 0.5,
      width * 0.75,
      width - 18,
    ]) {
      canvas.drawCircle(Offset(kx, y), 3.2, knot);
      canvas.drawCircle(
        Offset(kx, y),
        1.4,
        Paint()..color = const Color(0xFFE8D5A8).withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BambooSlipBackgroundPainter oldDelegate) =>
      oldDelegate.stripWidth != stripWidth ||
      oldDelegate.washOpacity != washOpacity ||
      oldDelegate.drawCords != drawCords;
}

/// Renders classical lines in horizontal LTR or vertical RTL layout.
class JingwayClassicalText extends StatelessWidget {
  const JingwayClassicalText({
    required this.lines,
    required this.direction,
    this.style,
    this.title,
    this.meta,
    this.titleStyle,
    this.metaStyle,
    super.key,
  });

  final List<String> lines;
  final JingwayWritingDirection direction;
  final TextStyle? style;
  final String? title;
  final String? meta;
  final TextStyle? titleStyle;
  final TextStyle? metaStyle;

  @override
  Widget build(BuildContext context) {
    final TextStyle body = style ?? jingwayClassicalBodyStyle(context);
    if (direction == JingwayWritingDirection.horizontalLtr) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: titleStyle ?? jingwayClassicalTitleStyle(context),
            ),
            if (meta != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                meta!,
                textAlign: TextAlign.center,
                style: metaStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: JingwayColors.hint,
                        ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          ...lines.map(
            (String line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: body,
              ),
            ),
          ),
        ],
      );
    }

    // Vertical RTL: each poetic line is one column; columns flow right → left.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null) ...<Widget>[
          _VerticalColumn(
            text: title!,
            style: titleStyle ?? jingwayClassicalTitleStyle(context),
            charSize: 28,
          ),
          if (meta != null) ...<Widget>[
            const SizedBox(height: 8),
            _VerticalColumn(
              text: meta!.replaceAll(' · ', ''),
              style: metaStyle ??
                  Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: JingwayColors.hint,
                      ),
              charSize: 13,
            ),
          ],
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: _estimateVerticalHeight(lines, body),
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // visual start on the right
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: <Widget>[
                  for (final String line in lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _VerticalColumn(
                        text: line,
                        style: body,
                        charSize: body.fontSize ?? 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _estimateVerticalHeight(List<String> lines, TextStyle style) {
    final double char = style.fontSize ?? 20;
    final double height = style.height ?? 1.35;
    int maxChars = 1;
    for (final String line in lines) {
      final int n = line.runes.length;
      if (n > maxChars) maxChars = n;
    }
    return maxChars * char * height + 8;
  }
}

class _VerticalColumn extends StatelessWidget {
  const _VerticalColumn({
    required this.text,
    required this.style,
    required this.charSize,
  });

  final String text;
  final TextStyle? style;
  final double charSize;

  @override
  Widget build(BuildContext context) {
    final List<String> chars = text.runes
        .map(String.fromCharCode)
        .where((String c) => c.trim().isNotEmpty || c == '　')
        .toList(growable: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String c in chars)
          SizedBox(
            width: charSize * 1.15,
            height: charSize * (style?.height ?? 1.35),
            child: Center(
              child: Text(
                c,
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

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
        height: 1.55,
      ) ??
      const TextStyle(
        fontSize: 20,
        height: 1.55,
        color: JingwayColors.body,
      );
}
