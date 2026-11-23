import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../flavors/app_flavor.dart';

enum AppNavDestination {
  home(
    route: '/home',
    label: '备考',
    title: '备考主页',
    subtitle: '按年级匹配字词、古诗文与练习，错题回流复习。',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  library(
    route: '/library',
    label: '视频',
    title: '视频学习',
    subtitle: '导入本地或 B 站视频，用已有字幕精听精看。',
    icon: LucideIcons.clapperboard,
    activeIcon: LucideIcons.clapperboard,
    showInBottomNav: false,
  ),
  /// 古诗文默写（底栏「诗文」）。阅读书架见 [readingHub]。
  reading(
    route: '/poetry',
    label: '诗文',
    title: '古诗文默写',
    subtitle: '年级必背：遮挡背诵、上下句、逐字默写。',
    icon: Icons.chrome_reader_mode_outlined,
    activeIcon: Icons.chrome_reader_mode_rounded,
  ),
  readingHub(
    route: '/reading',
    label: '阅读',
    title: '阅读',
    subtitle: '导入读物与书架，按篇精读。',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    showInBottomNav: false,
  ),
  oralCoach(
    route: '/digital-human',
    label: 'AI老师',
    title: 'AI老师',
    subtitle: '和数字人开口练习，也可以拍照识词。',
    icon: Icons.record_voice_over_outlined,
    activeIcon: Icons.record_voice_over_rounded,
    showInBottomNav: false,
    availableInJingway: false,
  ),
  growth(
    route: '/growth',
    label: '成长',
    title: '成长之旅',
    subtitle: '记录每一次进步，查看学习轨迹与掌握度。',
    icon: LucideIcons.sprout,
    activeIcon: LucideIcons.trophy,
    showInBottomNav: false,
    availableInJingway: false,
  ),
  discover(
    route: '/discover',
    label: '社区真题',
    title: '社区真题',
    subtitle: '真题资料共享、素材协作与同桌互评。',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups_rounded,
    showInBottomNav: false,
    availableInJingway: false,
  ),
  review(
    route: '/review',
    label: '复习',
    title: '复习',
    subtitle: 'FSRS 错字、默写与成语到期卡（按当前年级）。',
    icon: Icons.style_outlined,
    activeIcon: Icons.style_rounded,
  ),
  exam(
    route: '/exam',
    label: '专项',
    title: '考试专项',
    subtitle: '语文专项题包筹备中。',
    icon: Icons.school_outlined,
    activeIcon: Icons.school_rounded,
  ),
  phrases(
    route: '/phrases',
    label: '短语',
    title: '短语库',
    subtitle: '回顾收藏过的句子和表达，集中复习高价值内容。',
    icon: Icons.auto_stories_outlined,
    activeIcon: Icons.auto_stories_rounded,
    showInNav: false,
    showInBottomNav: false,
    availableInJingway: false,
  ),
  words(
    route: '/words',
    label: '单词本',
    title: '单词本',
    subtitle: '查看在视频字幕中见过并收藏的单词。',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    showInNav: false,
    showInBottomNav: false,
    availableInJingway: false,
  ),
  guide(
    route: '/guide',
    label: '怎么学',
    title: '怎么学',
    subtitle: '跟着视频，用轻松的三遍法练听力。',
    icon: Icons.tips_and_updates_outlined,
    activeIcon: Icons.tips_and_updates_rounded,
    showInBottomNav: false,
    availableInJingway: false,
  ),
  settings(
    route: '/settings',
    label: '设置',
    title: '我的',
    subtitle: '年级、账号与本地学习体验。',
    icon: Icons.tune_outlined,
    activeIcon: Icons.tune_rounded,
  ),
  importCourse(
    route: '/importCourse',
    label: '视频导入',
    title: '视频导入',
    subtitle: '选择本地视频和字幕文件，预览匹配结果后再导入。',
    icon: Icons.file_upload_outlined,
    activeIcon: Icons.file_upload_rounded,
    showInBottomNav: false,
  );

  const AppNavDestination({
    required this.route,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
    this.showInNav = true,
    this.showInBottomNav = true,
    this.availableInJingway = true,
  });

  final String route;
  final String label;
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;
  final bool showInNav;
  final bool showInBottomNav;

  /// AcquireEnglish-only destinations stay in the enum for other flavors,
  /// but Jingway product builds hide them from nav / More / sidebar.
  final bool availableInJingway;

  bool get isVisibleForCurrentProduct {
    if (!showInNav) {
      return false;
    }
    if (FlavorConfig.isJingwayProduct && !availableInJingway) {
      return false;
    }
    return true;
  }
}
