/// Thin catalog models for K12 语文 textbooks (metadata only — no bundled body).

enum TextbookSourceKind { chinaPdf, yuwenMarkdown, dianziIndex }

class TextbookLink {
  const TextbookLink({
    required this.label,
    required this.url,
    this.kind = 'external',
  });

  final String label;
  final String url;
  final String kind;

  factory TextbookLink.fromJson(Map<String, dynamic> json) {
    return TextbookLink(
      label: '${json['label'] ?? ''}',
      url: '${json['url'] ?? ''}',
      kind: '${json['kind'] ?? 'external'}',
    );
  }
}

class TextbookItem {
  const TextbookItem({
    required this.id,
    required this.title,
    required this.source,
    required this.band,
    this.subject = '语文',
    this.grade,
    this.gradeLabel = '',
    this.volume = '',
    this.unit = '',
    this.volumeCode = '',
    this.path = '',
    this.remoteUrl = '',
    this.githubUrl = '',
    this.mirrors = const <String>[],
    this.links = const <TextbookLink>[],
    this.password,
    this.note = '',
    this.action = 'external',
    this.sizeBytes = 0,
  });

  final String id;
  final String title;
  final TextbookSourceKind source;
  final String band;
  final String subject;
  final int? grade;
  final String gradeLabel;
  final String volume;
  final String unit;
  final String volumeCode;
  final String path;
  final String remoteUrl;
  final String githubUrl;
  final List<String> mirrors;
  final List<TextbookLink> links;
  final String? password;
  final String note;
  final String action;
  final int sizeBytes;

  String get subtitle {
    final List<String> parts = <String>[
      if (gradeLabel.isNotEmpty) gradeLabel,
      if (volume.isNotEmpty) volume,
      if (unit.isNotEmpty) unit,
    ];
    return parts.join(' · ');
  }

  List<String> get downloadCandidates {
    final List<String> urls = <String>[
      if (remoteUrl.isNotEmpty) remoteUrl,
      ...mirrors.where((String u) => u.isNotEmpty),
    ];
    // Deduplicate while preserving order.
    final Set<String> seen = <String>{};
    return urls.where((String u) => seen.add(u)).toList(growable: false);
  }
}

class YuwenVolume {
  const YuwenVolume({
    required this.id,
    required this.code,
    required this.title,
    required this.band,
    this.grade,
    this.gradeLabel = '',
    this.volume = '',
  });

  final String id;
  final String code;
  final String title;
  final String band;
  final int? grade;
  final String gradeLabel;
  final String volume;

  factory YuwenVolume.fromJson(Map<String, dynamic> json) {
    return YuwenVolume(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      title: '${json['title'] ?? ''}',
      band: '${json['band'] ?? ''}',
      grade: (json['grade'] as num?)?.toInt(),
      gradeLabel: '${json['gradeLabel'] ?? ''}',
      volume: '${json['volume'] ?? ''}',
    );
  }
}

class TextbookCatalogBundle {
  const TextbookCatalogBundle({
    required this.chinaItems,
    required this.yuwenItems,
    required this.yuwenVolumes,
    required this.dianziItems,
    this.chinaLicense = '',
    this.yuwenLicense = '',
    this.dianziLicense = '',
    this.yuwenRawBase = 'https://raw.githubusercontent.com/hantang/yuwen/docs/',
    this.yuwenMirrorPrefixes = const <String>[
      'https://ghfast.top/',
      'https://mirror.ghproxy.com/',
    ],
  });

  final List<TextbookItem> chinaItems;
  final List<TextbookItem> yuwenItems;
  final List<YuwenVolume> yuwenVolumes;
  final List<TextbookItem> dianziItems;
  final String chinaLicense;
  final String yuwenLicense;
  final String dianziLicense;
  final String yuwenRawBase;
  final List<String> yuwenMirrorPrefixes;

  static const TextbookCatalogBundle empty = TextbookCatalogBundle(
    chinaItems: <TextbookItem>[],
    yuwenItems: <TextbookItem>[],
    yuwenVolumes: <YuwenVolume>[],
    dianziItems: <TextbookItem>[],
  );
}
