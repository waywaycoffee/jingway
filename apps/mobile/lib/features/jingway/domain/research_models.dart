/// Research-only item models (NCR / CKnowEdit shaped).
///
/// These types must never be hydrated from `assets/` in prod. Loaders refuse
/// when [ResearchContentGate.isEnabled] is false.

enum ResearchErrorCategory {
  literal,
  inference,
  method;

  static ResearchErrorCategory? tryParse(String? raw) {
    switch (raw) {
      case 'literal':
        return ResearchErrorCategory.literal;
      case 'inference':
        return ResearchErrorCategory.inference;
      case 'method':
        return ResearchErrorCategory.method;
      default:
        return null;
    }
  }

  String get labelZh {
    switch (this) {
      case ResearchErrorCategory.literal:
        return '字面理解';
      case ResearchErrorCategory.inference:
        return '推理判断';
      case ResearchErrorCategory.method:
        return '方法策略';
    }
  }
}

class NcrReadingItem {
  const NcrReadingItem({
    required this.id,
    required this.passage,
    required this.question,
    required this.options,
    required this.answerIndex,
    this.grades = const <int>[],
    this.errorCategory,
    this.methodCard,
  });

  final String id;
  final List<int> grades;
  final String passage;
  final String question;
  final List<String> options;
  final int answerIndex;
  final ResearchErrorCategory? errorCategory;
  final String? methodCard;

  factory NcrReadingItem.fromJson(Map<String, dynamic> json) {
    return NcrReadingItem(
      id: json['id'] as String? ?? '',
      grades: (json['grades'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => (e as num).toInt())
          .toList(growable: false),
      passage: json['passage'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => '$e')
          .toList(growable: false),
      answerIndex: (json['answerIndex'] as num?)?.toInt() ?? 0,
      errorCategory: ResearchErrorCategory.tryParse(
        json['errorCategory'] as String?,
      ),
      methodCard: json['methodCard'] as String?,
    );
  }
}

enum CknowEditGenre {
  poetryCloze,
  literaryKnowledge,
  other;

  static CknowEditGenre parse(String? raw) {
    switch (raw) {
      case 'poetry_cloze':
        return CknowEditGenre.poetryCloze;
      case 'literary_knowledge':
        return CknowEditGenre.literaryKnowledge;
      default:
        return CknowEditGenre.other;
    }
  }
}

class CknowEditClozeItem {
  const CknowEditClozeItem({
    required this.id,
    required this.prompt,
    required this.answer,
    this.grades = const <int>[],
    this.genre = CknowEditGenre.other,
  });

  final String id;
  final List<int> grades;
  final String prompt;
  final String answer;
  final CknowEditGenre genre;

  factory CknowEditClozeItem.fromJson(Map<String, dynamic> json) {
    return CknowEditClozeItem(
      id: json['id'] as String? ?? '',
      grades: (json['grades'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => (e as num).toInt())
          .toList(growable: false),
      prompt: json['prompt'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      genre: CknowEditGenre.parse(json['genre'] as String?),
    );
  }
}
