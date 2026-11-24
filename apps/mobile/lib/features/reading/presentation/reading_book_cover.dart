import 'package:flutter/material.dart';

import '../../../flavors/app_flavor.dart';

/// Stable title-based cover for built-in and imported books.
/// Visual language matches AcquireEnglish bookshelf (spine + serif title).
class ReadingBookCover extends StatelessWidget {
  const ReadingBookCover({required this.title, this.level = '', super.key});
  final String title;
  final String level;

  @override
  Widget build(BuildContext context) {
    const List<Color> palette = <Color>[
      Color(0xFF315B50),
      Color(0xFF66455F),
      Color(0xFFAD6842),
      Color(0xFF384F74),
      Color(0xFF77623C),
    ];
    final int seed =
        title.runes.fold<int>(0, (int value, int rune) => value + rune);
    final Color color = palette[seed % palette.length];
    final bool jingway = FlavorConfig.isJingwayProduct;
    final String eyebrow = level.isNotEmpty
        ? level
        : (jingway ? '语文' : 'ENGLISH');
    final String brand = jingway ? 'JINGWAY READING' : 'ACQUIRE READING';
    return AspectRatio(
      aspectRatio: 0.68,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x30000000),
              blurRadius: 8,
              offset: Offset(3, 4),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(7, 0, 0, 0),
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0x44FFFFFF))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                eyebrow,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: jingway ? null : 'Georgia',
                  fontSize: jingway ? 16 : 17,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white54),
              Text(
                brand,
                style: const TextStyle(color: Colors.white70, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
