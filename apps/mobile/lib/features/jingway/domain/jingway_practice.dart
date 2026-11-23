class JingwayPracticeQuestion {
  const JingwayPracticeQuestion({
    required this.prompt,
    required this.answers,
    required this.explanation,
    this.options = const [],
  });

  final String prompt;
  final List<String> options;
  final List<String> answers;
  final String explanation;

  bool accepts(String answer) => answers.contains(answer.trim());
}

class JingwayPracticePack {
  const JingwayPracticePack({
    required this.id,
    required this.title,
    required this.questions,
    this.material,
    this.grade = 7,
  });

  // Change the ID suffix when questions or grading rules change.
  final String id;
  final String title;
  final int grade;
  final String? material;
  final List<JingwayPracticeQuestion> questions;
}

// Original samples for the seventh-grade pilot.
const jingwayPracticePacks = [
  JingwayPracticePack(
    id: 'g7-words-v1',
    title: '字词基础',
    questions: [
      JingwayPracticeQuestion(
        prompt: '哪一项适合填入「雨后，空气格外___」？',
        options: ['清新', '清晰', '清脆'],
        answers: ['清新'],
        explanation: '「清新」形容空气清爽新鲜。「清晰」指清楚，「清脆」常形容声音。',
      ),
      JingwayPracticeQuestion(
        prompt: '补全成语「循序渐___」。只填一个字。',
        answers: ['进'],
        explanation: '「循序渐进」指按一定的步骤逐渐推进。',
      ),
    ],
  ),
  JingwayPracticePack(
    id: 'g7-reading-v1',
    title: '现代文阅读',
    material:
        '① 放学时下起了雨。校门口，一位同学站在屋檐下，不时望着路口。\n\n'
        '② 小宁走过去，把伞举到两人中间。走到路口时，她自己的半边袖子已经湿了。'
        '她却把伞又往同学那边挪了挪。',
    questions: [
      JingwayPracticeQuestion(
        prompt: '哪一处细节最能表现小宁在照顾同学？',
        options: ['放学时下起了雨', '同学不时望着路口', '袖子湿了还把伞往同学那边挪'],
        answers: ['袖子湿了还把伞往同学那边挪'],
        explanation: '第②段写小宁的袖子已经湿了，她仍把伞往同学那边挪，表现了她对同学的照顾。',
      ),
      JingwayPracticeQuestion(
        prompt: '第①段在文中有什么作用？',
        options: ['交代下雨和同学等候的情形', '总结两人之间的友谊', '说明小宁如何买伞'],
        answers: ['交代下雨和同学等候的情形'],
        explanation: '第①段交代雨天和同学等候的情形，为第②段小宁过去撑伞作铺垫。',
      ),
    ],
  ),
];
