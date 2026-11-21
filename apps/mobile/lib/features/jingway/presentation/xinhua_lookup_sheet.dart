import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/xinhua_dictionary.dart';

Future<void> showXinhuaLookupSheet(
  BuildContext context,
  WidgetRef ref, {
  required String term,
}) async {
  final XinhuaEntry? entry =
      await ref.read(xinhuaDictionaryProvider).lookup(term);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (BuildContext context) {
      if (entry == null) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Text('未收录：「$term」'),
        );
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              entry.term,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              switch (entry.kind) {
                'idiom' => '成语',
                'word' => '词语',
                _ => '汉字',
              },
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF78716C),
                  ),
            ),
            if (entry.pinyin.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                entry.pinyin,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF9A3412),
                    ),
              ),
            ],
            const SizedBox(height: 10),
            Text(entry.gloss, style: Theme.of(context).textTheme.bodyLarge),
            if (entry.radical.isNotEmpty || entry.strokes > 0) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                [
                  if (entry.radical.isNotEmpty) '部首 ${entry.radical}',
                  if (entry.strokes > 0) '${entry.strokes} 画',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF78716C),
                    ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
