import 'dart:ui' show Locale, PlatformDispatcher;

enum AppFlavor { dev, staging, prod }

class FlavorConfig {
  static AppFlavor _flavor = AppFlavor.prod;

  static void setFlavor(AppFlavor flavor) {
    _flavor = flavor;
  }

  static AppFlavor get flavor => _flavor;

  static String get flavorName => _flavor.name;

  static bool get isDev => _flavor == AppFlavor.dev;
  static bool get isStaging => _flavor == AppFlavor.staging;
  static bool get isProd => _flavor == AppFlavor.prod;

  /// Jingway Chinese product line (this repo). Flip false only for a future
  /// AcquireEnglish flavor so English nav/settings/code can stay in-tree.
  static bool get isJingwayProduct => true;

  /// Machine translation (EN↔ZH) UI and pipelines. Off for Jingway.
  static bool get enableMachineTranslation => !isJingwayProduct;

  /// Auto ASR /「生成字幕」/ subtitle-completion queue. Off for Jingway;
  /// existing imported videos still play with whatever captions they already have.
  static bool get enableAutoSubtitleGeneration => !isJingwayProduct;

  static bool get isChineseLocale {
    final Locale locale = PlatformDispatcher.instance.locale;
    return locale.languageCode.toLowerCase() == 'zh';
  }

  /// Launcher / UI display name.
  static String get appName {
    switch (_flavor) {
      case AppFlavor.dev:
        return '景行语文 Dev';
      case AppFlavor.staging:
        return '景行语文 Staging';
      case AppFlavor.prod:
        return '景行语文';
    }
  }

  static String get bundleId {
    switch (_flavor) {
      case AppFlavor.dev:
        return 'com.jingway.chinese.dev';
      case AppFlavor.staging:
        return 'com.jingway.chinese.staging';
      case AppFlavor.prod:
        return 'com.jingway.chinese';
    }
  }
}
