import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../navigation/presentation/navigation_destination.dart';
import '../../shared/presentation/pad/pad_scaffold.dart';
import '../../shared/presentation/pad/pad_top_bar.dart';
import '../../../utils/url_utils.dart';
import '../domain/textbook_models.dart';
import 'jingway_colors.dart';
import 'textbook_hub_provider.dart';
import 'textbook_markdown_reader_screen.dart';

/// 「教材」hub: ChinaTextbook PDF / yuwen OCR / dianzi-keben index.
class JingwayTextbookHubScreen extends ConsumerStatefulWidget {
  const JingwayTextbookHubScreen({super.key});

  @override
  ConsumerState<JingwayTextbookHubScreen> createState() =>
      _JingwayTextbookHubScreenState();
}

class _JingwayTextbookHubScreenState
    extends ConsumerState<JingwayTextbookHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _busyId;
  String _busyLabel = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openPdf(TextbookItem item, {required bool download}) async {
    setState(() {
      _busyId = item.id;
      _busyLabel = download ? '下载中…' : '打开中…';
    });
    try {
      if (!download) {
        final String url = item.remoteUrl.isNotEmpty
            ? item.remoteUrl
            : (item.githubUrl.isNotEmpty
                  ? item.githubUrl
                  : (item.mirrors.isNotEmpty ? item.mirrors.first : ''));
        if (url.isEmpty) throw StateError('无可用链接');
        final bool ok = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) throw StateError('无法打开链接');
        return;
      }
      final File file = await ref
          .read(textbookDownloadServiceProvider)
          .downloadToDocuments(item, ext: 'pdf');
      final OpenResult result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已下载到本机，打开结果：${result.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('失败：$e')));
    } finally {
      if (mounted) {
        setState(() {
          _busyId = null;
          _busyLabel = '';
        });
      }
    }
  }

  Future<void> _openMarkdown(TextbookItem item) async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TextbookMarkdownReaderScreen(item: item),
      ),
    );
  }

  Future<void> _openDianzi(TextbookItem item) async {
    if (item.links.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无外链')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: <Widget>[
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: JingwayColors.title,
                ),
              ),
              if (item.password != null && item.password!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.key_rounded),
                  title: Text('提取码 ${item.password}'),
                  subtitle: const Text('点击复制'),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: item.password!));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('提取码已复制')),
                      );
                    }
                  },
                ),
              ],
              const SizedBox(height: 4),
              Text(
                item.note.isNotEmpty
                    ? item.note
                    : '版权归原出版社/教育部；仅供个人学习；景行不内置正文。',
                style: const TextStyle(fontSize: 12, color: JingwayColors.hint),
              ),
              const SizedBox(height: 8),
              for (final TextbookLink link in item.links)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    link.kind == 'platform'
                        ? Icons.school_outlined
                        : link.kind == 'netdisk'
                        ? Icons.cloud_outlined
                        : Icons.link,
                  ),
                  title: Text(link.label),
                  subtitle: Text(
                    link.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    unawaited(openUrl(Uri.parse(link.url)));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<TextbookCatalogBundle> catalog = ref.watch(
      textbookCatalogProvider,
    );
    final String? band = ref.watch(textbookBandFilterProvider);
    final int? grade = ref.watch(textbookGradeFilterProvider);
    final String? yuwenVol = ref.watch(textbookYuwenVolumeProvider);

    return PadScaffold(
      currentDestination: AppNavDestination.textbooks,
      showContinueLearning: false,
      backgroundColor: JingwayColors.cream,
      topBar: PadTopBar(
        title: '教材',
        description: '目录按需打开 · 不内置正文',
        leading: PadBackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(child: Text('目录加载失败：$e')),
        data: (TextbookCatalogBundle bundle) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _DisclaimerBanner(
                  text:
                      '版权归原出版社/教育部；仅供个人学习；景行不内置部编教材正文。来源：ChinaTextbook / yuwen / dianzi-keben。',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FilterRow(
                  band: band,
                  grade: grade,
                  onBand: (String? v) {
                    ref.read(textbookBandFilterProvider.notifier).setBand(v);
                    if (v == null) {
                      ref
                          .read(textbookGradeFilterProvider.notifier)
                          .setGrade(null);
                    }
                  },
                  onGrade: (int? v) {
                    ref.read(textbookGradeFilterProvider.notifier).setGrade(v);
                  },
                ),
              ),
              const SizedBox(height: 4),
              TabBar(
                controller: _tabs,
                labelColor: JingwayColors.accentStrong,
                unselectedLabelColor: JingwayColors.hint,
                indicatorColor: JingwayColors.accent,
                tabs: const <Widget>[
                  Tab(text: '电子课本'),
                  Tab(text: '课文文本'),
                  Tab(text: '智慧教育'),
                ],
              ),
              if (_busyId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: <Widget>[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _busyLabel,
                        style: const TextStyle(color: JingwayColors.hint),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: <Widget>[
                    _ChinaPdfList(
                      items: filterTextbookItems(
                        bundle.chinaItems,
                        band: band,
                        grade: grade,
                      ),
                      busyId: _busyId,
                      onOpen: (TextbookItem i) =>
                          unawaited(_openPdf(i, download: false)),
                      onDownload: (TextbookItem i) =>
                          unawaited(_openPdf(i, download: true)),
                    ),
                    _YuwenList(
                      volumes: bundle.yuwenVolumes
                          .where(
                            (YuwenVolume v) =>
                                band == null ||
                                band.isEmpty ||
                                v.band == band,
                          )
                          .where(
                            (YuwenVolume v) =>
                                grade == null ||
                                v.grade == null ||
                                v.grade == grade ||
                                (grade >= 10 && (v.grade ?? 0) >= 10),
                          )
                          .toList(growable: false),
                      lessons: filterTextbookItems(
                        bundle.yuwenItems,
                        band: band,
                        grade: grade,
                      ),
                      selectedVolume: yuwenVol,
                      onSelectVolume: (String? code) {
                        ref
                            .read(textbookYuwenVolumeProvider.notifier)
                            .setVolume(code);
                      },
                      onOpenLesson: (TextbookItem i) =>
                          unawaited(_openMarkdown(i)),
                    ),
                    _DianziList(
                      items: filterTextbookItems(
                        bundle.dianziItems,
                        band: band,
                      ),
                      onOpen: (TextbookItem i) => unawaited(_openDianzi(i)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JingwayColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JingwayColors.chipBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: JingwayColors.hint,
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.band,
    required this.grade,
    required this.onBand,
    required this.onGrade,
  });

  final String? band;
  final int? grade;
  final ValueChanged<String?> onBand;
  final ValueChanged<int?> onGrade;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _Chip(
              label: '全部学段',
              selected: band == null,
              onTap: () => onBand(null),
            ),
            for (final String b in const <String>['小学', '初中', '高中'])
              _Chip(
                label: b,
                selected: band == b,
                onTap: () => onBand(b),
              ),
          ],
        ),
        if (band != null) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Chip(
                label: '全部年级',
                selected: grade == null,
                onTap: () => onGrade(null),
              ),
              ..._gradesForBand(band!).map(
                (int g) => _Chip(
                  label: '$g年级',
                  selected: grade == g,
                  onTap: () => onGrade(g),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  static List<int> _gradesForBand(String band) {
    return switch (band) {
      '小学' => <int>[1, 2, 3, 4, 5, 6],
      '初中' => <int>[7, 8, 9],
      '高中' => <int>[10, 11, 12],
      _ => const <int>[],
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? JingwayColors.chipSelectedFill
          : JingwayColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? JingwayColors.chipSelectedBorder
                  : JingwayColors.chipBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : JingwayColors.section,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChinaPdfList extends StatelessWidget {
  const _ChinaPdfList({
    required this.items,
    required this.busyId,
    required this.onOpen,
    required this.onDownload,
  });

  final List<TextbookItem> items;
  final String? busyId;
  final ValueChanged<TextbookItem> onOpen;
  final ValueChanged<TextbookItem> onDownload;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('当前筛选下暂无语文 PDF 目录'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int i) {
        final TextbookItem item = items[i];
        final bool busy = busyId == item.id;
        return Material(
          color: JingwayColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: JingwayColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.subtitle} · ChinaTextbook',
                  style: const TextStyle(
                    fontSize: 12,
                    color: JingwayColors.hint,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    TextButton(
                      onPressed: busy ? null : () => onOpen(item),
                      child: const Text('在线打开'),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => onDownload(item),
                      child: Text(busy ? '处理中…' : '下载到本机'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _YuwenList extends StatelessWidget {
  const _YuwenList({
    required this.volumes,
    required this.lessons,
    required this.selectedVolume,
    required this.onSelectVolume,
    required this.onOpenLesson,
  });

  final List<YuwenVolume> volumes;
  final List<TextbookItem> lessons;
  final String? selectedVolume;
  final ValueChanged<String?> onSelectVolume;
  final ValueChanged<TextbookItem> onOpenLesson;

  @override
  Widget build(BuildContext context) {
    if (selectedVolume == null) {
      if (volumes.isEmpty) {
        return const Center(child: Text('当前筛选下暂无课文册次'));
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: volumes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int i) {
          final YuwenVolume v = volumes[i];
          final int count = lessons
              .where((TextbookItem l) => l.volumeCode == v.code)
              .length;
          return ListTile(
            tileColor: JingwayColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              v.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${v.band} · $count 篇课文（按需拉取）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelectVolume(v.code),
          );
        },
      );
    }

    final List<TextbookItem> unitLessons = lessons
        .where((TextbookItem l) => l.volumeCode == selectedVolume)
        .toList(growable: false);
    return Column(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: const Text('返回册次'),
          onTap: () => onSelectVolume(null),
        ),
        Expanded(
          child: unitLessons.isEmpty
              ? const Center(child: Text('该册暂无课文条目'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: unitLessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (BuildContext context, int i) {
                    final TextbookItem item = unitLessons[i];
                    return ListTile(
                      tileColor: JingwayColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        item.unit.isEmpty ? 'yuwen OCR' : item.unit,
                      ),
                      trailing: const Icon(Icons.menu_book_outlined),
                      onTap: () => onOpenLesson(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DianziList extends StatelessWidget {
  const _DianziList({required this.items, required this.onOpen});

  final List<TextbookItem> items;
  final ValueChanged<TextbookItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无智慧教育索引'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) {
          return ListTile(
            tileColor: JingwayColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: const Icon(Icons.public),
            title: const Text('打开智慧教育平台'),
            subtitle: const Text('basic.smartedu.cn'),
            onTap: () =>
                unawaited(openUrl(Uri.parse('https://basic.smartedu.cn/'))),
          );
        }
        final TextbookItem item = items[i - 1];
        return ListTile(
          tileColor: JingwayColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            item.password == null
                ? '${item.band} · 外链索引'
                : '${item.band} · 含网盘提取码',
          ),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => onOpen(item),
        );
      },
    );
  }
}
