import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/textbook_models.dart';

const String kChinaTextbookAsset =
    'assets/jingway/textbooks/china_textbook.json';
const String kYuwenTextbookAsset = 'assets/jingway/textbooks/yuwen.json';
const String kDianziTextbookAsset = 'assets/jingway/textbooks/dianzi_keben.json';

/// Loads thin textbook manifests shipped in the APK (metadata only).
class TextbookCatalogRepository {
  const TextbookCatalogRepository();

  Future<TextbookCatalogBundle> load() async {
    final List<Object?> results = await Future.wait<Object?>(<Future<Object?>>[
      rootBundle.loadString(kChinaTextbookAsset),
      rootBundle.loadString(kYuwenTextbookAsset),
      rootBundle.loadString(kDianziTextbookAsset),
    ]);
    final Map<String, dynamic> china = jsonDecode(results[0]! as String)
        as Map<String, dynamic>;
    final Map<String, dynamic> yuwen = jsonDecode(results[1]! as String)
        as Map<String, dynamic>;
    final Map<String, dynamic> dianzi = jsonDecode(results[2]! as String)
        as Map<String, dynamic>;

    final String yuwenRawBase =
        '${yuwen['rawBase'] ?? 'https://raw.githubusercontent.com/hantang/yuwen/docs/'}';
    final List<String> mirrorPrefixes = ((yuwen['mirrorPrefixes'] as List?) ??
            const <String>[
              'https://ghfast.top/',
              'https://mirror.ghproxy.com/',
            ])
        .map((Object? e) => '$e')
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);

    final List<TextbookItem> chinaItems = _parseChina(china);
    final List<YuwenVolume> volumes = ((yuwen['volumes'] as List?) ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> e) =>
              YuwenVolume.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList(growable: false);
    final List<TextbookItem> yuwenItems = _parseYuwen(
      yuwen,
      rawBase: yuwenRawBase,
      mirrorPrefixes: mirrorPrefixes,
    );
    final List<TextbookItem> dianziItems = _parseDianzi(dianzi);

    return TextbookCatalogBundle(
      chinaItems: chinaItems,
      yuwenItems: yuwenItems,
      yuwenVolumes: volumes,
      dianziItems: dianziItems,
      chinaLicense: '${china['licenseNote'] ?? ''}',
      yuwenLicense: '${yuwen['licenseNote'] ?? ''}',
      dianziLicense: '${dianzi['licenseNote'] ?? ''}',
      yuwenRawBase: yuwenRawBase,
      yuwenMirrorPrefixes: mirrorPrefixes,
    );
  }

  List<TextbookItem> _parseChina(Map<String, dynamic> root) {
    final List items = (root['items'] as List?) ?? const [];
    return items
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) {
          final Map<String, dynamic> json = Map<String, dynamic>.from(e);
          return TextbookItem(
            id: '${json['id'] ?? ''}',
            title: '${json['title'] ?? ''}',
            source: TextbookSourceKind.chinaPdf,
            band: '${json['band'] ?? ''}',
            subject: '${json['subject'] ?? '语文'}',
            grade: (json['grade'] as num?)?.toInt(),
            gradeLabel: '${json['gradeLabel'] ?? ''}',
            volume: '${json['volume'] ?? ''}',
            path: '${json['path'] ?? ''}',
            remoteUrl: '${json['remoteUrl'] ?? ''}',
            githubUrl: '${json['githubUrl'] ?? ''}',
            mirrors: ((json['mirrors'] as List?) ?? const [])
                .map((Object? u) => '$u')
                .where((String s) => s.isNotEmpty)
                .toList(growable: false),
            action: '${json['action'] ?? 'pdf'}',
            sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
            note: '${root['licenseNote'] ?? ''}',
          );
        })
        .where((TextbookItem i) => i.id.isNotEmpty && i.title.isNotEmpty)
        .toList(growable: false);
  }

  List<TextbookItem> _parseYuwen(
    Map<String, dynamic> root, {
    required String rawBase,
    required List<String> mirrorPrefixes,
  }) {
    final List items = (root['items'] as List?) ?? const [];
    return items
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) {
          final Map<String, dynamic> json = Map<String, dynamic>.from(e);
          final String path = '${json['path'] ?? ''}';
          final String encoded = path
              .split('/')
              .map(Uri.encodeComponent)
              .join('/');
          final String remote = path.isEmpty ? '' : '$rawBase$encoded';
          final List<String> mirrors = remote.isEmpty
              ? const <String>[]
              : mirrorPrefixes
                    .map((String p) => '$p$remote')
                    .toList(growable: false);
          return TextbookItem(
            id: '${json['id'] ?? ''}',
            title: '${json['title'] ?? ''}',
            source: TextbookSourceKind.yuwenMarkdown,
            band: '${json['band'] ?? ''}',
            grade: (json['grade'] as num?)?.toInt(),
            gradeLabel: '${json['gradeLabel'] ?? ''}',
            volume: '${json['volume'] ?? ''}',
            unit: '${json['unit'] ?? ''}',
            volumeCode: '${json['volumeCode'] ?? ''}',
            path: path,
            remoteUrl: remote,
            mirrors: mirrors,
            action: '${json['action'] ?? 'markdown'}',
            note: '${root['licenseNote'] ?? ''}',
          );
        })
        .where((TextbookItem i) => i.id.isNotEmpty && i.title.isNotEmpty)
        .toList(growable: false);
  }

  List<TextbookItem> _parseDianzi(Map<String, dynamic> root) {
    final List items = (root['items'] as List?) ?? const [];
    return items
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) {
          final Map<String, dynamic> json = Map<String, dynamic>.from(e);
          final List<TextbookLink> links = ((json['links'] as List?) ?? const [])
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (Map<dynamic, dynamic> m) =>
                    TextbookLink.fromJson(Map<String, dynamic>.from(m)),
              )
              .where((TextbookLink l) => l.url.isNotEmpty)
              .toList(growable: false);
          return TextbookItem(
            id: '${json['id'] ?? ''}',
            title: '${json['title'] ?? ''}',
            source: TextbookSourceKind.dianziIndex,
            band: '${json['band'] ?? ''}',
            subject: '${json['subject'] ?? '语文'}',
            grade: (json['grade'] as num?)?.toInt(),
            gradeLabel: '${json['gradeLabel'] ?? ''}',
            path: '${json['path'] ?? ''}',
            links: links,
            password: json['password'] == null ? null : '${json['password']}',
            note: '${json['note'] ?? root['licenseNote'] ?? ''}',
            action: '${json['action'] ?? 'external'}',
          );
        })
        .where((TextbookItem i) => i.id.isNotEmpty && i.title.isNotEmpty)
        .toList(growable: false);
  }
}
