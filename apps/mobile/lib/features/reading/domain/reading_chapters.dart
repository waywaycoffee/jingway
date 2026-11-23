/// One chapter (or whole-book fallback) inside a flattened reading document.
class ReadingChapter {
  const ReadingChapter({
    required this.index,
    required this.title,
    required this.start,
    required this.end,
    required this.bodyStart,
    required this.body,
  });

  final int index;
  final String title;

  /// Inclusive start offset of the chapter block (usually the heading).
  final int start;

  /// Exclusive end offset in the full [plainText].
  final int end;

  /// Inclusive start of [body] inside the full [plainText].
  final int bodyStart;

  /// Body without the heading line when heading was stripped into [title].
  final String body;

  int get length => end - start;
}

final RegExp _chapterHeading = RegExp(
  r'^\s*(?:'
  r'＃＃＃\s+(.+)'
  r'|#{1,3}\s+(.+)'
  r'|第[零〇一二三四五六七八九十百千万两0-9]+[章节回部卷集篇].{0,40}'
  r'|Chapter\s+\d+[.:：\s].{0,40}'
  r'|CHAPTER\s+\d+[.:：\s].{0,40}'
  r')\s*$',
);

/// Detect novel / ebook chapters from flattened plain text.
///
/// EPUB import inserts `＃＃＃ title` between spine files. TXT novels often use
/// `第N章` / `Chapter N`. If nothing matches, returns a single「全文」chapter.
List<ReadingChapter> detectReadingChapters(String plainText) {
  final String text = plainText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  if (text.trim().isEmpty) {
    return const <ReadingChapter>[
      ReadingChapter(
        index: 0,
        title: '全文',
        start: 0,
        end: 0,
        bodyStart: 0,
        body: '',
      ),
    ];
  }

  final List<({int start, String title})> heads = <({int start, String title})>[];
  int lineStart = 0;
  final List<String> lines = text.split('\n');
  for (final String line in lines) {
    final RegExpMatch? m = _chapterHeading.firstMatch(line);
    if (m != null) {
      String title = (m.group(1) ?? m.group(2) ?? line).trim();
      title = title.replaceFirst(RegExp(r'^＃＃＃\s*'), '');
      if (title.isEmpty) title = '未命名章节';
      // Avoid treating very long lines as headings.
      if (line.trim().length <= 48) {
        heads.add((start: lineStart, title: title));
      }
    }
    lineStart += line.length + 1;
  }

  if (heads.length < 2) {
    return <ReadingChapter>[
      ReadingChapter(
        index: 0,
        title: heads.isEmpty ? '全文' : heads.first.title,
        start: 0,
        end: text.length,
        bodyStart: 0,
        body: text,
      ),
    ];
  }

  final List<ReadingChapter> out = <ReadingChapter>[];
  for (int i = 0; i < heads.length; i++) {
    final int start = heads[i].start;
    final int end = i + 1 < heads.length ? heads[i + 1].start : text.length;
    final String slice = text.substring(start, end);
    final int nl = slice.indexOf('\n');
    if (nl < 0) {
      out.add(
        ReadingChapter(
          index: i,
          title: heads[i].title,
          start: start,
          end: end,
          bodyStart: start,
          body: slice.trim(),
        ),
      );
      continue;
    }
    int bodyStart = start + nl + 1;
    while (bodyStart < end &&
        (text[bodyStart] == ' ' ||
            text[bodyStart] == '\t' ||
            text[bodyStart] == '\n')) {
      bodyStart += 1;
    }
    final String body = text.substring(bodyStart, end);
    out.add(
      ReadingChapter(
        index: i,
        title: heads[i].title,
        start: start,
        end: end,
        bodyStart: bodyStart,
        body: body,
      ),
    );
  }
  return out;
}

int chapterIndexForOffset(List<ReadingChapter> chapters, int offset) {
  if (chapters.isEmpty) return 0;
  final int o = offset.clamp(0, chapters.last.end);
  for (int i = chapters.length - 1; i >= 0; i--) {
    if (o >= chapters[i].start) return i;
  }
  return 0;
}

double readingGlobalPercent({
  required List<ReadingChapter> chapters,
  required int chapterIndex,
  required double localPercent,
}) {
  if (chapters.isEmpty) return localPercent.clamp(0.0, 1.0);
  final int total = chapters.last.end;
  if (total <= 0) return 1.0;
  final ReadingChapter ch =
      chapters[chapterIndex.clamp(0, chapters.length - 1)];
  final double local = localPercent.clamp(0.0, 1.0);
  final double global = (ch.start + local * ch.length) / total;
  return global.clamp(0.0, 1.0);
}

class ReadingSearchHit {
  const ReadingSearchHit({
    required this.offset,
    required this.chapterIndex,
    required this.snippet,
  });

  final int offset;
  final int chapterIndex;
  final String snippet;
}

/// Case-insensitive search over full text; returns up to [limit] hits.
List<ReadingSearchHit> searchReadingText({
  required String plainText,
  required String query,
  required List<ReadingChapter> chapters,
  int limit = 50,
}) {
  final String q = query.trim();
  if (q.isEmpty || plainText.isEmpty) return const <ReadingSearchHit>[];
  final String hay = plainText.toLowerCase();
  final String needle = q.toLowerCase();
  final List<ReadingSearchHit> out = <ReadingSearchHit>[];
  int from = 0;
  while (out.length < limit) {
    final int at = hay.indexOf(needle, from);
    if (at < 0) break;
    final int snippetStart = (at - 16).clamp(0, plainText.length);
    final int snippetEnd = (at + needle.length + 24).clamp(0, plainText.length);
    out.add(
      ReadingSearchHit(
        offset: at,
        chapterIndex: chapterIndexForOffset(chapters, at),
        snippet: plainText.substring(snippetStart, snippetEnd).replaceAll('\n', ' '),
      ),
    );
    from = at + needle.length;
  }
  return out;
}
