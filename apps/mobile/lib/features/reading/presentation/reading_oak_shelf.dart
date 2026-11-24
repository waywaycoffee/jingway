import 'package:flutter/material.dart';

/// 橡木书架横板：书籍立于其上，复用爱快英语书架氛围。
class ReadingOakShelfBay extends StatelessWidget {
  const ReadingOakShelfBay({
    required this.children,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(10, 14, 10, 0),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF5C3A22),
              Color(0xFF3E2616),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: CustomPaint(painter: _OakGrainPainter())),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Recessed shelf cavity.
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    padding: padding,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          const Color(0xFF2A1A10).withValues(alpha: 0.55),
                          const Color(0xFF1A100A).withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        for (int i = 0; i < children.length; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: children[i]),
                        ],
                      ],
                    ),
                  ),
                  // Oak plank under books.
                  const _OakPlank(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OakPlank extends StatelessWidget {
  const _OakPlank();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFE6C897),
                  Color(0xFFC9965A),
                  Color(0xFF9A6A3A),
                ],
                stops: <double>[0.0, 0.45, 1.0],
              ),
            ),
          ),
          const CustomPaint(painter: _OakGrainPainter(light: true)),
          // Front lip highlight.
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
          // Underside shadow.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OakGrainPainter extends CustomPainter {
  const _OakGrainPainter({this.light = false});

  final bool light;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = light ? 1.1 : 1.4
      ..color = light
          ? const Color(0x66A56B35)
          : const Color(0x33E8C9A0);
    for (double y = 6; y < size.height; y += light ? 5.5 : 9) {
      final Path path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 18) {
        path.quadraticBezierTo(
          x + 6,
          y + ((x ~/ 18).isEven ? 1.8 : -1.6),
          x + 18,
          y,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OakGrainPainter oldDelegate) =>
      oldDelegate.light != light;
}

/// Cream paper canvas used behind the oak shelf (Acquire Reading).
const Color kReadingShelfCanvas = Color(0xFFF7F3E9);
const Color kReadingShelfInk = Color(0xFF243F36);
