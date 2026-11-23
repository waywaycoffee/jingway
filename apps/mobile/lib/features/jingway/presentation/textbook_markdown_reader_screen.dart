import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../../shared/presentation/pad/pad_top_bar.dart';
import '../domain/textbook_models.dart';
import 'jingway_colors.dart';
import 'textbook_hub_provider.dart';

/// Fetches yuwen OCR markdown on demand and shows a plain reader.
class TextbookMarkdownReaderScreen extends ConsumerStatefulWidget {
  const TextbookMarkdownReaderScreen({required this.item, super.key});

  final TextbookItem item;

  @override
  ConsumerState<TextbookMarkdownReaderScreen> createState() =>
      _TextbookMarkdownReaderScreenState();
}

class _TextbookMarkdownReaderScreenState
    extends ConsumerState<TextbookMarkdownReaderScreen> {
  late final Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(textbookDownloadServiceProvider).fetchText(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    return PadScaffold(
      currentDestination: AppNavDestination.textbooks,
      showContinueLearning: false,
      backgroundColor: JingwayColors.cream,
      topBar: PadTopBar(
        title: widget.item.title,
        description: widget.item.subtitle,
        leading: PadBackButton(onPressed: () => context.pop()),
      ),
      body: FutureBuilder<String>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<String> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '加载失败：${snap.error}\n\n可稍后重试，或检查网络 / 镜像。',
                style: const TextStyle(color: JingwayColors.body, height: 1.5),
              ),
            );
          }
          final String text = snap.data ?? '';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: JingwayColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: JingwayColors.chipBorder),
                ),
                child: const Text(
                  '版权归原作者/出版社；来源 hantang/yuwen（OCR）。仅供个人学习，景行不内置正文。',
                  style: TextStyle(
                    fontSize: 12,
                    color: JingwayColors.hint,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                _stripFrontMatter(text),
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.7,
                  color: JingwayColors.body,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _stripFrontMatter(String raw) {
    final String t = raw.trimLeft();
    if (!t.startsWith('---')) return raw;
    final int end = t.indexOf('\n---', 3);
    if (end < 0) return raw;
    return t.substring(end + 4).trimLeft();
  }
}
