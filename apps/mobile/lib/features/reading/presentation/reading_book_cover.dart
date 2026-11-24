import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../flavors/app_flavor.dart';

/// 立体书封面（爱快英语书架同款视觉：书脊 + 页边 + 封面厚度阴影）。
class ReadingBookCover extends StatelessWidget {
  const ReadingBookCover({
    required this.title,
    this.level = '',
    this.compact = false,
    super.key,
  });

  final String title;
  final String level;
  final bool compact;

  static const List<Color> _palette = <Color>[
    Color(0xFF315B50),
    Color(0xFF66455F),
    Color(0xFFAD6842),
    Color(0xFF384F74),
    Color(0xFF77623C),
    Color(0xFF5C4033),
    Color(0xFF2F4F4F),
  ];

  @override
  Widget build(BuildContext context) {
    final int seed =
        title.runes.fold<int>(0, (int value, int rune) => value + rune);
    final Color color = _palette[seed % _palette.length];
    final Color spine = Color.lerp(color, Colors.black, 0.28)!;
    final Color highlight = Color.lerp(color, Colors.white, 0.18)!;
    final bool jingway = FlavorConfig.isJingwayProduct;
    final String eyebrow =
        level.isNotEmpty ? level : (jingway ? '语文' : 'ENGLISH');
    final String brand = jingway ? '景行阅读' : 'ACQUIRE READING';

    return AspectRatio(
      aspectRatio: compact ? 0.72 : 0.68,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;
          final double depth = (w * 0.09).clamp(7.0, 14.0);
          final double pageW = (w * 0.055).clamp(4.0, 9.0);
          return CustomPaint(
            painter: _BookShadowPainter(depth: depth),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Page block (right edge) — white leaf stack.
                Positioned(
                  right: 0,
                  top: h * 0.025,
                  bottom: h * 0.02,
                  width: pageW + depth * 0.35,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(2),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: <Color>[
                          Color(0xFFF4EFE6),
                          Color(0xFFFFFCF7),
                          Color(0xFFE8E0D4),
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: CustomPaint(painter: _PageLinesPainter()),
                  ),
                ),
                // Spine (left thickness).
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: depth,
                  child: Transform(
                    alignment: Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateY(-0.55),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(3),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: <Color>[
                            Color.lerp(spine, Colors.black, 0.2)!,
                            spine,
                            highlight.withValues(alpha: 0.85),
                          ],
                          stops: const <double>[0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Front cover face.
                Positioned(
                  left: depth * 0.55,
                  right: pageW,
                  top: 0,
                  bottom: depth * 0.15,
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(-0.08),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            highlight,
                            color,
                            Color.lerp(color, Colors.black, 0.18)!,
                          ],
                          stops: const <double>[0.0, 0.45, 1.0],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: Offset(depth * 0.4, depth * 0.55),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Stack(
                        children: <Widget>[
                          // Soft light strip on cover.
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Colors.white.withValues(alpha: 0.22),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 8 : 11,
                              compact ? 8 : 11,
                              compact ? 8 : 10,
                              compact ? 8 : 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  eyebrow,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: compact ? 9 : 10,
                                    letterSpacing: 0.4,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  title,
                                  maxLines: compact ? 3 : 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: jingway ? null : 'Georgia',
                                    fontSize: compact ? 14 : 16,
                                    height: 1.22,
                                    fontWeight: FontWeight.w700,
                                    shadows: const <Shadow>[
                                      Shadow(
                                        color: Color(0x66000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: compact ? 8 : 10),
                                Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.35),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  brand,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 8,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BookShadowPainter extends CustomPainter {
  _BookShadowPainter({required this.depth});

  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(depth * 0.6, size.height * 0.92)
      ..lineTo(size.width * 0.92, size.height * 0.92)
      ..lineTo(size.width * 0.98, size.height)
      ..lineTo(depth * 0.3, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _BookShadowPainter oldDelegate) =>
      oldDelegate.depth != depth;
}

class _PageLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFD9D0C3)
      ..strokeWidth = 0.8;
    final int lines = math.max(6, (size.height / 7).floor());
    for (int i = 1; i < lines; i++) {
      final double y = size.height * (i / lines);
      canvas.drawLine(Offset(0.5, y), Offset(size.width - 0.5, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
