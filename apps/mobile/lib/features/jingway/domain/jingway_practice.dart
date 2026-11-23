const String jingwayReadingSampleId = 'jingway-g7-rain-v1';
const String jingwayReadingPracticeId = 'g7-reading-v2';
const String jingwayG3StoryDocId = 'jingway-g3-ant-v1';
const String jingwayG3StoryPracticeId = 'g3-story-v1';

/// 景行原创读物 → 篇后题包；非原创返回 null。
String? jingwayPracticePackForDoc(String docId) {
  if (docId == jingwayReadingSampleId) return jingwayReadingPracticeId;
  if (docId == jingwayG3StoryDocId) return jingwayG3StoryPracticeId;
  return null;
}

bool isJingwayOriginalDoc(String docId) =>
    jingwayPracticePackForDoc(docId) != null;

class JingwayPracticeQuestion {
  const JingwayPracticeQuestion({
    required this.prompt,
    required this.answers,
    required this.explanation,
    this.options = const [],
    this.skill,
  });

  final String prompt;
  final List<String> options;
  final List<String> answers;
  final String explanation;
  final String? skill;

  bool accepts(String answer) => answers.contains(answer.trim());
}

class JingwayPracticePack {
  const JingwayPracticePack({
    required this.id,
    required this.title,
    required this.questions,
    this.material,
    this.method,
    this.grade = 7,
  });

  // Change the ID suffix when questions or grading rules change.
  final String id;
  final String title;
  final int grade;
  final String? material;
  final String? method;
  final List<JingwayPracticeQuestion> questions;
}

// Original samples for the seventh-grade pilot.
const jingwayPracticePacks = [
  JingwayPracticePack(
    id: 'g7-words-v1',
    title: '字词基础',
    method: '把备选词放回原句，结合词义和搭配判断。',
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
    id: jingwayReadingPracticeId,
    title: '现代文阅读',
    method: '先圈出题干里的关键词，再回原文找能直接支持答案的句子。'
        ' （能力层对齐 CMRC/叫叫过程技能：信息提取→直接推论→理解整合）',
    material:
        '① 放学时下起了雨。校门口，一位同学站在屋檐下，不时望着路口。\n\n'
        '② 小宁走过去，把伞举到两人中间。走到路口时，她自己的半边袖子已经湿了。'
        '她却把伞又往同学那边挪了挪。',
    questions: [
      JingwayPracticeQuestion(
        skill: '信息提取',
        prompt: '第①段里，同学当时在做什么？',
        options: ['在屋檐下望着路口', '正在买伞', '已经走到校外'],
        answers: ['在屋檐下望着路口'],
        explanation: '第①段写同学站在屋檐下，不时望着路口。',
      ),
      JingwayPracticeQuestion(
        skill: '直接推论',
        prompt: '哪一处细节最能表现小宁在照顾同学？',
        options: ['放学时下起了雨', '同学不时望着路口', '袖子湿了还把伞往同学那边挪'],
        answers: ['袖子湿了还把伞往同学那边挪'],
        explanation: '第②段写小宁的袖子已经湿了，她仍把伞往同学那边挪，表现了她对同学的照顾。',
      ),
      JingwayPracticeQuestion(
        skill: '理解整合',
        prompt: '用一句话概括两段内容，最贴切的是？',
        options: ['雨天里，小宁把伞让给同学多遮一些', '小宁忘记带伞只好跑回家', '同学在路上捡到一把伞'],
        answers: ['雨天里，小宁把伞让给同学多遮一些'],
        explanation: '两段合写雨天等候与小宁主动让伞的照顾行为。',
      ),
    ],
  ),
  // congcong-school 式分级短篇：低年级听读理解闭环（原创正文，非教材）。
  JingwayPracticePack(
    id: 'g3-story-v1',
    grade: 3,
    title: '分级故事 · 小蚂蚁搬家',
    method: '先听读/默读故事，再答题；错题可重做并看解析。',
    material:
        '小蚂蚁发现一颗糖。糖太大，搬不动。'
        '它叫来伙伴，大家一起推。糖终于滚进洞里。'
        '大家笑了：齐心合力，再大的糖也能搬回家。',
    questions: [
      JingwayPracticeQuestion(
        skill: '信息提取',
        prompt: '小蚂蚁一开始发现了什么？',
        options: ['一颗糖', '一滴水', '一片叶子'],
        answers: ['一颗糖'],
        explanation: '第一句写明发现一颗糖。',
      ),
      JingwayPracticeQuestion(
        skill: '直接推论',
        prompt: '糖为什么后来能进洞？',
        options: ['大家一起推', '风把它吹进去', '糖自己变小了'],
        answers: ['大家一起推'],
        explanation: '文中写它叫来伙伴一起推，糖才滚进洞。',
      ),
    ],
  ),
  JingwayPracticePack(
    id: 'g8-words-v1',
    grade: 8,
    title: '词语与成语运用',
    questions: [
      JingwayPracticeQuestion(
        prompt: '「他从调查中找到证据，这个猜测终于___。」哪一项最贴切？',
        options: ['得到证实', '不言而喻', '不胫而走'],
        answers: ['得到证实'],
        explanation: '已有证据说明猜测成立，应使用「得到证实」。',
      ),
      JingwayPracticeQuestion(
        prompt: '补全成语「因地制___」。只填一个字。',
        answers: ['宜'],
        explanation: '「因地制宜」指根据当地情况采取适合的措施。',
      ),
    ],
  ),
  JingwayPracticePack(
    id: 'g8-logic-v1',
    grade: 8,
    title: '逻辑思辨',
    method: '先划出要证明的观点，再检查理由是否相关、证据是否足够。',
    questions: [
      JingwayPracticeQuestion(
        prompt: '「建议延长阅览室开放时间。调查显示，不少学生在晚自习结束后才有空借书。」哪一句是论点？',
        options: ['建议延长阅览室开放时间', '不少学生晚自习后才有空借书'],
        answers: ['建议延长阅览室开放时间'],
        explanation: '第一句是要证明的主张，调查结果是用来支持它的理由。',
      ),
      JingwayPracticeQuestion(
        prompt: '要支持「课间应多到室外活动」，哪项理由更相关？',
        options: ['户外活动能让学生舒展身体', '操场入口最近换了颜色'],
        answers: ['户外活动能让学生舒展身体'],
        explanation: '前者说明室外活动的具体益处，入口颜色与主张无关。',
      ),
      JingwayPracticeQuestion(
        prompt: '「我遇到两位同学不爱阅读，所以全校同学都不爱阅读。」这段推理的主要问题是什么？',
        options: ['以偏概全', '偷换概念', '人身攻击'],
        answers: ['以偏概全'],
        explanation: '两位同学的情况不足以代表全校。',
      ),
    ],
  ),
];

// Follow-up items assess the same skill using new wording or a new example.
const Map<String, List<JingwayPracticeQuestion>> jingwayVerificationItems = {
  'g7-words-v1': [
    JingwayPracticeQuestion(
      prompt: '哪项适合填入「山谷里传来___的鸟鸣」？',
      options: ['清脆', '清晰', '清新'],
      answers: ['清脆'],
      explanation: '形容鸟鸣声悦耳响亮，可用「清脆」。',
    ),
    JingwayPracticeQuestion(
      prompt: '补全成语「按部就___」。只填一个字。',
      answers: ['班'],
      explanation: '「按部就班」指依照一定的步骤和次序进行。',
    ),
  ],
  jingwayReadingPracticeId: [
    JingwayPracticeQuestion(
      skill: '信息提取',
      prompt: '根据第①段，同学站在哪里？',
      options: ['校门口的屋檐下', '路口', '教室里'],
      answers: ['校门口的屋檐下'],
      explanation: '第①段直接交代同学在校门口的屋檐下等候。',
    ),
    JingwayPracticeQuestion(
      skill: '直接推论',
      prompt: '文中写小宁「半边袖子已经湿了」，最能说明什么？',
      options: ['她把伞更多地让给了同学', '她把伞忘在教室了', '她想在雨里玩'],
      answers: ['她把伞更多地让给了同学'],
      explanation: '结合她继续挪伞的动作，可以推知她把更多伞面让给了同学。',
    ),
    JingwayPracticeQuestion(
      skill: '理解整合',
      prompt: '下面哪个标题同时照应了下雨的背景和两人之间发生的事？',
      options: ['雨天里共撑一把伞', '放学铃响了', '校门口的路'],
      answers: ['雨天里共撑一把伞'],
      explanation: '「雨天」照应第①段背景，「共撑一把伞」概括了第②段主要事件。',
    ),
  ],
  jingwayG3StoryPracticeId: [
    JingwayPracticeQuestion(
      skill: '信息提取',
      prompt: '小蚂蚁叫谁来帮忙？',
      options: ['伙伴', '小鸟', '老师'],
      answers: ['伙伴'],
      explanation: '文中写它叫来伙伴一起推。',
    ),
  ],
};
