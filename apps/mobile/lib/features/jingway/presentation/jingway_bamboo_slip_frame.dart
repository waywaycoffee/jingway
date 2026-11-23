import 'package:flutter/material.dart';

import 'jingway_colors.dart';

/// Classical writing direction for 古文/诗文.
enum JingwayWritingDirection {
  /// 横排：左 → 右
  horizontalLtr,

  /// 竖排：列从右 → 左，字从上 → 下
  verticalRtl,
}

/// Full vertical bamboo-slip (竹简) background with warm rice-paper fill.
class JingwayBambooSlipFrame extends StatelessWidget {
  const JingwayBambooSlipFrame({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 20, 18, 22),
    this.stripWidth = 28,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double stripWidth;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: _BambooSlipBackgroundPainter(stripWidth: stripWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _BambooSlipBackgroundPainter extends CustomPainter {
  const _BambooSlipBackgroundPainter({required this.stripWidth});

  final double stripWidth;

  static const Color _bamboo = Color(0xFFC9AE7A);
  static const Color _bambooDark = Color(0xFF8B6914);
  static const Color _bambooMid = Color(0xFFB89555);
  static const Color _bambooLight = Color(0xFFE6D4A6);
  static const Color _gap = Color(0xFF6B5428);
  static const Color _cord = Color(0xFF7C2D12);
  static const Color _paperWash = Color(0x66F8F0DA);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = JingwayColors.cream,
    );

    final double pitch = stripWidth + 3;
    int i = 0;
    for (double x = 0; x < size.width + pitch; x += pitch, i++) {
      _drawStrip(
        canvas,
        Rect.fromLTWH(x, 0, stripWidth, size.height),
        mirror: i.isOdd,
      );
      // Gap between slips.
      canvas.drawRect(
        Rect.fromLTWH(x + stripWidth, 0, 3, size.height),
        Paint()..color = _gap.withValues(alpha: 0.35),
      );
    }

    // Soft paper wash so text stays readable.
    canvas.drawRect(Offset.zero & size, Paint()..color = _paperWash);

    _drawCord(canvas, y: 16, width: size.width);
    _drawCord(canvas, y: size.height - 16, width: size.width);
  }

  void _drawStrip(Canvas canvas, Rect rect, {required bool mirror}) {
    final Paint fill = Paint()
      ..shader = LinearGradient(
        colors: mirror
            ? const <Color>[_bambooLight, _bamboo, _bambooDark]
            : const <Color>[_bambooDark, _bambooMid, _bambooLight],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(2)),
      fill,
    );

    final Paint ring = Paint()
      ..color = _bambooDark.withValues(alpha: 0.5)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (double y = 28; y < rect.height - 28; y += 44) {
      canvas
        ..drawLine(
          Offset(rect.left + 1, rect.top + y),
          Offset(rect.right - 1, rect.top + y),
          ring,
        )
        ..drawLine(
          Offset(rect.left + 1, rect.top + y + 2.5),
          Offset(rect.right - 1, rect.top + y + 2.5),
          ring,
        );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + 4, rect.top + 10, 2.5, rect.height - 20),
        const Radius.circular(1),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  void _drawCord(Canvas canvas, {required double y, required double width}) {
    final Paint cord = Paint()
      ..color = _cord.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path path = Path()
      ..moveTo(8, y)
      ..cubicTo(width * 0.28, y - 3, width * 0.42, y + 4, width * 0.5, y)
      ..cubicTo(width * 0.58, y - 4, width * 0.72, y + 3, width - 8, y);
    canvas.drawPath(path, cord);
  }

  @override
  bool shouldRepaint(covariant _BambooSlipBackgroundPainter oldDelegate) =>
      oldDelegate.stripWidth != stripWidth;
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
    final TextStyle body =
        style ?? jingwayClassicalBodyStyle(context);
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
        .map((int r) => String.fromCharCode(r))
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
