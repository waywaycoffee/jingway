import 'package:flutter/material.dart';

import 'jingway_colors.dart';

/// Classical writing direction for 古文/诗文.
enum JingwayWritingDirection {
  /// 横排：左 → 右
  horizontalLtr,

  /// 竖排：列从右 → 左，字从上 → 下
  verticalRtl,
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
    this.highlightLineIndex,
    super.key,
  });

  final List<String> lines;
  final JingwayWritingDirection direction;
  final TextStyle? style;
  final String? title;
  final String? meta;
  final TextStyle? titleStyle;
  final TextStyle? metaStyle;

  /// SuFei-style TTS 逐句高亮（可选）。
  final int? highlightLineIndex;

  @override
  Widget build(BuildContext context) {
    final TextStyle body = style ?? jingwayClassicalBodyStyle(context);
    final TextStyle hi = body.copyWith(
      color: JingwayColors.accentStrong,
      backgroundColor: JingwayColors.accent.withValues(alpha: 0.12),
      fontWeight: FontWeight.w700,
    );
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
          for (int i = 0; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                lines[i],
                textAlign: TextAlign.center,
                style: highlightLineIndex == i ? hi : body,
              ),
            ),
        ],
      );
    }

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
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: <Widget>[
                  for (int i = 0; i < lines.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DecoratedBox(
                        decoration: highlightLineIndex == i
                            ? BoxDecoration(
                                color: JingwayColors.accent.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              )
                            : const BoxDecoration(),
                        child: _VerticalColumn(
                          text: lines[i],
                          style: highlightLineIndex == i ? hi : body,
                          charSize: body.fontSize ?? 20,
                        ),
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
