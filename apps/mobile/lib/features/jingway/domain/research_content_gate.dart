import 'package:flutter/foundation.dart';

/// Gate for research-only corpora (NCR / CKnowEdit / etc.).
///
/// Prod assets must never ship these packs. Content may live under
/// `data/research/` (gitignored) and only load when explicitly enabled.
class ResearchContentGate {
  const ResearchContentGate({
    this.remoteEnabled = false,
    this.debugOverride,
  });

  /// Remote / feature-flag stub (wire to Config later).
  final bool remoteEnabled;

  /// Optional explicit override for tests.
  final bool? debugOverride;

  bool get isEnabled {
    if (debugOverride != null) return debugOverride!;
    // Never enable in release/profile builds via local debug alone.
    if (kReleaseMode) return false;
    return remoteEnabled || kDebugMode && _localDebugAllow;
  }

  /// Flip only in debug/devtools; keep false so research trees stay opt-in.
  static const bool _localDebugAllow = false;
}

const ResearchContentGate kResearchContentGate = ResearchContentGate();

/// Asset / path conventions — do not register these under `pubspec.yaml` assets.
abstract final class ResearchContentPaths {
  static const String root = 'data/research';
  static const String ncr = 'data/research/ncr';
  static const String cknowEdit = 'data/research/cknow_edit';
}
