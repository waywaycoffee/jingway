import 'package:flutter/material.dart';

/// Warm rice-paper + terracotta palette for Jingway surfaces.
///
/// Do not use [AppDesignTokens] surfaces here — those follow global dark mode
/// and paint navy chips / muddied grays on cream.
abstract final class JingwayColors {
  /// Slightly yellowed 宣纸.
  static const Color cream = Color(0xFFF1E6C8);
  static const Color surface = Color(0xFFF8F0DA);
  static const Color title = Color(0xFF1C1917);
  static const Color body = Color(0xFF292524);
  static const Color section = Color(0xFF44403C);
  static const Color hint = Color(0xFF57534E);
  static const Color muted = Color(0xFF57534E);
  static const Color slogan = Color(0xFF7C2D12);
  static const Color accent = Color(0xFF9A3412);
  static const Color accentStrong = Color(0xFF7C2D12);
  static const Color chipBorder = Color(0xFFD6D3D1);
  static const Color chipSelectedFill = Color(0xFF9A3412);
  static const Color chipSelectedBorder = Color(0xFF7C2D12);
  static const Color ctaDisabledBg = Color(0xFFD6C4B8);
  static const Color ctaDisabledFg = Color(0xFF7C2D12);
}
