import 'dart:convert';
import 'dart:typed_data';

import 'package:common_learn_english/features/jingway/data/xinhua_dictionary.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String seed = '''
{
  "version": 2,
  "source": "test",
  "entries": {
    "霜": { "pinyin": "shuāng", "gloss": "冰晶", "radical": "雨", "strokes": 17 }
  },
  "words": {
    "故乡": { "pinyin": "gù xiāng", "gloss": "家乡" }
  },
  "idioms": {
    "守株待兔": { "pinyin": "shǒu zhū dài tù", "gloss": "死守经验" }
  }
}
''';

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      final String key = const StringCodec().decodeMessage(message)!;
      if (key == 'assets/jingway/dict/xinhua_seed.json') {
        return ByteData.sublistView(Uint8List.fromList(utf8.encode(seed)));
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('lookup prefers idiom then char', () async {
    final XinhuaDictionary dict = XinhuaDictionary();
    expect((await dict.lookup('霜'))?.gloss, '冰晶');
    expect((await dict.lookup('故乡'))?.kind, 'word');
    expect((await dict.lookup('守株待兔'))?.kind, 'idiom');
    expect((await dict.lookup('霜花'))?.term, '霜');
  });

  test('suggest finds prefix idioms', () async {
    final XinhuaDictionary dict = XinhuaDictionary();
    final hits = await dict.suggest('守');
    expect(hits.any((e) => e.term == '守株待兔'), isTrue);
  });
}
