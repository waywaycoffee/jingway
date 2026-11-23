import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../reading/domain/reading_doc.dart';
import '../../reading/presentation/reading_library_provider.dart';
import '../domain/jingway_practice.dart';
import 'jingway_profile_provider.dart';

/// 课外阅读入口：congcong「读 → 练 → 报告」闭环（正文原创，非教材）。
class JingwayReadingScreen extends ConsumerWidget {
  const JingwayReadingScreen({super.key});

  Future<void> _openStory({
    required BuildContext context,
    required WidgetRef ref,
    required String docId,
    required String title,
    required String packId,
    required String plainText,
  }) async {
    try {
      await ref.read(readingLibraryProvider.notifier).addDoc(
            ReadingDoc(
              id: docId,
              title: title,
              sourceType: ReadingSourceType.catalog,
              sourceLabel: '景行原创',
              plainText: plainText,
            ),
          );
      if (!context.mounted) return;
      final bool? doQuiz = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(title),
          content: const Text(
            '可读全文（点词查新华、可伴读）。读完后做篇后题，交卷可见能力层学习报告。',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('先阅读'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('去篇后题'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (doQuiz == true) {
        context.push('/exam?pack=$packId');
      } else {
        context.push('/reading/$docId');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂时无法打开读物，请重试。')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? grade = ref.watch(jingwayProfileProvider).grade;
    return Scaffold(
      appBar: AppBar(title: const Text('语文阅读')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('课内阅读'),
            subtitle: const Text('按年级浏览教材目录（正文不进包）'),
            onTap: () => context.push('/textbooks'),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('课外阅读 · 读练报告'),
          ),
          if (grade == 3)
            ListTile(
              title: const Text('小蚂蚁搬家'),
              subtitle: const Text('三年级 · 分级故事 + 篇后题'),
              onTap: () {
                final JingwayPracticePack pack = jingwayPracticePacks
                    .firstWhere(
                      (JingwayPracticePack p) =>
                          p.id == jingwayG3StoryPracticeId,
                    );
                _openStory(
                  context: context,
                  ref: ref,
                  docId: jingwayG3StoryDocId,
                  title: pack.title,
                  packId: pack.id,
                  plainText: pack.material!,
                );
              },
            )
          else if (grade == 7)
            ListTile(
              title: const Text('雨中的伞'),
              subtitle: const Text('七年级 · 原创记叙 · 信息提取/推论/整合'),
              onTap: () {
                final JingwayPracticePack pack = jingwayPracticePacks
                    .firstWhere(
                      (JingwayPracticePack p) =>
                          p.id == jingwayReadingPracticeId,
                    );
                _openStory(
                  context: context,
                  ref: ref,
                  docId: jingwayReadingSampleId,
                  title: '雨中的伞',
                  packId: pack.id,
                  plainText: pack.material!,
                );
              },
            )
          else
            const ListTile(title: Text('当前年级的课外读物正在筹备')),
          ListTile(
            title: const Text('我的书架与导入'),
            subtitle: const Text('EPUB/TXT · 点词 · i+1（Mogao 思路）'),
            onTap: () => context.push('/reading'),
          ),
          ListTile(
            title: const Text('古诗文默写'),
            subtitle: const Text('朗读高亮 · 挖空 · 理解默写（SuFei / Reciter）'),
            onTap: () => context.push('/poetry'),
          ),
        ],
      ),
    );
  }
}
