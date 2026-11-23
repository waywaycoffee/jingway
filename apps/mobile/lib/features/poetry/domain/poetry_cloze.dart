import 'dart:math';

/// Reciter-style 挖空：以句内连续字为挖空单元（景行自算，不依赖外置题库正文）。
class PoetryClozeItem {
  const PoetryClozeItem({
    required this.lineIndex,
    required this.displayLine,
    required this.blank,
    required this.fullLine,
  });

  final int lineIndex;
  final String displayLine;
  final String blank;
  final String fullLine;
}

List<String> _chars(String line) {
  return line.runes.map(String.fromCharCode).toList(growable: false);
}

/// 从篇目句列生成一组挖空题；[seed] 固定则同一篇可复现。
List<PoetryClozeItem> buildPoetryCloze({
  required List<String> lines,
  int blanksPerPass = 2,
  int? seed,
}) {
  final List<String> usable = <String>[
    for (int i = 0; i < lines.length; i++)
      if (lines[i].trim().isNotEmpty) lines[i],
  ];
  if (usable.isEmpty) return const <PoetryClozeItem>[];

  final Random rng = Random(seed ?? lines.join().hashCode);
  final List<int> indices = List<int>.generate(usable.length, (int i) => i)
    ..shuffle(rng);
  final int take = blanksPerPass.clamp(1, usable.length);
  final List<PoetryClozeItem> out = <PoetryClozeItem>[];

  for (final int li in indices.take(take)) {
    final String line = usable[li];
    final List<String> chars = _chars(line);
    if (chars.length < 2) continue;
    final int blankLen = chars.length <= 3
        ? 1
        : (chars.length / 2).floor().clamp(1, chars.length - 1);
    final int startMax = chars.length - blankLen;
    final int start = startMax <= 0 ? 0 : rng.nextInt(startMax + 1);
    final String blank = chars.sublist(start, start + blankLen).join();
    final String display =
        '${chars.sublist(0, start).join()}'
        '${List<String>.filled(blankLen, '＿').join()}'
        '${chars.sublist(start + blankLen).join()}';
    final int originalIndex = lines.indexOf(line);
    out.add(
      PoetryClozeItem(
        lineIndex: originalIndex < 0 ? li : originalIndex,
        displayLine: display,
        blank: blank,
        fullLine: line,
      ),
    );
  }
  return out;
}

String _stripNoise(String s) => s.replaceAll(RegExp(r'\s+'), '').replaceAll(
      RegExp('[，。、；：？！（）【】《》…—·,.!?;:\\-"\']'),
      '',
    );

bool acceptsPoetryCloze(String expected, String actual) {
  return _stripNoise(actual) == _stripNoise(expected);
}
