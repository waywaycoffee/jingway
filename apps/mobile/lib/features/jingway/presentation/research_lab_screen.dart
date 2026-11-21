import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/domain/cn_dictation_diff.dart';
import '../data/research_content_repository.dart';
import '../domain/research_content_gate.dart';
import '../domain/research_models.dart';
import 'jingway_profile_provider.dart';

/// Debug/internal lab for research-shaped prototypes.
///
/// Hidden unless [ResearchContentGate.isEnabled]. Uses synthetic samples only;
/// real NCR/CKnowEdit files stay under gitignored `data/research/`.
class ResearchLabScreen extends ConsumerStatefulWidget {
  ResearchLabScreen({
    super.key,
    ResearchContentGate? gate,
  }) : gate = gate ??
            (kDebugMode
                ? const ResearchContentGate(debugOverride: true)
                : kResearchContentGate);

  final ResearchContentGate gate;

  @override
  ConsumerState<ResearchLabScreen> createState() => _ResearchLabScreenState();
}

class _ResearchLabScreenState extends ConsumerState<ResearchLabScreen> {
  late final ResearchContentRepository _repo;
  List<NcrReadingItem> _ncr = const <NcrReadingItem>[];
  List<CknowEditClozeItem> _cloze = const <CknowEditClozeItem>[];
  String? _error;
  int? _pickedOption;
  bool? _ncrCorrect;
  final TextEditingController _clozeInput = TextEditingController();
  CnDictationDiffResult? _clozeDiff;

  @override
  void initState() {
    super.initState();
    _repo = ResearchContentRepository(gate: widget.gate);
    _load();
  }

  @override
  void dispose() {
    _clozeInput.dispose();
    super.dispose();
  }

  void _load() {
    try {
      final int? grade = ref.read(jingwayProfileProvider).grade;
      final List<NcrReadingItem> ncr =
          _repo.parseNcrBundle(ResearchContentRepository.syntheticNcrJson);
      final List<CknowEditClozeItem> cloze = _repo
          .parseCknowEditBundle(ResearchContentRepository.syntheticCknowJson);
      setState(() {
        _ncr = grade == null
            ? ncr
            : ncr
                .where((NcrReadingItem e) => e.grades.contains(grade))
                .toList(growable: false);
        _cloze = grade == null
            ? cloze
            : cloze
                .where((CknowEditClozeItem e) => e.grades.contains(grade))
                .toList(growable: false);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.gate.isEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('研究内容')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '研究内容门禁已关闭。正式包不得加载 NCR / CKnowEdit。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final NcrReadingItem? ncr = _ncr.isEmpty ? null : _ncr.first;
    final CknowEditClozeItem? cloze = _cloze.isEmpty ? null : _cloze.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: const Text('研究内容（内测）'),
        backgroundColor: const Color(0xFFF7F4EF),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: <Widget>[
                const Text(
                  '合成夹具 · 非 NCR/CKnowEdit 原文',
                  style: TextStyle(color: Color(0xFF78716C)),
                ),
                const SizedBox(height: 16),
                if (ncr != null) ...<Widget>[
                  Text('阅读选择题', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(ncr.passage),
                        const SizedBox(height: 12),
                        Text(
                          ncr.question,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...List<Widget>.generate(ncr.options.length, (int i) {
                          final bool selected = _pickedOption == i;
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: const Color(0xFF9A3412),
                            ),
                            title: Text(ncr.options[i]),
                            onTap: () {
                              setState(() {
                                _pickedOption = i;
                                _ncrCorrect = i == ncr.answerIndex;
                              });
                            },
                          );
                        }),
                        if (_ncrCorrect != null) ...<Widget>[
                          Text(
                            _ncrCorrect! ? '回答正确' : '回答有误',
                            style: TextStyle(
                              color: _ncrCorrect!
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF9A3412),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!_ncrCorrect! && ncr.errorCategory != null)
                            Text('错因：${ncr.errorCategory!.labelZh}'),
                          if (ncr.methodCard != null && ncr.methodCard!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('方法卡：${ncr.methodCard}'),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (cloze != null) ...<Widget>[
                  Text('填空默写原型', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(cloze.prompt),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _clozeInput,
                          decoration: const InputDecoration(
                            hintText: '填写空缺',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF9A3412),
                          ),
                          onPressed: () {
                            setState(() {
                              _clozeDiff = diffCnDictation(
                                expected: cloze.answer,
                                actual: _clozeInput.text,
                              );
                            });
                          },
                          child: const Text('核对'),
                        ),
                        if (_clozeDiff != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            _clozeDiff!.exact ? '默写正确' : '需订正',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _clozeDiff!.exact
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF9A3412),
                            ),
                          ),
                          if (!_clozeDiff!.exact)
                            Text('参考：${cloze.answer}'),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
