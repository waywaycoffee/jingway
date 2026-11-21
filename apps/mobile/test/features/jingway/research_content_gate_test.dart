import 'package:common_learn_english/features/jingway/domain/research_content_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('research gate stays off by default', () {
    expect(kResearchContentGate.isEnabled, isFalse);
    expect(
      const ResearchContentGate(debugOverride: true).isEnabled,
      isTrue,
    );
    expect(
      const ResearchContentGate(remoteEnabled: true, debugOverride: false)
          .isEnabled,
      isFalse,
    );
  });

  test('research paths are not under assets/', () {
    expect(ResearchContentPaths.root.startsWith('assets/'), isFalse);
    expect(ResearchContentPaths.ncr.contains('research'), isTrue);
  });
}
